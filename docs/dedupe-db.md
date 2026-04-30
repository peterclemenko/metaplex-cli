# Dedupe DB (SQLite) — Usage

This document describes the dedupe database that tracks content-hash -> URI mappings used by the CLI to avoid duplicate uploads.

Commands

- `mplx db init [-d path]` — Initialize the dedupe DB (default: `~/.config/mplx/upload-dedupe.db`).
- `mplx db status [-d path]` — Show DB path and counts of uploads and assets.
- `mplx db export -o file.json [-d path]` — Export DB contents to a JSON file (safe to commit to git).
- `mplx db import -i file.json [-d path]` — Import previously exported DB contents.
- `mplx db reset [-y] [-d path]` — Clear DB contents (destructive).

Notes

- The DB is implemented with SQLite (`better-sqlite3`) and a small Drizzle schema. It contains two tables: `uploads` (hash -> uri) and `assets` (asset-level mapping).
- Exported JSON files are safe to sync via git. Use `mplx db export -o upload-dedupe.json` to create a portable snapshot.
- Import will `INSERT OR REPLACE` rows, allowing merging snapshots from other machines.

Next steps

- The CLI will integrate DB lookups into the upload flow to skip uploads when a matching hash is found.
- You can control the DB path via `-d` flags or configure a default in the global config in future iterations.
