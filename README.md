# My entire dev kit

This is an easy way to setup my own dev kit on other machines. The shell files
and this README was 99% written with Codex. The README in `ssh-setup/` is
my own tutorial on setting up SSH profiles and keys. There are no scripts
related to the SSH setup, since I would prefer to do that manually.

NOTE: These scripts are not extensively tested, but they will ask you whether
to backup, overwrite, or skip existing configuration files. I would RECOMMEND
choosing the backup option, unless you are me.

Anyways, on with the AI overview!

---

These scripts target Ubuntu/Debian Linux and WSL with Bash, apt,
sudo, and an internet connection. Run them as your normal user, not with sudo;
they request sudo only for system packages.

```bash
bash install.sh          # Aliases, tmux, Neovim, and Starship
bash extra.sh            # keychain, uv, Ruff, ty, and Codex
# Or install everything in one run:
bash install.sh --extras
```

Each installer also works individually, from any working directory:

| Script | Installs |
| --- | --- |
| `bash_aliases.sh` | `~/.bash_aliases`, its Bash loader, and tree/bat/git |
| `tmux.sh` | tmux configuration, TPM plugins, and Alt-h/j/k/l Readline bindings |
| `nvim.sh` | Neovim configuration, a suitable Neovim release if needed, and its dependencies |
| `starship.sh` | Starship, `starship.toml`, and Bash prompt initialization |
| `nerd_fonts.sh` | JetBrainsMono Nerd Font on Linux; Windows instructions on WSL |
| `extra.sh` | keychain startup, uv, Ruff and ty through uv, and Codex through npm |

When a configuration file or directory exists, the scripts ask whether to
**backup**, **overwrite**, or **skip** it. The default and end-of-input behavior
is skip. Backups live beside the original, named `.backup.DATE.PID`. Neovim's
entire configuration directory is replaced when you choose backup or overwrite.
Skipping tmux's configuration also skips plugin setup; skipping Neovim's
configuration skips its additional runtime dependencies but still checks and
installs the required Neovim executable.

For `~/.bashrc`, backup saves a copy before appending; overwrite appends without
a backup; skip leaves it alone. Existing content is preserved in both write
modes. The choice applies to all Bash additions by that script. Each addition
has a `# my-entire-dev-kit file_name.sh` comment. Identical lines are added only
once. Downloaded runtime installers are told not to edit shell startup files,
so these prompts also govern their Bash setup. Open a new Bash shell afterward.
If you skip Bash changes, add the printed PATH/settings yourself as needed.

Neovim must be **0.12.4 or newer**: `12.4` in `PROMPT.txt` is interpreted as
`0.12.4`, as confirmed by the user. A suitable installed version is reused;
otherwise the latest stable Linux x86_64/arm64 release is downloaded, checked,
and installed under `~/.local/share/my-entire-dev-kit/nvim`. Its bin directory
is added before older Neovim installations on PATH. To change the minimum:

```bash
NVIM_MIN_VERSION=0.12.4 bash nvim.sh
```

Neovim dependencies include the compiler/make toolchain, ripgrep, fd, unzip,
wget, git, curl, clang-format, CMake, GDB, Node/npm (nvm and current LTS when
needed), Rust/Cargo, Tree-sitter CLI, Deno for Peek, and clipboard tools. The
font installer runs as part of Neovim setup. Choose the installed Nerd Font in
your terminal; on WSL install it in Windows. Ruff and ty require `extra.sh`.
After installation, run `nvim` to download plugins and Mason tools, then run
`:checkhealth`. Plugin downloads/builds occur on first launch. See the
[Neovim README](https://github.com/CrunchyToothpicks100/kickstart.nvim#readme)
for configuration details.

The configuration is installed using the equivalent of:

```bash
git clone https://github.com/CrunchyToothpicks100/kickstart.nvim
mv kickstart.nvim/ nvim/
```

The script clones into a temporary directory, then moves the checkout to
`$XDG_CONFIG_HOME/nvim` (default `~/.config/nvim`) after applying your
backup/overwrite/skip choice. This prevents nesting a checkout inside an existing
`nvim` directory and preserves the destination if cloning fails. Git metadata
is retained so you can update it later with `git -C ~/.config/nvim pull`.
Each installation uses the repository's current default branch, so its contents
and dependency requirements may change. Commit and push local configuration
changes to include them in future installations; pin a commit if you need
identical installations over time. Files tracked in the upstream repository,
including any tracked undo files, are included in the clone.

Configurations use `$XDG_CONFIG_HOME` when set. Tmux uses `~/.tmux.conf`, or
`$XDG_CONFIG_HOME/tmux/tmux.conf` (defaulting to `~/.config/tmux/tmux.conf`) when
that file already exists, respecting tmux's configuration precedence.
For a nondefault Neovim configuration path, the installer adjusts the upstream
hardcoded undo-directory setting to follow Neovim's actual configuration path.
This creates a local change in `lua/options.lua`; review it when updating the
checkout. Default `~/.config/nvim` installations retain an unmodified checkout.
Neovim is no longer duplicated under `assets/`; the other configuration assets
remain in this repository.

On WSL, the Neovim script uses the Windows clipboard and installs wslu when
available from apt. When `wslview` is available, it offers to install a user
`xdg-open` wrapper for Peek. Otherwise it prints a reminder to configure a
browser opener. On Linux, it installs wl-clipboard for Wayland or xclip for
X11. Headless systems still need a working display/clipboard session for copying.

Starship, uv, and Codex install into user-owned locations. Existing Starship,
uv, Cargo, Tree-sitter CLI, and Deno executables are reused. Ruff and ty are
installed/upgraded with `uv tool install --upgrade`; Codex is installed/upgraded
with `npm install --global --prefix "$HOME/.local" @openai/codex@latest`.
Run `codex` to sign in after installation. keychain is configured for the SSH
agent without naming or creating keys. `ssh-setup/` is outside these installers.

Installation commands follow [official OpenAI documentation](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex),
the [Neovim releases](https://github.com/neovim/neovim/releases/latest),
[nvm documentation](https://github.com/nvm-sh/nvm#installing-and-updating),
[uv installation guide](https://docs.astral.sh/uv/getting-started/installation/),
and [Starship installation guide](https://starship.rs/guide/).

Creating these files does not install anything. Running the scripts explicitly
installs packages and writes to the target user's home directory.
