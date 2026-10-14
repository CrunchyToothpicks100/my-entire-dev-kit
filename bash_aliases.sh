#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

apt_install tree bat git
install_asset "$DEVKIT_DIR/assets/bash_aliases" "$HOME/.bash_aliases"
append_bashrc '[ ! -f "$HOME/.bash_aliases" ] || . "$HOME/.bash_aliases"'
echo 'Bash aliases installed. Open a new Bash shell to load them.'
