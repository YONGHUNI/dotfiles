# dotfiles

Shared shell, Vim, tmux, and R configuration for Linux, NixOS, WSL, and remote servers.

The same dotfiles are installed on each host. Host-specific behavior is handled by conditional checks in the files, not by maintaining separate branches.

## Quick start

```bash
git clone https://github.com/YONGHUNI/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` symlinks the dotfiles into `$HOME`, installs vim-plug when missing, installs Vim plugins, and reports available language tools.

## What's included

- `.bashrc` - Powerline-style prompt with git status, memory usage, command timer, and local/remote host indicator. Loads HPC modules only when the `module` command exists. Initializes micromamba only when `~/bin/micromamba` exists.
- `.vimrc` - vim-plug setup, ALE completion/linting/fixing, vim-slime tmux integration, and filetype rules for Python, C/CUDA/C++, R, Julia, Quarto, YAML, and Nix.
- `.tmux.conf` - `C-a` prefix, vim-style pane navigation/resizing, vi copy mode, and a compact status bar. Mouse is disabled inside VS Code.
- `.Rprofile` - Adds `~/R/library` to the R library path.

## Environment Model

Use this repository for editor and shell behavior. Install executables in the host environment that owns them:

- WSL NixOS: base tools are managed in `~/nix-config`.
- Remote servers and HPC systems: install or load executables using the environment provided by each host.
- Project-specific data science tools: keep them in each project environment, not in these dotfiles.

## Language Tooling

Current Vim/ALE expectations:

- Python: `pyright`, `black`
- C/CUDA/C++: `clangd`, `clang-format`
- YAML: `yamllint`
- Nix: `statix`, `nixpkgs-fmt`
- R: `languageserver`
- Julia: `LanguageServer.jl`


On WSL NixOS, Nix-related tools such as `statix` and `nixpkgs-fmt` are expected to come from `~/nix-config`.

## Useful Checks

```bash
vim some-file.nix
:ALEInfo
```

For Nix files, `Enabled Linters` should include `statix`, and the fixer should include `nixpkgs-fmt`.
