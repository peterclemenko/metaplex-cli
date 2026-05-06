# Other — justfile

# Justfile — Development Task Automation

This justfile provides a collection of `just` recipe targets for automating common development tasks in the project. It encapsulates CodeQL security analysis, testing workflows, npm publishing, and local GitHub Actions execution.

## Prerequisites

- **just** — The command runner (`brew install just` or `cargo install just`)
- **bash** — All recipes execute via bash with strict error handling (`-eu -o pipefail`)
- **pnpm** — Preferred package manager (falls back to npm when unavailable)

Run `just` with no arguments to see available targets, or `just help` for the same output.

---

## CodeQL Analysis

The justfile automates the complete CodeQL security scanning workflow: downloading the CodeQL CLI, creating a database from your codebase, and running security queries.

### Target Overview

| Target | Purpose |
|--------|---------|
| `download-codeql` | Download CodeQL CLI or use system version on PATH |
| `codeql-create-db` | Create a CodeQL database from source |
| `codeql-analyze` | Run security queries against the database |
| `codeql-run` | Convenience target: download → create-db → analyze |
| `codeql-clean-db` | Remove all CodeQL artifacts |
| `codeql-status` | Show installed CodeQL version and database info |

### Download CodeQL

```bash
just download-codeql
```

This target checks for CodeQL in two places:

1. **System PATH** — If `codeql` is on PATH, it creates a symlink in `tools/codeql/` pointing to the system binary
2. **Local download** — If not found on PATH, downloads the latest Linux64 release from GitHub, extracts it to `tools/codeql/`, and creates a `codeql` symlink

The downloaded CLI lives in `tools/codeql/codeql`.

### Create Database

```bash
just codeql-create-db
```

Creates a CodeQL database named `codeql-db` by running a build command against the JavaScript/TypeScript source. By default:

- **Build command:** `pnpm install && pnpm run build`
- **Language:** JavaScript
- **Output:** `codeql-db/`

**Environment variables:**

- `BUILD_CMD` — Override the build command (e.g., `BUILD_CMD="npm run build" just codeql-create-db`)
- `OVERWRITE=true` — Replace an existing database instead of skipping

```bash
# Recreate the database from scratch
OVERWRITE=true just codeql-create-db

# Custom build command
BUILD_CMD="npm install && npm run build:prod" just codeql-create-db
```

The target detects whether `codeql-db` exists and is a valid database. If the directory exists but isn't a valid CodeQL database, it removes it and recreates.

### Run Analysis

```bash
just codeql-analyze
```

Analyzes the `codeql-db` database using the JavaScript query pack and writes results to SARIF format.

**Environment variables:**

- `PACK` — Query pack to use (default: `codeql/javascript-queries@latest`)
- `OUT` — Output file (default: `results.sarif`)

```bash
# Custom output location
OUT=security-results.sarif just codeql-analyze
```

### Full Workflow

```bash
# Run the complete CodeQL pipeline
just codeql-run

# Or step by step
just download-codeql
just codeql-create-db
just codeql-analyze
```

### Cleanup

```bash
just codeql-clean-db
```

Removes:
- `codeql-db/` — The database directory
- `results.sarif` — Analysis output
- `tools/codeql/` — Downloaded CLI (but not a system-installed symlink)

---

## Testing

### Run Unit Tests

```bash
just pnpm-test
```

Runs the project's test suite. Uses pnpm if available, falls back to npm.

```bash
just test-mocha
```

Runs Mocha-specific tests via `pnpm run test:mocha` (or npm fallback).

---

## Local GitHub Actions

### Run with `act`

```bash
just act
```

Executes GitHub Actions workflows locally using [act](https://github.com/nektos/act). Requires Docker and the `act` binary to be installed.

**Environment variables:**

- `WORKFLOW` — Path to workflow file (default: `.github/workflows/ci.yml`)
- `JOB` — Specific job to run (optional)
- `EVENT_FILE` — Path to event payload file (optional)

```bash
# Run a specific job
JOB=test just act

# Use a custom workflow
WORKFLOW=.github/workflows/security.yml just act
```

### Full Analysis + Act

```bash
just act-run
```

Convenience target that runs:
1. `download-codeql`
2. `codeql-create-db`
3. `codeql-analyze`
4. `act`

---

## gitnexus Analysis

```bash
just gitnexus-analyze
```

Runs the gitnexus analyzer via `npx gitnexus analyze`.

### Serve gitnexus GUI

```bash
just gitnexus-serve
```

Starts the gitnexus development server. The GUI runs at `https://gitnexus.vercel.app/`.

The target checks if port 4747 is already in use before starting the server.

### Run Everything

```bash
just run
```

Runs `gitnexus-analyze` followed by `gitnexus-serve`.

---

## npm Publishing

### Dry-Run Publish

```bash
just npm-publish-dry-run
```

Performs a dry-run of npm publishing:
1. Updates the package version to `0.2.0` (if not already at that version)
2. Runs `npm publish --dry-run`

This target handles the `npm version` command gracefully — if the version is already set, it continues without error.

---

## Dependabot

```bash
just dependabot-update
```

Runs the Dependabot CLI to check for dependency updates.

**Environment variables:**

- `PM` — Package manager (default: `npm_and_yarn`)
- `REPO` — Repository in format `owner/repo` (default: `peterclemenko/ghost-datatype-support-lib`)

```bash
# Check for Go updates
PM=go just dependabot-update
```

---

## Environment Variables Summary

| Variable | Target(s) | Description |
|----------|----------|-------------|
| `BUILD_CMD` | `codeql-create-db` | Build command for database creation |
| `OVERWRITE` | `codeql-create-db` | Set to `true` to replace existing database |
| `PACK` | `codeql-analyze` | CodeQL query pack |
| `OUT` | `codeql-analyze` | SARIF output filename |
| `WORKFLOW` | `act` | Path to workflow file |
| `JOB` | `act` | Specific job to run |
| `EVENT_FILE` | `act` | Event payload file |
| `PM` | `dependabot-update` | Package manager |
| `REPO` | `dependabot-update` | Repository for dependabot |

---

## Error Handling

All recipes use bash with strict error handling:

```bash
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
```

- `-e` — Exit immediately on command failure
- `-u` — Treat unset variables as errors
- `-o pipefail` — Pipeline fails if any command fails (not just the last)

This ensures failures are caught early and scripts don't continue with invalid state.