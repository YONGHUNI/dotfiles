# dotfiles

Shared Bash, Vim, and tmux configuration for Linux, NixOS, WSL, and remote Linux systems.

The repository keeps host-independent shell/editor behavior and small user-level workflow integrations in one place. Machine-specific packages, services, credentials, and institutional access configuration belong in the host configuration instead of these dotfiles.

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

## Optional Positron / Pixi integration

For hosts where Positron needs to discover Pixi but Pixi is intentionally provided by each project's Nix dev shell, this repository includes a portable shim:

```bash
cd ~/dotfiles
./install-pixi-nix-shim.sh
```

The installer places the shim at `~/.pixi/bin/pixi`, the fallback location Positron checks for Pixi. The shim finds the nearest `flake.nix` and delegates the requested Pixi command through:

```bash
nix develop <flake-root> -c pixi ...
```

This helper is optional and is not part of the normal `install.sh` flow. It does not install Nix, Pixi, CUDA, or project dependencies. It also avoids machine-specific `/nix/store/<hash>-...` paths so the same source can be used across NixOS, normal Nix installations, and remote Linux systems using [`rootless-nix-bootstrap`](https://github.com/YONGHUNI/rootless-nix-bootstrap).

See [`docs/positron-pixi-nix-shim.md`](docs/positron-pixi-nix-shim.md) for behavior, requirements, update handling, and overwrite safeguards.

## What's included

- `.bash_profile` - sources `.bashrc` for login Bash sessions.
- `.bashrc` - adaptive Powerline-style prompt with local/remote host state, memory usage, command timing, environment context, and Git status.
- `.vimrc` - vim-plug setup, ALE completion/linting/fixing, vim-slime tmux integration, and filetype rules for Python, C/CUDA/C++, R, Julia, Quarto, YAML, and Nix.
- `.tmux.conf` - `C-a` prefix, vim-style pane navigation/resizing, vi copy mode, and a compact status bar. Mouse is disabled inside VS Code-compatible terminals.
- `bin/pixi-nix-shim` - portable Positron-to-Pixi bridge that enters the project's Nix dev shell before invoking Pixi.
- `install-pixi-nix-shim.sh` - safe installer/updater for `~/.pixi/bin/pixi`; unrelated existing files are not overwritten unless explicitly requested.

A global `.Rprofile` is intentionally not managed. R library paths and packages should come from the active project environment rather than a shared `~/R/library`, which keeps Nix/Pixi/renv-style environments isolated and reproducible.

## Adaptive Bash prompt

The first prompt line contains host, memory, and command-time information on the left. Environment and Git information is kept on the right.

A wide terminal can look roughly like:

```text
nixos-research  MEM ...  20ms               nix:dev +  pixi:my-project  main
╭─ ♥ 17:40:05 | 0 | ~/data/projects/my-project
╰─$
```

When the left and right sections no longer fit, the right-side modules automatically move to a separate right-aligned line instead of overwriting the left side.

Recognized contexts:

- interactive `nix shell`: displayed as ` nix:shell`
- `nix develop`: displayed as ` nix:dev`, or ` nix:<name>` when `NIX_SHELL_NAME` is set
- Pixi: displayed as ` pixi:<project>` (and includes a non-default Pixi environment name when present)
- Python virtual environment: ` <venv>`
- Conda environment: ` <conda-env>`
- Git repository: branch plus staged, modified, and untracked counts

When Nix and Pixi are nested, they are grouped in one environment segment, for example:

```text
  nix:dev +  pixi:my-project   main ~1
```

Pixi uses the Python logo and suppresses the duplicate Conda-style environment label that Pixi may expose internally.

### `nix shell` handling

Unlike `nix develop`, interactive `nix shell` does not expose a dedicated prompt marker. The Bash configuration therefore wraps only the interactive `nix shell` subcommand and passes `NIX_SHELL_KIND=shell` into the spawned shell.

Other Nix commands keep their normal behavior. In particular, `nix shell ... -c ...` / `--command ...` is passed through unchanged because it executes a command rather than opening an interactive shell.

For a custom `nix develop` label, set `NIX_SHELL_NAME` in the project's `shellHook`, for example:

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
- Project-specific runtimes and dependencies: keep them in each project environment (`nix develop`, `nix shell`, `pixi shell`, Conda/venv, `renv`, etc.) rather than hard-coding them here.
- Optional user-level integration shims may live here when they are host-independent and do not own the underlying runtime or project dependencies.
- Institution-specific SSH, Kerberos, module, proxy, or cluster configuration: keep it out of this repository and configure it only on hosts that still need it.

## Language tooling

Current Vim/ALE expectations:

- Python: `pyright`, `black`
- C/CUDA/C++: `clangd`, `clang-format`
- YAML: `yamllint`
- Nix: `statix`, `nixpkgs-fmt`
- R: `languageserver`
- Julia: `LanguageServer.jl`

The dotfiles configure these tools when they are available; they do not install the language runtimes themselves or override their package/library paths.

## Useful checks

```bash
# Shell syntax
bash -n ~/.bashrc

# Vim/ALE status
vim some-file.nix
:ALEInfo
```

For Nix files, `Enabled Linters` should include `statix`, and the fixer should include `nixpkgs-fmt` when those tools are available in the current environment.
