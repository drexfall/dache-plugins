#!/usr/bin/env bash
# Downloads the plugin-cli release named in CLI_VERSION, checks it against CLI_SHA256 and prints the path of its
# launcher. The Publish workflow hands this binary the index signing key, so a release asset that was replaced
# after the fact must not run: a zip whose digest doesn't match fails here, before anything is unpacked.
set -euo pipefail
root="$(dirname "$0")/.."
version="$(cat "$root/CLI_VERSION")"
expected="$(tr -d '[:space:]' < "$root/CLI_SHA256")"
dir="${RUNNER_TEMP:-/tmp}/dache-plugin"
zip="$dir/dache-plugin-$version.zip"
rm -rf "$dir" && mkdir -p "$dir"
gh release download "cli-$version" --pattern "dache-plugin-$version.zip" --dir "$dir" >&2
actual="$(sha256sum "$zip" | cut -d' ' -f1)"
if [ "$actual" != "$expected" ]; then
  echo "::error::dache-plugin-$version.zip has SHA-256 $actual, but CLI_SHA256 says $expected" >&2
  exit 1
fi
unzip -q "$zip" -d "$dir"
echo "$dir/dache-plugin-$version/bin/dache-plugin"
