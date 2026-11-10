#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd -P)
shim="$repo_root/bin/pixi-nix-shim"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mock-bin" "$tmp/store/bin" "$tmp/project with spaces/subdir" "$tmp/outside"
touch "$tmp/project with spaces/flake.nix" "$tmp/project with spaces/pixi.toml"

cat > "$tmp/mock-bin/nix" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$CALL_LOG"
if [[ "$1" == build && "$2" == --no-link && "$3" == --print-out-paths ]]; then
    [[ "${APP_ONLY:-0}" == 1 ]] && exit 1
    printf '%s\n' "$STORE_DIR"
elif [[ "$1" == run && "$3" == -- ]]; then
    exec "$STORE_DIR/bin/pixi" "${@:4}"
else
    exit 2
fi
MOCK
cat > "$tmp/store/bin/pixi" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == --version ]]; then
    echo "pixi $MOCK_VERSION"
else
    printf 'tls=%s\n' "${PIXI_TLS_ROOT_CERTS-<unset>}"
    printf 'args='
    printf '%q ' "$@"
    printf '\n'
fi
MOCK
chmod +x "$tmp/mock-bin/nix" "$tmp/store/bin/pixi"
export PATH="$tmp/mock-bin:$PATH" STORE_DIR="$tmp/store" CALL_LOG="$tmp/calls"

check() {
    local version=$1 expected=$2 inherited=${3:-unset} output
    : > "$CALL_LOG"
    if [[ "$inherited" == unset ]]; then
        output=$(cd "$tmp/project with spaces/subdir" && env -u PIXI_TLS_ROOT_CERTS MOCK_VERSION="$version" bash "$shim" run --frozen R --version)
    else
        output=$(cd "$tmp/project with spaces/subdir" && PIXI_TLS_ROOT_CERTS="$inherited" MOCK_VERSION="$version" bash "$shim" run --frozen R --version)
    fi
    [[ "$output" == *"tls=$expected"* ]] || { echo "Bad TLS: $output" >&2; exit 1; }
    [[ "$output" == *'args=run --frozen R --version '* ]] || { echo "Bad args: $output" >&2; exit 1; }
    [[ $(wc -l < "$CALL_LOG") -eq 1 ]] || { echo "Expected one Nix call" >&2; exit 1; }
}
check 0.68.1 native
check 0.68.1 native system
check 0.68.1 webpki webpki
check 0.69.0 '<unset>'
check 0.69.0 system native
check 0.73.0 system system
check 1.0.0 '<unset>'

: > "$CALL_LOG"
output=$(cd "$tmp/outside" && env -u PIXI_TLS_ROOT_CERTS MOCK_VERSION=0.68.1 bash "$shim" run --manifest-path "$tmp/project with spaces/pixi.toml" R)
[[ "$output" == *'tls=native'* ]] || exit 1
[[ $(wc -l < "$CALL_LOG") -eq 1 ]] || exit 1

: > "$CALL_LOG"
output=$(cd "$tmp/project with spaces/subdir" && env -u PIXI_TLS_ROOT_CERTS APP_ONLY=1 MOCK_VERSION=0.68.1 bash "$shim" run R)
[[ "$output" == *'tls=native'* ]] || exit 1
[[ $(wc -l < "$CALL_LOG") -eq 3 ]] || exit 1
echo 'pixi-nix-shim: 9 checks passed'
