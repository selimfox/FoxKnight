#!/usr/bin/env bash
# Run with bash scripts/cloud/setup.sh. No sudo or export templates required.
set -euo pipefail
readonly version='4.7.1'
readonly release="${version}-stable"
readonly archive="Godot_v${release}_linux.x86_64.zip"
readonly executable="Godot_v${release}_linux.x86_64"
readonly origin="https://github.com/godotengine/godot-builds/releases/download/${release}"
readonly destination="${HOME:?HOME must be set}/.local/bin/godot-${version}"
fail() { printf 'SETUP FAIL | %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || fail 'Linux x86_64 is required.'
for command in curl sha512sum sha256sum awk unzip mktemp install timeout grep wc; do
    command -v "$command" >/dev/null || fail "Missing prerequisite: ${command} (add it to the environment image)."
done
# Reuse only an intact installation previously verified against the official manifest.
if [[ -x "$destination" && -f "${destination}.sha256" ]] &&
   sha256sum --check --status "${destination}.sha256" &&
   timeout 30 "$destination" --headless --version | grep -Eq '^4\.7\.1\.stable(\.|$)'; then
    printf 'SETUP PASS | verified Godot %s already installed at %s\n' "$version" "$destination"
    exit 0
fi
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
curl --fail --location --retry 3 --connect-timeout 30 --max-time 300 \
    "$origin/SHA512-SUMS.txt" --output "$temporary/SHA512-SUMS.txt"
curl --fail --location --retry 3 --connect-timeout 30 --max-time 600 \
    "$origin/$archive" --output "$temporary/$archive"
awk -v name="$archive" '{file=$2; sub(/^\*/, "", file); if(file==name) print $1 "  " name}' \
    "$temporary/SHA512-SUMS.txt" > "$temporary/selected.sha512"
[[ $(wc -l < "$temporary/selected.sha512") == 1 ]] || fail 'Expected one official archive checksum.'
(cd "$temporary" && sha512sum --check selected.sha512)
unzip -q "$temporary/$archive" "$executable" -d "$temporary"
chmod 755 "$temporary/$executable"
timeout 30 "$temporary/$executable" --headless --version | grep -Eq '^4\.7\.1\.stable(\.|$)' \
    || fail 'Downloaded binary cannot run or has an unexpected version.'
mkdir -p "$(dirname "$destination")"
install -m 755 "$temporary/$executable" "$destination"
sha256sum "$destination" > "${destination}.sha256"
printf 'SETUP PASS | Godot %s installed at %s\n' "$version" "$destination"
