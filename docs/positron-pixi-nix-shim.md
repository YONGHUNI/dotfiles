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

After updating the dotfiles, start a new login shell (for example, disconnect and reconnect over SSH). If the current shell was started with an older configuration that already placed `~/.pixi/bin` on `PATH`, merely sourcing the new `.bashrc` does not remove that inherited PATH entry.

Expected behavior in a fresh shell is:

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
5. inside an existing `nix develop`, uses the active Pixi directly (no nested user namespace); on a rootless-nix-bootstrap host without a host-visible Nix store, uses `nix run <flake>#pixi` to keep execution inside the namespace; otherwise resolves `packages.<system>.pixi` with `nix build --no-link --print-out-paths`, falling back to `nix run` for app-only flakes;
6. reads the pinned Pixi version and normalizes the TLS root certificate option when needed (`native` for versions below 0.69, `system` for newer versions);
7. executes the binary directly with the original arguments unchanged.

Conceptually:

```text
~/.pixi/bin/pixi
        ↓
nix build --no-link --print-out-paths <flake-root>#pixi
        ↓
/nix/store/.../bin/pixi <original arguments>

App-only flakes fall back to two `nix run` invocations for version discovery and execution.
```

For the fast path, the project flake exposes:

```text
packages.<system>.pixi
```

Legacy app-only flakes exposing `apps.<system>.pixi` remain supported through a slower fallback.

The data-science templates in `YONGHUNI/nix-data-science-templates` expose both `apps.<system>.pixi` and `packages.<system>.pixi` while continuing to provide Pixi inside the normal development shell.

The shim deliberately does **not** enter `nix develop`. That distinction is important for IDE integration: Positron may inspect the environment produced by `pixi run`, and wrapping every Pixi invocation in a development shell can cause Nix devShell variables such as `IN_NIX_SHELL`, `NIX_*`, devShell `PATH`, or a Nix-provided `SHELL` to be mistaken for Pixi activation variables. Directly running the project-pinned Pixi app keeps the IDE-facing process environment narrower while preserving the normal interactive workflow:

```bash
nix develop
pixi install
pixi run python analysis.py
```

The shim deliberately contains no fixed `/nix/store/<hash>-...` paths, so Nix upgrades and garbage collection do not invalidate it. It does not install Pixi globally, install Nix, configure CUDA, or modify project dependencies. The first `nix build` may realize the pinned Pixi package into the Nix store if not already present.

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
- a flake package named `pixi` (`packages.<system>.pixi`), or a fallback app (`apps.<system>.pixi`)

If neither flake output exposes `pixi`, the shim fails instead of falling back to an unrelated global installation.

## TLS compatibility

Older Pixi (e.g. 0.68.1) accepts `native` but not `system` for `PIXI_TLS_ROOT_CERTS`. Pixi 0.69 and later accept `system`. The shim checks the project-pinned version at invocation time, normalizes incompatible `native`/`system` spellings, and preserves explicit `webpki`/`all` preferences. It does not alter the ordinary `nix develop` shell or the project's `pixi.toml`.

To run the local mocked regression checks:

```bash
bash tests/test-pixi-nix-shim.sh
```

## Update

After updating the dotfiles repository, rerun:

```bash
./install-pixi-nix-shim.sh
```

The managed copy at `~/.pixi/bin/pixi` will be replaced only when its contents changed.

## Sapelo2 / rootless Nix notes

When rootless-nix-bootstrap uses `nix-user-chroot`, the Nix store may exist only inside the chroot namespace. Executing a `/nix/store/...` path **after** the `nix build` wrapper returns is not portable. The shim therefore uses `nix run <flake>#pixi` on such hosts. It runs once to determine the pinned Pixi version and again to execute the requested Pixi command, applying the matching TLS option.

The shim is not intended to be placed on the interactive shell PATH. If invoked explicitly from inside `nix develop`, it now uses the active Pixi rather than nesting the rootless Nix wrapper. Positron's remote extension host generally runs outside the project devShell, where the rootless `nix run` path applies.

To test after updating on Sapelo2, run `~/.pixi/bin/pixi --version` **outside** `nix develop` from the project directory. Update the managed copy with `./install-pixi-nix-shim.sh`; do not assume a git pull alone replaces the installed script.

## Slurm node-local Pixi cache

Positron's extension host can invoke the Pixi shim without sourcing a project's `nix develop` shellHook. On Sapelo2, this used to leave `PIXI_CACHE_DIR` unset and cause Pixi/rattler to warn about using a network-filesystem repodata cache at `~/.cache/rattler`.

When `SLURM_JOB_ID` is present and `/lscratch/$USER` is available, the shim now sets `PIXI_CACHE_DIR=/lscratch/$USER/pixi-cache` for its Pixi subprocess. Explicit `PIXI_CACHE_DIR` and `RATTLER_CACHE_DIR` settings always take precedence. The project `.pixi/config.toml` still controls `detached-environments` separately. It does not create or install an environment during interpreter discovery.

This is not a replacement for the project's shellHook, which continues to set the cache path for direct `nix develop` usage.
