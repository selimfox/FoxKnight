#!/usr/bin/env bash
# Run with bash scripts/cloud/check.sh after setup.sh.
set -euo pipefail
readonly project=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
readonly godot="${HOME:?HOME must be set}/.local/bin/godot-4.7.1"
readonly logs="$project/output/cloud"
fail() { printf 'CHECK FAIL | %s\n' "$*" >&2; exit 1; }
command -v timeout >/dev/null || fail 'GNU timeout is required.'
[[ -x "$godot" ]] || fail 'Run bash scripts/cloud/setup.sh first.'
timeout 30 "$godot" --headless --version | grep -Eq '^4\.7\.1\.stable(\.|$)' \
    || fail 'Expected runnable Godot 4.7.1 stable.'
mkdir -p "$logs" "$project/output/art_revision_20260930"
export GODOT_SILENCE_ROOT_WARNING=1
run_logged() {
    local name=$1 expected=$2
    shift 2
    local log="$logs/$name.log" status=0
    printf 'CHECK | %s\n' "$name"
    timeout --kill-after=10s 300s "$godot" --headless --audio-driver Dummy \
        --path "$project" "$@" > "$log" 2>&1 || status=$?
    cat "$log"
    [[ $status == 0 ]] || fail "$name exited $status; see $log"
    if grep -Eiq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|Parse Error:|FAIL[[:space:]]*\||RESULT[[:space:]]*\|[[:space:]]*FAIL)' "$log"; then
        fail "$name reported errors; see $log"
    fi
    if [[ -n "$expected" ]] && ! grep -Fxq "$expected" "$log"; then
        fail "$name did not emit its exact PASS result; see $log"
    fi
}
run_logged import '' --editor --import
run_logged smoke 'RESULT | PASS | Prototype smoke acceptance' \
    --script res://tests/acceptance/acceptance_runner.gd
run_logged campaign 'RESULT | PASS | Campaign and TileMap acceptance' \
    --script res://tests/acceptance/campaign_runner.gd
printf 'CHECK PASS | import, core smoke and campaign acceptance; logs: %s\n' "$logs"
# Headless checks do not certify graphical rendering, art quality or player experience.
