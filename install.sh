#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
case ${1:-} in
  '') ;;
  --extras) ;;
  *) echo 'Usage: bash install.sh [--extras]'; exit 1 ;;
esac
(( $# <= 1 )) || { echo 'Usage: bash install.sh [--extras]'; exit 1; }

for script in bash_aliases.sh tmux.sh nvim.sh starship.sh; do
  echo "Running $script..."
  bash "$SCRIPT_DIR/$script"
done
if [[ ${1:-} == --extras ]]; then
  bash "$SCRIPT_DIR/extra.sh"
else
  echo 'Run bash extra.sh to install keychain, uv, Ruff, ty, and Codex.'
fi
echo 'Setup finished. Open a new Bash shell to load the added settings.'
