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

| Language | LSP | Install |
|----------|-----|---------|
| Python | pyright, black | `micromamba install pyright black` |
| C++/CUDA | clangd, clang-format | `module load clang/20` |
| Julia | LanguageServer.jl | `julia -e 'using Pkg; Pkg.add("LanguageServer")'` |
| R | languageserver | `R -e 'install.packages("languageserver")'` |
