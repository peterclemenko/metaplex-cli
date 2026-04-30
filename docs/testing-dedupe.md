# Testing — Dedupe DB & CLI

**Overview**

This document explains the testing flow for the dedupe database and the new `db` CLI commands. Tests cover:

- Unit tests for the DB utility: [test/lib/dedupeDb.test.ts](test/lib/dedupeDb.test.ts#L1-L200)
- Command-level tests for the `db` namespace: [test/commands/db/db.test.ts](test/commands/db/db.test.ts#L1-L50)

**Prerequisites**

- Node.js >= 20 (project requirement)
- `pnpm` (preferred) or `npm`
- Native build tooling for `better-sqlite3` (C++ build tools available on CI/machine)

**Run the full test suite**

Run the project's test script which executes Mocha over TypeScript test files:

```bash
pnpm install
pnpm test
```

**Run only the dedupe DB tests**

Run a single test file to iterate quickly while developing:

```bash
npx mocha test/lib/dedupeDb.test.ts
```

Or use the test runner helper used by other tests (when available in your environment):

```bash
npx mocha "test/lib/dedupeDb.test.ts"
```

**Run command tests (oclif)**

Command tests use `@oclif/test` helpers invoked by the same `pnpm test` script. To run only the `db` command tests:

```bash
npx mocha test/commands/db/db.test.ts
```

**What the tests do**

- `test/lib/dedupeDb.test.ts`:
  - Initializes a temporary SQLite DB in the OS temp directory using `dedupeDb.initDedupeDb()`.
  - Verifies `dbStatus()` reports zero rows initially.
  - Inserts an `uploads` row and verifies lookup via `lookupByHash()`.
  - Upserts an `assets` row and verifies retrieval via `getAsset()`.
  - Exports DB to JSON, resets the DB, imports the JSON back, and verifies counts match.
  - Cleans up temporary files in the `after` hook.

- `test/commands/db/db.test.ts`:
  - Ensures `mplx db` prints the CLI help/commands list.
  - Ensures `mplx db --help` shows the `db` command description.

**Tips for debugging failing tests**

- If `better-sqlite3` fails to install or load, ensure your system has a working C++ toolchain and that `node-gyp` can build native modules. On Linux this typically requires `build-essential` and Python 3.
- You can reproduce environment differences by running tests inside a clean Docker container with Node.js 20.
- For flaky tests that touch the file system, inspect the temp files created in your OS temp directory (printed paths in test code) and ensure no stale locks exist.

**CI considerations**

- CI must run `pnpm install` to build native modules before running `pnpm test`.
- Add caching for `node_modules` and, if possible, reuse compiled native artifacts between runs to speed up builds.

**Next steps (integration)**

- After wiring the dedupe lookups into `uploadFiles()` and `uploadCandyMachineItems()`, add integration tests that mock provider uploads and assert that DB hits skip provider calls. These tests should run deterministically and avoid real network uploads.

**References**

- DB utility: [src/lib/uploader/dedupeDb.ts](src/lib/uploader/dedupeDb.ts#L1-L999)
- DB commands: [src/commands/db](src/commands/db/index.ts#L1-L50)
- Tests: [test/lib/dedupeDb.test.ts](test/lib/dedupeDb.test.ts#L1-L200), [test/commands/db/db.test.ts](test/commands/db/db.test.ts#L1-L50)
