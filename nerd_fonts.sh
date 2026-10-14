#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

if grep -qi microsoft /proc/sys/kernel/osrelease; then
  echo 'On WSL, install JetBrainsMono Nerd Font in Windows and select it in Windows Terminal.'
  echo 'Download: https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
  exit 0
fi

FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
choose_existing "$FONT_DIR"
if [[ $FILE_CHOICE == skip ]]; then
  echo "Skipped $FONT_DIR"
  exit 0
fi
FONT_CHOICE=$FILE_CHOICE
apt_install curl ca-certificates unzip fontconfig
download https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip "$WORK_DIR/font.zip"
mkdir "$WORK_DIR/font"
unzip -q "$WORK_DIR/font.zip" -d "$WORK_DIR/font"
replace_target "$WORK_DIR/font" "$FONT_DIR" "$FONT_CHOICE"
fc-cache -f "$FONT_DIR"
echo 'Installed JetBrainsMono Nerd Font. Select it in your terminal preferences.'
