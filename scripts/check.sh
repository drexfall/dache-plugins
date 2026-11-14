#!/usr/bin/env bash
# Validates every manifest, runs every plugin's fixture tests (a plugin without fixtures fails), and builds the
# index without signing it.
# Usage: scripts/check.sh <path to dache-plugin>
set -euo pipefail
cli="$1"
cd "$(dirname "$0")/.."

"$cli" validate plugins/*/manifest.json

for plugin in plugins/*/; do
  if [ ! -d "$plugin/fixtures" ]; then
    echo "::error::${plugin%/} has no fixtures; record at least the token check and each list (see README)"
    exit 1
  fi
  settings=()
  if [ -f "$plugin/test-settings" ]; then
    while IFS= read -r line; do [ -n "$line" ] && settings+=(--setting "$line"); done < "$plugin/test-settings"
  fi
  echo "== ${plugin%/} fixtures"
  "$cli" test "$plugin/manifest.json" --fixtures "$plugin/fixtures" "${settings[@]}"
done

"$cli" index . --out "${RUNNER_TEMP:-/tmp}/dache-index-check"
