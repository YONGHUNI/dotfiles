#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source_file="$repo_root/bin/pixi-nix-shim"
target_dir="$HOME/.pixi/bin"
target="$target_dir/pixi"
force=0

usage() {
    cat <<'USAGE'
Usage: ./install-pixi-nix-shim.sh [--force]

Install the portable Positron/Pixi/Nix shim at ~/.pixi/bin/pixi.
Existing unmanaged files are left untouched unless --force is given.
USAGE
}

while (($#)); do
    case "$1" in
        --force) force=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -f "$source_file" ]] || {
    printf 'Missing shim source: %s\n' "$source_file" >&2
    exit 1
}

bash -n "$source_file"
mkdir -p "$target_dir"

if [[ -e "$target" || -L "$target" ]]; then
    if cmp -s "$source_file" "$target" 2>/dev/null; then
        printf 'Pixi Nix shim is already up to date: %s\n' "$target"
        exit 0
    fi

    managed=0
    if [[ -f "$target" ]] && grep -Fq '# Source: YONGHUNI/dotfiles/bin/pixi-nix-shim' "$target" 2>/dev/null; then
        managed=1
    fi

    if (( ! managed && ! force )); then
        printf 'Refusing to replace existing unmanaged path: %s\n' "$target" >&2
        printf 'Re-run with --force to back it up and install the shim.\n' >&2
        exit 2
    fi

    if (( ! managed )); then
        timestamp=$(date +%Y%m%d-%H%M%S)
        backup="${target}.bak.${timestamp}"
        cp -a "$target" "$backup"
        printf 'Backed up existing path: %s\n' "$backup"
    fi

    rm -f "$target"
fi

install -m 0755 "$source_file" "$target"
printf 'Installed Pixi Nix shim: %s\n' "$target"
printf 'The shim is intended for Positron discovery; it does not install Pixi or Nix.\n'
