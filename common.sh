#!/usr/bin/env bash
# Shared helpers; source this file from the installers.

devkit_init() {
  DEVKIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  SCRIPT_NAME="$(basename -- "$0")"
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
  BASHRC="$HOME/.bashrc"
  BASHRC_CHOICE=''
  [[ $(uname -s) == Linux ]] || die 'These installers support Linux and WSL.'
  command -v apt-get >/dev/null || die 'These installers require Ubuntu/Debian with apt-get.'
  (( EUID != 0 )) || die 'Run as your normal user; the scripts use sudo for apt only.'
  command -v sudo >/dev/null || die 'sudo is required to install system packages.'
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf -- "$WORK_DIR"' EXIT
}

die() { echo "Error: $*" >&2; exit 1; }

apt_install() {
  if [[ ${DEVKIT_APT_UPDATED:-0} != 1 ]]; then
    sudo apt-get update
    export DEVKIT_APT_UPDATED=1
  fi
  sudo apt-get install -y "$@"
}

# Set FILE_CHOICE without modifying anything. EOF is treated as skip.
choose_existing() {
  local target=$1 answer
  FILE_CHOICE=overwrite
  if [[ -e $target || -L $target ]]; then
    while true; do
      read -r -p "$target exists: [b]ackup, [o]verwrite, or [s]kip? [s] " answer || answer=s
      case ${answer,,} in
        b|backup) FILE_CHOICE=backup; break ;;
        o|overwrite) FILE_CHOICE=overwrite; break ;;
        s|skip|'') FILE_CHOICE=skip; break ;;
        *) echo 'Please enter b, o, or s.' ;;
      esac
    done
  fi
}

replace_target() {
  local source=$1 target=$2 choice=$3 mode=${4:-copy} backup
  [[ $choice != skip ]] || { echo "Skipped $target"; return 0; }
  [[ -e $source ]] || die "Missing asset: $source"
  [[ $mode == copy || $mode == move ]] || die "Unknown installation mode: $mode"
  mkdir -p -- "$(dirname -- "$target")"
  if [[ -e $target || -L $target ]]; then
    if [[ $choice == backup ]]; then
      backup="${target}.backup.$(date +%Y%m%d-%H%M%S).$$"
      [[ ! -e $backup && ! -L $backup ]] || die "Backup already exists: $backup"
      mv -- "$target" "$backup"
      echo "Backed up $target to $backup"
    else
      rm -rf -- "$target"
    fi
  fi
  if [[ $mode == move ]]; then
    mv -T -- "$source" "$target"
  else
    cp -R -- "$source" "$target"
  fi
  echo "Installed $target"
}

install_asset() {
  choose_existing "$2"
  replace_target "$1" "$2" "$FILE_CHOICE"
}

# Preserve existing Bash settings. Overwrite means append without a backup.
# A single choice applies to all additions made by this invocation.
append_bashrc() {
  local line=$1 backup staged
  if [[ -f $BASHRC ]] && grep -Fxq -- "$line" "$BASHRC"; then
    return 0
  fi
  if [[ -z $BASHRC_CHOICE ]]; then
    [[ ! -d $BASHRC ]] || die "$BASHRC is a directory."
    echo 'Bash changes append settings and preserve existing content.'
    choose_existing "$BASHRC"
    BASHRC_CHOICE=$FILE_CHOICE
    if [[ $BASHRC_CHOICE == backup && -f $BASHRC ]]; then
      backup="${BASHRC}.backup.$(date +%Y%m%d-%H%M%S).$$"
      [[ ! -e $backup && ! -L $backup ]] || die "Backup already exists: $backup"
      cp -pL -- "$BASHRC" "$backup"
      echo "Backed up $BASHRC to $backup"
    fi
  fi
  if [[ $BASHRC_CHOICE == skip ]]; then
    echo "Skipped Bash setting: $line"
    return 0
  fi
  # Replace symlinks with a regular file, leaving their referents untouched.
  if [[ -L $BASHRC ]]; then
    staged="$(mktemp "$HOME/.bashrc.devkit.XXXXXX")"
    if [[ -f $BASHRC ]]; then
      cat -- "$BASHRC" > "$staged"
      chmod --reference="$BASHRC" "$staged"
    fi
    mv -T -- "$staged" "$BASHRC"
  fi
  echo >> "$BASHRC"
  echo "# my-entire-dev-kit $SCRIPT_NAME" >> "$BASHRC"
  echo "$line" >> "$BASHRC"
}

add_path() {
  local directory=$1 line
  # %q protects spaces and shell metacharacters in the destination path.
  printf -v line 'export PATH=%q:"$PATH"' "$directory"
  append_bashrc "$line"
  export PATH="$directory:$PATH"
}

download() { curl --fail --location --show-error --silent "$1" -o "$2"; }

ensure_node() {
  # Use nvm if present, even when a noninteractive shell did not load it.
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s $NVM_DIR/nvm.sh ]]; then
    # nvm is not compatible with nounset in all versions.
    set +u
    source "$NVM_DIR/nvm.sh"
    set -u
  fi
  local node_major=0 nvm_line
  if command -v node >/dev/null; then
    node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
  fi
  if (( node_major < 22 )) || ! command -v npm >/dev/null; then
    if [[ ! -s $NVM_DIR/nvm.sh ]]; then
      download https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh "$WORK_DIR/nvm-install.sh"
      PROFILE=/dev/null bash "$WORK_DIR/nvm-install.sh"
      set +u
      source "$NVM_DIR/nvm.sh"
      set -u
    fi
    set +u
    nvm install --lts
    nvm alias default 'lts/*'
    set -u
  fi
  if [[ -s $NVM_DIR/nvm.sh ]]; then
    printf -v nvm_line 'export NVM_DIR=%q; [ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"' "$NVM_DIR"
    append_bashrc "$nvm_line"
    append_bashrc '[ -z "${NVM_BIN:-}" ] || export PATH="$NVM_BIN:$PATH"'
  fi
}
