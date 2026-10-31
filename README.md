# Dache plugin registry

Provider plugins for [Dache](https://github.com/drexfall/dache). Each plugin is a JSON manifest: the hosts it may call, where the token goes, and how API responses map onto Dache's models. Manifests contain no code.

This repository is private for now, so the app can't download the index anonymously yet. Making it public is all it takes to switch installs on; the URL the app uses doesn't change.

## Layout

```
plugins/<id>/manifest.json   the manifest; <id> must equal its "id"
plugins/<id>/fixtures/       optional recorded responses for `dache-plugin test`
plugins/<id>/test-settings   optional key=value lines passed as --setting to that test
manifest.schema.json         JSON Schema for editors
CLI_VERSION                  the plugin-cli release CI uses
scripts/                     what CI runs
```

## Adding or updating a plugin

1. Write the manifest following the plugin author's guide in the Dache repo (`docs/writing-a-plugin.md`). Set `publisher`, `dashboardUrl`, `tokenUrl` and `tokenHelp`.
2. Bump `version` (MAJOR.MINOR.PATCH) on every change. The app offers an update when the version differs.
3. Record fixtures for at least the token check and each list, so `dache-plugin test` passes offline.
4. Open a pull request. The Check workflow validates every manifest, runs fixture tests and builds an unsigned index.

Review before merging:

- Every host in `hosts` belongs to the provider and is needed.
- The token goes where the provider's docs say (`bearer`, a named `header`, or a `query` parameter only when nothing else works).
- A change to `hosts` or `auth` is deliberate. Apps never install such an update silently; users approve it again.
- `tokenHelp` asks for the least the plugin needs.

## Publishing

Merging to `main` runs Publish: it checks everything again, builds `index.json`, signs it, and force-pushes the result to the `index` branch:

```
index.json                     plugins, versions, SHA-256 of each manifest, hosts, auth, capabilities
index.json.sig                 base64 Ed25519 signature of index.json's exact bytes
plugins/<id>/<version>.json    the manifests, byte for byte
```

The app reads `https://raw.githubusercontent.com/drexfall/dache-plugins/index/index.json`, checks the signature against its pinned key, refuses an index whose `serial` is older than the last one it accepted, and checks each manifest's SHA-256 before installing.

## Signing key

- **Algorithm:** Ed25519. The app pins the public key: `zz14nlO7yt4dUa1RzyGCvPin2UqD3U8G1J2AkwbhGwI=`.
- **Holder:** the repository owner. The private key lives in two places only: the `DACHE_INDEX_KEY` Actions secret, which only the Publish workflow reads, and the owner's offline backup. It is never committed or printed.
- **Making a key:** `dache-plugin keygen <file>` writes the private key to an owner-only file and prints the public key. Set the secret with `gh secret set DACHE_INDEX_KEY < <file>`.

### Rotating

The app accepts an index signed by any key it pins, so rotation never strands installed apps:

1. Make a new key. Keep the old one.
2. Ship an app release that pins both public keys.
3. Once that release is widely installed, replace `DACHE_INDEX_KEY` with the new key and publish.
4. Drop the old public key from the next app release, and destroy the old private key.

If the key leaks, skip the wait: ship an app release pinning only the new key, then switch the secret. Apps that haven't updated keep their installed plugins but see no updates until they do.

## The CLI

CI downloads `dache-plugin-<version>.zip` from this repo's `cli-<version>` release, built in the Dache repo with `./gradlew :tools:plugin-cli:distZip`. To move CI to a newer CLI, upload a new release and bump `CLI_VERSION`.
