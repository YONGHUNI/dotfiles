# Positron Pixi-Nix shim

This repository includes an optional portable shim for Positron's Pixi discovery on remote Linux systems where Pixi is intentionally provided by a project-local Nix dev shell instead of installed globally.

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

The shared `.bashrc` keeps both `~/.local/bin` and `~/.pixi/bin` on `PATH`. This makes rootless-Nix commands such as `nix` available normally while keeping the shim available as the interactive `pixi` command. After updating the dotfiles, start a new shell or run:

```bash
source ~/.bashrc
```

## How it works

The shim:

1. starts from the current working directory, or from Positron's `--manifest-path` when supplied;
2. canonicalizes symlinked paths;
3. walks upward to the nearest `flake.nix`;
4. finds `nix` from the current `PATH` or common user/system installation locations;
5. removes the shim directory from the child `PATH` before entering the dev shell;
6. enters the project with `nix develop`;
7. requires the resulting `pixi` executable to come from `/nix/store/.../bin/pixi` before forwarding the original arguments.

Conceptually:

```text
~/.pixi/bin/pixi
        ↓
nix develop <flake-root>
        ↓
/nix/store/.../bin/pixi <original arguments>
```

This keeps the Pixi executable project-local and lets each flake control the Pixi version. Removing the shim path before `nix develop` prevents recursive self-invocation, including from a terminal that Positron has already activated as a Pixi environment. Requiring the dev-shell Pixi to come from the Nix store also prevents an unrelated host installation from being selected silently.

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
- a dev shell that provides `pixi` through Nix

If the selected dev shell does not provide Pixi, the shim exits with an explicit error instead of invoking itself again or falling back to an unrelated global Pixi.

## Update

After updating the dotfiles repository, rerun:

```bash
./install-pixi-nix-shim.sh
```

The managed copy at `~/.pixi/bin/pixi` will be replaced only when its contents changed.
