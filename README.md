# dotfiles

Shared Bash, Vim, tmux, and R configuration for Linux, NixOS, WSL, and remote Linux systems.

The repository keeps host-independent shell/editor behavior in one place. Machine-specific packages, services, credentials, and institutional access configuration belong in the host configuration instead of these dotfiles.

## Quick start

```bash
git clone https://github.com/YONGHUNI/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` links the managed dotfiles into `$HOME`, installs vim-plug when missing, installs Vim plugins, and reports available language tools.

On NixOS hosts managed by [`nix-config`](https://github.com/YONGHUNI/nix-config), Home Manager links the shared files from this repository instead. The `dotfiles` flake input is locked, so update that input when you want a NixOS host to consume a new dotfiles commit:

```bash
cd ~/nix-config
nix flake update dotfiles
```

## What's included

- `.bash_profile` - sources `.bashrc` for login Bash sessions.
- `.bashrc` - adaptive Powerline-style prompt with local/remote host state, memory usage, command timing, environment context, and Git status.
- `.vimrc` - vim-plug setup, ALE completion/linting/fixing, vim-slime tmux integration, and filetype rules for Python, C/CUDA/C++, R, Julia, Quarto, YAML, and Nix.
- `.tmux.conf` - `C-a` prefix, vim-style pane navigation/resizing, vi copy mode, and a compact status bar. Mouse is disabled inside VS Code-compatible terminals.
- `.Rprofile` - adds `~/R/library` to the R library path.

## Adaptive Bash prompt

The first prompt line contains host, memory, and command-time information on the left. Environment and Git information is kept on the right.

A wide terminal looks roughly like:

```text
nixos-research  MEM ...  20ms                         pixi:my-project  master
╭─ ♥ 17:40:05 | 0 | ~/data/projects/my-project
╰─$
```

When the left and right sections no longer fit, the right-side modules automatically move to a separate right-aligned line instead of overwriting the left side:

```text
nixos-research  MEM ...  20ms
                                                     pixi:my-project  master
╭─ ♥ 17:40:05 | 0 | ~/data/projects/my-project
╰─$
```

The environment module is detected at prompt-render time, so entering or leaving a nested project shell is reflected without editing the prompt configuration.

Recognized contexts:

- Nix development shell: `IN_NIX_SHELL`
- Pixi shell: `PIXI_PROJECT_NAME` / `PIXI_ENVIRONMENT_NAME`
- Python virtual environment: `VIRTUAL_ENV`
- Conda environment: `CONDA_DEFAULT_ENV`
- Git repository: branch plus staged, modified, and untracked counts

Pixi receives its own shell module and the Conda-style Python module is suppressed while Pixi is active, avoiding duplicate environment labels.

For a custom Nix development-shell label, set `NIX_SHELL_NAME` in the project's `shellHook`, for example:

```nix
shellHook = ''
  export NIX_SHELL_NAME=geoai
'';
```

The dotfiles deliberately do **not** auto-activate micromamba, Conda, Pixi, or Nix environments. Environment activation is project-local and explicit, which avoids hidden PATH changes and nested-environment conflicts.

## Environment model

Use this repository for shell and editor behavior. Install executables in the environment that owns them:

- NixOS hosts: system and shared user tools are managed by `nix-config`.
- WSL or other Linux systems not managed by Home Manager: use `install.sh` for these dotfiles and let the host manage executables.
- Project-specific runtimes and dependencies: keep them in each project environment (`nix develop`, `pixi shell`, Conda/venv, etc.) rather than hard-coding them here.
- Institution-specific SSH, Kerberos, module, proxy, or cluster configuration: keep it out of this repository and configure it only on hosts that still need it.

## Language tooling

Current Vim/ALE expectations:

- Python: `pyright`, `black`
- C/CUDA/C++: `clangd`, `clang-format`
- YAML: `yamllint`
- Nix: `statix`, `nixpkgs-fmt`
- R: `languageserver`
- Julia: `LanguageServer.jl`

The dotfiles configure these tools when they are available; they do not install the language runtimes themselves.

## Useful checks

```bash
# Shell syntax
bash -n ~/.bashrc

# Vim/ALE status
vim some-file.nix
:ALEInfo
```

For Nix files, `Enabled Linters` should include `statix`, and the fixer should include `nixpkgs-fmt` when those tools are available in the current environment.
