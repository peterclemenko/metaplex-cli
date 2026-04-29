set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

CODEQL_DIR := "tools/codeql"
CODEQL_ZIP := "codeql.zip"
CODEQL_URL := "https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip"

help:
    @echo "Targets:"
    @echo "  download-codeql   - Ensure CodeQL CLI is available (uses system CodeQL if on PATH)"
    @echo "  codeql-create-db         - Create a CodeQL DB named 'codeql-db' (default build: pnpm install && pnpm run build). Use OVERWRITE=true to replace an existing DB."
    @echo "  codeql-analyze           - Analyze 'codeql-db' with the JavaScript query pack and write results.sarif"
    @echo "  codeql-clean-db          - Remove codeql-db, results.sarif and the downloaded CodeQL CLI"
    @echo "  codeql-status            - Show CodeQL binary and DB info (if present)"
    @echo "  codeql-run               - download-codeql, create-db, then analyze"
    @echo "  gitnexus-analyze           - Analyze with gitnexus"
    @echo "  pnpm-test           - unit tests with pnpm"
    @echo "  act           - unit tests with pnpm"
    @echo "  act-run           - unit tests with pnpm"
    @echo "  test-mocha           - test with mocha"
    @echo "  npm-publish-dry-run           - npm-publish-dry-run"
    @echo "  run           - combines download-codeql codeql-create-db codeql-analyze gitnexus-analyze"


