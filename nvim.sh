#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
devkit_init

# Minimum version confirmed by the user.
NVIM_MIN_VERSION="${NVIM_MIN_VERSION:-0.12.4}"
[[ $NVIM_MIN_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'NVIM_MIN_VERSION must be major.minor.patch.'
NVIM_INSTALL_DIR="$HOME/.local/share/my-entire-dev-kit/nvim"

nvim_version() {
  "$1" --version | sed -n '1s/^NVIM v\([^[:space:]]*\).*/\1/p'
}

nvim_is_recent() {
  local version
  version="$(nvim_version "$1")" || return 1
  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || return 1
  # A development build of the required version precedes its stable release.
  dpkg --compare-versions "${version/-/\~}" ge "$NVIM_MIN_VERSION"
}

install_nvim() {
  local arch binary
  if command -v nvim >/dev/null; then
    binary="$(command -v nvim)"
    echo "Found Neovim $(nvim_version "$binary") at $binary; minimum is $NVIM_MIN_VERSION."
    if nvim_is_recent "$binary"; then
      add_path "$(dirname -- "$binary")"
      return
    fi
  fi
  if [[ -x $NVIM_INSTALL_DIR/bin/nvim ]] && nvim_is_recent "$NVIM_INSTALL_DIR/bin/nvim"; then
    add_path "$NVIM_INSTALL_DIR/bin"
    return
  fi
  case $(uname -m) in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) die 'Neovim release installation supports Linux x86_64 and arm64.' ;;
  esac
  download "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" "$WORK_DIR/nvim.tar.gz"
  tar -xzf "$WORK_DIR/nvim.tar.gz" -C "$WORK_DIR"
  binary="$WORK_DIR/nvim-linux-${arch}/bin/nvim"
  nvim_is_recent "$binary" || die "The downloaded release does not meet Neovim >= $NVIM_MIN_VERSION."
  choose_existing "$NVIM_INSTALL_DIR"
  [[ $FILE_CHOICE != skip ]] || die 'Skipped Neovim installation; no suitable existing version was found.'
  replace_target "$WORK_DIR/nvim-linux-${arch}" "$NVIM_INSTALL_DIR" "$FILE_CHOICE"
  add_path "$NVIM_INSTALL_DIR/bin"
}

choose_existing "$CONFIG_DIR/nvim"
NVIM_CONFIG_CHOICE=$FILE_CHOICE
apt_install git curl ca-certificates build-essential unzip wget ripgrep fd-find \
  clang-format cmake gdb xdg-utils
install_nvim

if [[ $NVIM_CONFIG_CHOICE == skip ]]; then
  echo 'Skipped Neovim configuration and its additional runtime dependencies.'
  exit 0
fi

# Clone before replacing the destination so a network failure preserves it.
git clone https://github.com/CrunchyToothpicks100/kickstart.nvim "$WORK_DIR/kickstart.nvim"
[[ -f $WORK_DIR/kickstart.nvim/init.lua && -d $WORK_DIR/kickstart.nvim/lua ]] || \
  die 'The cloned repository is missing its Neovim configuration.'
# Preserve the earlier XDG support; the upstream undo path is currently fixed.
# Default ~/.config installations keep an unmodified Git checkout.
if [[ $CONFIG_DIR != "$HOME/.config" && -f $WORK_DIR/kickstart.nvim/lua/options.lua ]]; then
  sed -i "s|vim\\.o\\.undodir = vim\\.fn\\.expand '~/.config/nvim/undofiles'|vim.o.undodir = vim.fn.stdpath 'config' .. '/undofiles'|" \
    "$WORK_DIR/kickstart.nvim/lua/options.lua"
fi

# Ubuntu/Debian call fd "fdfind"; Telescope expects "fd".
if ! command -v fd >/dev/null; then
  mkdir -p "$HOME/.local/bin"
  if [[ ! -e $HOME/.local/bin/fd && ! -L $HOME/.local/bin/fd ]]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
fi
add_path "$HOME/.local/bin"
ensure_node

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
export PATH="$CARGO_HOME/bin:$PATH"
if ! command -v cargo >/dev/null; then
  download https://sh.rustup.rs "$WORK_DIR/rustup-install.sh"
  sh "$WORK_DIR/rustup-install.sh" -y --profile minimal --no-modify-path
fi
add_path "$CARGO_HOME/bin"
if ! command -v tree-sitter >/dev/null; then
  cargo install tree-sitter-cli --locked
fi

export DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
export PATH="$DENO_INSTALL/bin:$PATH"
if ! command -v deno >/dev/null; then
  download https://deno.land/install.sh "$WORK_DIR/deno-install.sh"
  sh "$WORK_DIR/deno-install.sh" --yes --no-modify-path
fi
add_path "$DENO_INSTALL/bin"

# On WSL the Windows clipboard works even without a Linux display server.
if grep -qi microsoft /proc/sys/kernel/osrelease; then
  append_bashrc '[ ! -x /mnt/c/Windows/System32/clip.exe ] || export PATH="/mnt/c/Windows/System32:$PATH"'
  export PATH="/mnt/c/Windows/System32:$PATH"
  if ! command -v wslview >/dev/null && apt-cache show wslu >/dev/null 2>&1; then
    apt_install wslu
  fi
  if command -v wslview >/dev/null; then
    install_asset "$DEVKIT_DIR/assets/wsl-xdg-open" "$HOME/.local/bin/xdg-open"
    append_bashrc 'export BROWSER=wslview'
  else
    echo 'For Peek previews on WSL, install wslview or configure an opener in lua/plugins/peek.lua.'
  fi
elif [[ ${XDG_SESSION_TYPE:-} == wayland || -n ${WAYLAND_DISPLAY:-} ]]; then
  apt_install wl-clipboard
else
  apt_install xclip
fi

replace_target "$WORK_DIR/kickstart.nvim" "$CONFIG_DIR/nvim" "$NVIM_CONFIG_CHOICE" move
mkdir -p "$CONFIG_DIR/nvim/undofiles"
append_bashrc 'export EDITOR=nvim'
append_bashrc 'export LAUNCH_EDITOR=nvim'
bash "$DEVKIT_DIR/nerd_fonts.sh"
echo 'Neovim installed. Run bash extra.sh for uv, Ruff, and ty used by this configuration.'
echo 'Then open nvim to install plugins and Mason tools; run :checkhealth after installation.'
