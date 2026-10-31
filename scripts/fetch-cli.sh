#!/usr/bin/env bash
# Downloads the plugin-cli release named in CLI_VERSION and prints the path of its launcher.
set -euo pipefail
version="$(cat "$(dirname "$0")/../CLI_VERSION")"
dir="${RUNNER_TEMP:-/tmp}/dache-plugin"
rm -rf "$dir" && mkdir -p "$dir"
gh release download "cli-$version" --pattern "dache-plugin-$version.zip" --dir "$dir" >&2
unzip -q "$dir/dache-plugin-$version.zip" -d "$dir"
echo "$dir/dache-plugin-$version/bin/dache-plugin"
