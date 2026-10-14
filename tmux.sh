#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

apt_install tmux git
TMUX_CONF="$HOME/.tmux.conf"
if [[ -e $CONFIG_DIR/tmux/tmux.conf || -L $CONFIG_DIR/tmux/tmux.conf ]]; then
  TMUX_CONF="$CONFIG_DIR/tmux/tmux.conf"
fi
choose_existing "$TMUX_CONF"
if [[ $FILE_CHOICE == skip ]]; then
  echo 'Skipped tmux configuration and plugin setup.'
  exit 0
fi
replace_target "$DEVKIT_DIR/assets/tmux.conf" "$TMUX_CONF" "$FILE_CHOICE"
mkdir -p "$HOME/.tmux/logs" "$HOME/.tmux/plugins"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -e $TPM_DIR && ! -L $TPM_DIR ]]; then
  git clone https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
fi
[[ -x $TPM_DIR/bin/install_plugins ]] || die "$TPM_DIR is not a valid TPM installation."

# Use a separate server so an active user's tmux session is not changed.
# TPM needs a running server with its config loaded to read the plugin list.
TMUX_SOCKET="devkit-$$"
trap 'tmux -L "$TMUX_SOCKET" kill-server >/dev/null 2>&1 || true; rm -rf -- "$WORK_DIR"' EXIT
env -u TMUX tmux -L "$TMUX_SOCKET" -f "$TMUX_CONF" new-session -d -s devkit
tmux -L "$TMUX_SOCKET" set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
TMUX="$(tmux -L "$TMUX_SOCKET" display-message -p '#{socket_path}'),0,0" \
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" "$TPM_DIR/bin/install_plugins"
tmux -L "$TMUX_SOCKET" kill-server

for key in h j k l; do
  append_bashrc "bind -r '\"\\e${key}\"'"
done
echo 'Tmux configured. Open a new Bash shell; new tmux servers will load the config.'
printf 'For an existing tmux server, run: tmux source-file %q\n' "$TMUX_CONF"