download-codeql:
    @echo "Ensuring CodeQL CLI is available (skips download if present)..."
    if command -v codeql >/dev/null 2>&1; then \
        echo "Found system CodeQL on PATH, skipping download."; \
        mkdir -p {{CODEQL_DIR}}; \
        ln -sf "$(command -v codeql)" {{CODEQL_DIR}}/codeql || true; \
    else \
        if [ -x {{CODEQL_DIR}}/codeql ]; then \
            echo "Found {{CODEQL_DIR}}/codeql, skipping download."; \
        else \
            mkdir -p {{CODEQL_DIR}}; \
            echo "Downloading CodeQL CLI into {{CODEQL_DIR}}..."; \
            curl -L -o {{CODEQL_ZIP}} "{{CODEQL_URL}}"; \
            tmpdir=$(mktemp -d) && unzip -q {{CODEQL_ZIP}} -d "$tmpdir" && mv "$tmpdir"/* {{CODEQL_DIR}}/ && rm -rf "$tmpdir" {{CODEQL_ZIP}}; \
            CODEQL_BIN=$(find {{CODEQL_DIR}} -maxdepth 4 -type f -name codeql | head -n1 || true); \
            if [ -z "$CODEQL_BIN" ]; then echo "CodeQL binary not found after unzip"; exit 2; fi; \
            ln -sf "$CODEQL_BIN" {{CODEQL_DIR}}/codeql; \
            chmod +x {{CODEQL_DIR}}/codeql; \
        fi; \
    fi; \
    echo "CodeQL available at: $(if command -v {{CODEQL_DIR}}/codeql >/dev/null 2>&1; then {{CODEQL_DIR}}/codeql --version 2>/dev/null || true; else command -v codeql || echo 'unknown'; fi)"

codeql-create-db:
    @echo "Creating CodeQL DB 'codeql-db' (use BUILD_CMD and OVERWRITE env vars to override)"
    BUILD_CMD="${BUILD_CMD:-pnpm install && pnpm run build}"; \
    OVERWRITE="${OVERWRITE:-false}"; \
    CODEQL_BIN="{{CODEQL_DIR}}/codeql"; \
    if [ -x "$CODEQL_BIN" ]; then \
        CMD="$CODEQL_BIN"; \
    elif command -v codeql >/dev/null 2>&1; then \
        CMD="$(command -v codeql)"; \
    else \
        echo "No codeql binary found; run 'just download-codeql' or ensure CodeQL is on PATH"; exit 2; \
    fi; \
    OVERWRITE_FLAG=""; \
    if [ -d codeql-db ]; then \
        if [ "$OVERWRITE" = "true" ]; then \
            echo "Overwriting existing codeql-db (OVERWRITE=true)."; \
            OVERWRITE_FLAG="--overwrite"; \
        else \
            echo "Found existing 'codeql-db' — skipping create (set OVERWRITE=true to recreate)."; \
            exit 0; \
        fi; \
    fi; \
    "$CMD" database create codeql-db --language=javascript --command "$BUILD_CMD" $OVERWRITE_FLAG

codeql-analyze:
    @echo "Analyzing 'codeql-db' (use PACK and OUT env vars to override)"
    PACK="${PACK:-codeql/javascript-queries@latest}"; \
    OUT="${OUT:-results.sarif}"; \
    CODEQL_BIN="{{CODEQL_DIR}}/codeql"; \
    if [ -x "$CODEQL_BIN" ]; then \
        CMD="$CODEQL_BIN"; \
    elif command -v codeql >/dev/null 2>&1; then \
        CMD="$(command -v codeql)"; \
    else \
        echo "No codeql binary found; run 'just download-codeql' or ensure CodeQL is on PATH"; exit 2; \
    fi; \
    "$CMD" database analyze codeql-db "$PACK" --format=sarif-latest --output="$OUT" --threads 0

# Unit test helpers
pnpm-test:
    @echo "Running unit tests (uses pnpm if available, falls back to npm)"
    if command -v pnpm >/dev/null 2>&1; then \
        pnpm test; \
    elif command -v npm >/dev/null 2>&1; then \
        npm test; \
    else \
        echo "Install pnpm or npm to run tests"; exit 2; \
    fi

test-mocha:
    @echo "Running Mocha tests (pnpm/npm fallback)"
    if command -v pnpm >/dev/null 2>&1; then \
        pnpm run test:mocha; \
    elif command -v npm >/dev/null 2>&1; then \
        npm run test:mocha; \
    else \
        echo "Install pnpm or npm to run mocha tests"; exit 2; \
    fi

# GitHub Actions helpers using `act`
act:
    @echo "Running GitHub Actions locally with act (requires act + Docker)"
    if command -v act >/dev/null 2>&1; then \
        WORKFLOW="${WORKFLOW:-.github/workflows/ci.yml}"; \
        JOB="${JOB:-}"; \
        EVENT_FILE="${EVENT_FILE:-}"; \
        CMD=(act -W "$WORKFLOW"); \
        if [ -n "$JOB" ]; then CMD+=( -j "$JOB" ); fi; \
        if [ -n "$EVENT_FILE" ]; then CMD+=( -e "$EVENT_FILE" ); fi; \
        echo "Running: ${CMD[*]}"; \
        "${CMD[@]}"; \
    else \
        echo "Install 'act' (https://github.com/nektos/act) or enable it in your devshell"; exit 2; \
    fi

act-run:
    @echo "Convenience target: runs download-codeql, create-db, analyze, then runs act (if present)"
    just download-codeql; \
    just create-db; \
    just analyze; \
    just act

codeql-clean-db:
    @echo "Removing codeql-db, results and downloaded CodeQL"
    rm -rf codeql-db results.sarif {{CODEQL_DIR}}

gitnexus-analyze:
    @echo "analyzing with gitnexus"
    npx gitnexus analyze

codeql-status:
    @echo "CodeQL binary (if installed):"
    ls -l {{CODEQL_DIR}}/codeql || true
    if [ -d codeql-db ]; then {{CODEQL_DIR}}/codeql database info codeql-db || true; else echo "No codeql-db present"; fi

npm-publish-dry-run:
    @echo "Publishing to npm (dry-run) — updating version if needed"
    @set +e; npm version 0.2.0 --no-git-tag-version 2> /tmp/just-npm-version.err; RC=$?; set -e; \
    if [ $RC -eq 0 ]; then \
        echo "Version updated"; \
    else \
        if grep -q "Version not changed" /tmp/just-npm-version.err 2>/dev/null; then \
            echo "Version unchanged; continuing"; \
        else \
            echo "npm version failed:"; cat /tmp/just-npm-version.err; exit $RC; \
        fi; \
    fi; \
    npm publish --dry-run

dependabot-update:
    @echo "running dependabot update (local CLI)"
    # Use explicit package manager + repo to avoid CLI 'unknown package manager' error
    PM="${PM:-npm_and_yarn}"; REPO="${REPO:-peterclemenko/ghost-datatype-support-lib}"; \
    echo "Running: dependabot update $PM $REPO"; \
    dependabot update "$PM" "$REPO"

run:
    just download-codeql
    just codeql-create-db
    just codeql-analyze
    just gitnexus-analyze
