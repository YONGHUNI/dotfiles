# dotfiles

Unified shell, vim, and tmux configuration for WSL and HPC servers.

## Quick start

```bash
git clone https://github.com/YONGHUNI/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash install.sh
```

## What's included

- **`.bashrc`** — Powerline prompt with git status, memory usage, timer. Conditional micromamba and HPC module loading.
- **`.vimrc`** — ALE LSP (pyright, clangd, rust-analyzer, julia, R), vim-slime for tmux, auto-install vim-plug.
- **`.tmux.conf`** — Prefix C-a, vim-style navigation/resizing, vi copy mode, Powerline status bar.
- **`install.sh`** — Symlinks dotfiles, installs vim-plug + plugins, reports LSP availability.

## LSP dependencies

### MPCDF clusters (raven, etc.)

HPC module system provides most tools. `.bashrc` auto-loads them if `module` is available.

```bash
# Loaded automatically via .bashrc
module load clang/20 julia/1.11 R/4.5

# Python tools (one-time setup)
micromamba install -n base pyright black
```

### General Linux / WSL

```bash
# Python
pip install pyright black

# C++/CUDA
sudo apt install clangd clang-format        # Debian/Ubuntu
# or: nix-env -iA nixpkgs.clang-tools      # NixOS

# Julia
julia -e 'using Pkg; Pkg.add("LanguageServer")'

# R
R -e 'install.packages("languageserver")'
```

### macOS

```bash
pip install pyright black
brew install llvm                            # includes clangd, clang-format
julia -e 'using Pkg; Pkg.add("LanguageServer")'
R -e 'install.packages("languageserver")'
```

`install.sh` will report which LSPs are found and which are missing after setup.
