#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

apt_install keychain curl ca-certificates git build-essential
add_path "$HOME/.local/bin"
if ! command -v uv >/dev/null; then
  download https://astral.sh/uv/install.sh "$WORK_DIR/uv-install.sh"
  UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh "$WORK_DIR/uv-install.sh"
fi
uv tool install --upgrade ruff
uv tool install --upgrade ty
add_path "$(uv tool dir --bin)"
append_bashrc 'command -v keychain >/dev/null && eval "$(keychain --quiet --eval --agents ssh)"'

ensure_node
# A user-owned npm prefix avoids sudo and works with system Node or nvm.
npm install --global --prefix "$HOME/.local" @openai/codex@latest
add_path "$HOME/.local/bin"
echo 'Installed keychain, uv, Ruff, ty, and Codex. Open a new Bash shell, then run codex.'
