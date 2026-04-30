# justfile


# Unit test helpers
pnpm-test:
    @echo "Running unit tests (uses pnpm if available, falls back to npm)"
    
    just gitnexus-analyze
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
