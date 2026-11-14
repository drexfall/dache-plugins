#!/usr/bin/env bash
# Builds and signs the index, then adds it as a new commit on the `index` branch. Manifests of earlier versions
# stay there, so the branch's history is a record of everything ever published. Needs DACHE_INDEX_KEY (the base64
# Ed25519 seed) and a token that may push. Usage: scripts/publish.sh <path to dache-plugin>
set -euo pipefail
cli="$1"
cd "$(dirname "$0")/.."
out="${RUNNER_TEMP:-/tmp}/dache-index"
branch="${RUNNER_TEMP:-/tmp}/dache-index-branch"
remote="${INDEX_REMOTE:-https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git}"
rm -rf "$out" "$branch"

"$cli" index . --out "$out"
"$cli" sign "$out/index.json" --key-env DACHE_INDEX_KEY

if git ls-remote --exit-code --heads "$remote" index > /dev/null; then
  git clone -q --branch index --single-branch "$remote" "$branch"
else
  git init -q -b index "$branch"
fi

cp -R "$out"/. "$branch"/
cd "$branch"
git add -A
git -c user.name="dache-registry" -c user.email="dache-registry@users.noreply.github.com" \
  commit -q -m "Publish index from ${GITHUB_SHA:-local}"
git push -q "$remote" index
echo "published $(grep -c '"path"' index.json) plugins"
