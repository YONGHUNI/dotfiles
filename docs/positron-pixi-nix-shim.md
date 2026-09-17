# Positron Pixi-Nix shim

This repository includes an optional portable shim for Positron's Pixi discovery on remote Linux systems where Pixi is intentionally provided by a project flake instead of installed globally.

## Install

```bash
cd ~/dotfiles
./install-pixi-nix-shim.sh
```

The installer copies `bin/pixi-nix-shim` to:

```text
~/.pixi/bin/pixi
```

It is idempotent. If an unrelated file already exists at that path, the installer refuses to overwrite it. Use `--force` only when you intentionally want the installer to back up the existing file and replace it.

The shared `.bashrc` keeps `~/.local/bin` on `PATH` so rootless-Nix commands such as `nix` remain available, but deliberately leaves `~/.pixi/bin` off the interactive shell `PATH`. As a result, `pixi` is not a normal shell command outside a project devShell. Positron still checks `~/.pixi/bin/pixi` directly as its fallback installation location, so IDE discovery continues to use the shim.

After updating the dotfiles, start a new shell or run:

```bash
source ~/.bashrc
hash -r
```

Expected shell behavior is:

```text
outside nix develop:  pixi -> not found
inside nix develop:   pixi -> /nix/store/.../bin/pixi
Positron discovery:   ~/.pixi/bin/pixi -> shim -> nix run <flake>#pixi
```

## How it works

The shim:

1. starts from the current working directory, or from Positron's `--manifest-path` when supplied;
2. canonicalizes symlinked paths;
3. walks upward to the nearest `flake.nix`;
4. finds `nix` from the current `PATH` or common user/system installation locations;
5. invokes the project's `pixi` flake app with `nix run`;
6. forwards the original Pixi arguments unchanged.

Conceptually:

```text
~/.pixi/bin/pixi
        ↓
nix run <flake-root>#pixi -- <original arguments>
        ↓
/nix/store/.../bin/pixi <original arguments>
```

The project flake must expose:

```text
apps.<system>.pixi
```

The data-science templates in `YONGHUNI/nix-data-science-templates` expose both `apps.<system>.pixi` and `packages.<system>.pixi` while continuing to provide Pixi inside the normal development shell.

The shim deliberately does **not** enter `nix develop`. That distinction is important for IDE integration: Positron may inspect the environment produced by `pixi run`, and wrapping every Pixi invocation in a development shell can cause Nix devShell variables such as `IN_NIX_SHELL`, `NIX_*`, devShell `PATH`, or a Nix-provided `SHELL` to be mistaken for Pixi activation variables. Directly running the project-pinned Pixi app keeps the IDE-facing process environment narrower while preserving the normal interactive workflow:

```bash
nix develop
pixi install
pixi run python analysis.py
```

The shim deliberately contains no fixed `/nix/store/<hash>-...` paths, so Nix upgrades and garbage collection do not invalidate it. It does not install Pixi, install Nix, configure CUDA, or modify project dependencies.

Known Nix locations checked when Positron starts with a reduced GUI environment include:

```text
~/.local/bin/nix
~/.nix-profile/bin/nix
/usr/local/bin/nix
/usr/bin/nix
```

The first path is the default wrapper location used by [`rootless-nix-bootstrap`](https://github.com/YONGHUNI/rootless-nix-bootstrap).

## Requirements

- Bash
- `nix`
- GNU/coreutils-style `realpath` and `dirname`
- a project with `flake.nix`
- a flake app named `pixi` (`apps.<system>.pixi`)

If the project flake does not expose the `pixi` app, `nix run <flake>#pixi` fails explicitly instead of falling back to an unrelated global Pixi.

## Update

After updating the dotfiles repository, rerun:

```bash
./install-pixi-nix-shim.sh
```

The managed copy at `~/.pixi/bin/pixi` will be replaced only when its contents changed.
