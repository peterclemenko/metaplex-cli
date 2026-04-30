# justfile

CODEQL_DIR := "tools/codeql"
CODEQL_ZIP := "codeql.zip"
CODEQL_URL := "https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip"

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


codeql-clean-db:
    @echo "Removing codeql-db, results and downloaded CodeQL"
    rm -rf codeql-db results.sarif {{CODEQL_DIR}}


codeql-create-db:
    @echo "Creating CodeQL DB 'codeql-db' (use BUILD_CMD and OVERWRITE env vars to override)"
    BUILD_CMD="${BUILD_CMD:-sh -lc 'pnpm install && pnpm run build'}"; \
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
            if "$CMD" database info codeql-db >/dev/null 2>&1; then \
                echo "Found existing 'codeql-db' — skipping create (set OVERWRITE=true to recreate)."; \
                exit 0; \
            else \
                echo "Directory 'codeql-db' exists but is not a valid CodeQL DB; recreating."; \
                rm -rf codeql-db; \
            fi; \
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
