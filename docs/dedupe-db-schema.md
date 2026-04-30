# Dedupe DB — Schema & Logic

This document describes the SQLite schema used by the CLI dedupe layer and the application-level logic for using it to avoid duplicate uploads.

Location

- Default DB path: `~/.config/mplx/upload-dedupe.db` (configurable via `-d` flags on `mplx db` commands)

Overview

The DB contains two primary tables:

- `uploads` — maps file content hashes to provider URIs (file-level dedupe)
- `assets` — optional asset-level mapping that links an asset key to its image/json hashes and URIs

Schema

uploads

- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `hash` TEXT NOT NULL UNIQUE — canonical content hash (e.g. `sha256:<hex>`)
- `uri` TEXT NOT NULL — provider URL returned after upload (e.g. `https://arweave.net/<id>`)
- `type` TEXT NOT NULL — arbitrary type label, typically `image` or `json`
- `created_at` TEXT NOT NULL — ISO timestamp

assets

- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `asset_key` TEXT NOT NULL UNIQUE — app-defined key for the asset (see Asset Key below)
- `image_hash` TEXT | NULL — recorded image content hash
- `json_hash` TEXT | NULL — recorded metadata JSON content hash
- `image_uri` TEXT | NULL — recorded image URI
- `json_uri` TEXT | NULL — recorded JSON URI
- `created_at` TEXT NOT NULL — ISO timestamp when the asset row was created

Asset Key

The `asset_key` is a unique identifier chosen by the application to represent a logical asset. Implementations commonly use one of:

- the relative filename (e.g. `assets/0001.png`)
- an index string (e.g. `0001` or `1`)
- `collectionName/0001` for multi-collection workflows

Choose a key that is stable across runs so imports/merges behave predictably.

Hashing Strategy

- Use a stable, content-based hash (SHA-256) and store it as a prefixed string, e.g. `sha256:<hex>`.
- For JSON metadata, compute the hash after substituting the resolved `image_uri` (if image is deduped) so identical final metadata maps to the same hash.

Application Logic (recommended hybrid flow)

1. Image phase (file-level dedupe)
   - Compute image hash (SHA-256).
   - Query `uploads` by `hash`. If found, reuse `uri` and skip provider upload.
   - If not found, upload the image via the configured provider, then insert into `uploads` with `type='image'`.
   - Upsert the `assets` row: set `image_hash` and `image_uri`.

2. JSON/metadata phase (asset-level dedupe)
   - Substitute the resolved `image_uri` into the JSON metadata locally.
   - Compute the JSON hash (SHA-256) of the resulting JSON string.
   - Query `uploads` by JSON hash; if found, reuse `json_uri` and skip provider upload.
   - If not found, upload JSON and insert into `uploads` with `type='json'`.
   - Upsert the `assets` row: set `json_hash` and `json_uri`.

3. Write-through and idempotency
   - All successful provider uploads should be written to `uploads` immediately (write-through).
   - When importing snapshots (`mplx db import`) we use `INSERT OR REPLACE` semantics so merges override rows with the imported data.

Import / Export

- `mplx db export -o file.json` writes a JSON snapshot containing both `uploads` and `assets` rows. The snapshot is safe to commit to git and share between machines.
- `mplx db import -i file.json` reads the snapshot and `INSERT OR REPLACE`-es rows into the local DB, allowing easy sync/merge.

Conflict resolution & merging

- Imports use `INSERT OR REPLACE`, which replaces rows with matching unique keys (`hash` for `uploads`, `asset_key` for `assets`).
- If two machines independently uploaded the same content but with different URIs, importing one snapshot into the other overwrites the row with the imported values.
- Consider keeping export files in a branch or PR workflow to review changes before merging into a shared repo.

Concurrency & multi-machine considerations

- SQLite is a local, single-file DB. `better-sqlite3` is synchronous and supports transactions, but it is not a replacement for a distributed DB.
- For multi-machine workflows, prefer export/import via git (the `mplx db export/import` commands) or use a shared networked DB service.
- When multiple processes may access the same DB file on a shared filesystem, ensure the FS supports file locking; otherwise prefer export/import.

Provider lookup fallback

- When the DB does not contain a hash, optionally query the storage provider for existing content (if provider API supports lookup by hash) before uploading. This reduces false negatives when other machines uploaded directly to the provider.

Transactions and atomicity

- Wrap multi-step operations (upload -> insert upload -> upsert asset) in a DB transaction when possible to avoid partial state on failures.
- The current utility exposes atomic import transaction blocks for import operations; callers should use transactions for multi-row updates.

Example queries

- Look up an upload by hash:

  SELECT * FROM uploads WHERE hash = ?;

- Get an asset's URIs by key:

  SELECT image_uri, json_uri FROM assets WHERE asset_key = ?;

Notes for integrators

- Use the `src/lib/uploader/dedupeDb.ts` API (`initDedupeDb`, `lookupByHash`, `insertUpload`, `upsertAsset`, `exportDbToFile`, `importDbFromFile`, `resetDb`, `dbStatus`).
- Default DB path is created on first `initDedupeDb()` call; callers can pass a custom path to the init function and CLI flags.
- Keep JSON hashing deterministic: canonicalize JSON (consistent key ordering) before hashing to avoid false mismatches.

Security & privacy

- The exported JSON snapshot contains only content hashes, URIs and timestamps — no private keys, secrets or wallet information.
- Treat export files as sensitive if your URIs reveal project details; store them in private repos when necessary.

Roadmap ideas

- Add a provider indexer that queries configured providers for known hashes and syncs them into the local DB (background job).
- Add an opt-in global config setting to enable/disable DB lookups by default.
