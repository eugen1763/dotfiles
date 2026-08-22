#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"${runtime_dir}/elephant.lock"
flock -n 9 || exit 0

export ELEPHANT_PROVIDER_DIR="$HOME/.local/lib/elephant"
exec "$HOME/.local/bin/elephant"
