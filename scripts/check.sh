#!/usr/bin/env bash
# Validates every manifest, runs fixture tests where a plugin has them, and builds the index without signing it.
# Usage: scripts/check.sh <path to dache-plugin>
set -euo pipefail
cli="$1"
cd "$(dirname "$0")/.."

"$cli" validate plugins/*/manifest.json

for plugin in plugins/*/; do
  [ -d "$plugin/fixtures" ] || continue
  settings=()
  if [ -f "$plugin/test-settings" ]; then
    while IFS= read -r line; do [ -n "$line" ] && settings+=(--setting "$line"); done < "$plugin/test-settings"
  fi
  echo "== ${plugin%/} fixtures"
  "$cli" test "$plugin/manifest.json" --fixtures "$plugin/fixtures" "${settings[@]}"
done

index="${RUNNER_TEMP:-/tmp}/dache-index-check"
"$cli" index . --out "$index"

# The check Publish makes, run before merging: a version already on the index branch must not change.
if git fetch -q --depth=1 origin index 2> /dev/null; then
  for file in $(cd "$index" && find plugins -name '*.json'); do
    if git cat-file -e "FETCH_HEAD:$file" 2> /dev/null && ! git show "FETCH_HEAD:$file" | cmp -s - "$index/$file"; then
      echo "::error::$file is already published with different content; bump the plugin's version"
      exit 1
    fi
  done
fi
