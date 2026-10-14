#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

apt_install curl ca-certificates
add_path "$HOME/.local/bin"
if ! command -v starship >/dev/null; then
  mkdir -p "$HOME/.local/bin"
  download https://starship.rs/install.sh "$WORK_DIR/starship-install.sh"
  sh "$WORK_DIR/starship-install.sh" --yes --bin-dir "$HOME/.local/bin"
fi
install_asset "$DEVKIT_DIR/assets/starship.toml" "$CONFIG_DIR/starship.toml"
append_bashrc 'command -v starship >/dev/null && eval "$(starship init bash)"'
echo 'Starship configured. Select a Nerd Font in your terminal and open a new Bash shell.'
