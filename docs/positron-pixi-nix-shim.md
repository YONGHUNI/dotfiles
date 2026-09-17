# Positron Pixi-Nix shim

This repository includes an optional portable shim for Positron's Pixi discovery when Pixi is intentionally provided by a project-local Nix dev shell instead of installed globally.

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

## How it works

The shim:

1. starts from the current working directory, or from Positron's `--manifest-path` when supplied;
2. canonicalizes symlinked paths;
3. walks upward to the nearest `flake.nix`;
4. finds `nix` from the current `PATH` or common user/system installation locations;
5. executes:

```bash
nix develop <flake-root> -c pixi ...
```

This keeps the Pixi executable project-local and lets each flake control the Pixi version.

The shim deliberately contains no `/nix/store/<hash>-...` paths, so Nix upgrades and garbage collection do not invalidate it. It also does not alter the login shell's `PATH`, install Pixi, install Nix, or configure CUDA.

Known Nix locations checked when Positron starts with a reduced GUI environment include:

```text
~/.local/bin/nix
~/.nix-profile/bin/nix
/run/current-system/sw/bin/nix
/usr/local/bin/nix
/usr/bin/nix
```

This covers the `rootless-nix-bootstrap` wrapper, normal single-user Nix installations, NixOS, and common system installations.

## Requirements

- Bash
- `nix`
- GNU/coreutils-style `realpath` and `dirname`
- a project with `flake.nix`
- a dev shell that actually provides `pixi`

If the selected dev shell does not provide Pixi, the recursion guard fails explicitly rather than repeatedly invoking the shim.

## Update

After updating the dotfiles repository, rerun:

```bash
./install-pixi-nix-shim.sh
```

The managed copy at `~/.pixi/bin/pixi` will be replaced only when its contents changed.
