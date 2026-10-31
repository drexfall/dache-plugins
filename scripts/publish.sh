#!/usr/bin/env bash
# Builds and signs the index, then replaces the `index` branch with it. Needs DACHE_INDEX_KEY (the base64 Ed25519
# seed) and a token that may push. Usage: scripts/publish.sh <path to dache-plugin>
set -euo pipefail
cli="$1"
cd "$(dirname "$0")/.."
out="${RUNNER_TEMP:-/tmp}/dache-index"
rm -rf "$out"

"$cli" index . --out "$out"
"$cli" sign "$out/index.json" --key-env DACHE_INDEX_KEY

cd "$out"
git init -q -b index
git add .
git -c user.name="dache-registry" -c user.email="dache-registry@users.noreply.github.com" \
  commit -q -m "Publish index from ${GITHUB_SHA:-local}"
git push -q --force "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" index
echo "published $(grep -c '"id"' index.json) plugins"
