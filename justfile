set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

import "just/codeql.just"
import "just/solana.just"
import "just/github-act.just"

help:
    @echo "Targets:"
    @echo "  download-codeql   - Ensure CodeQL CLI is available (uses system CodeQL if on PATH)"
    @echo "  codeql-create-db         - Create a CodeQL DB named 'codeql-db' (default build: pnpm install && pnpm run build). Use OVERWRITE=true to replace an existing DB."
    @echo "  codeql-analyze           - Analyze 'codeql-db' with the JavaScript query pack and write results.sarif"
    @echo "  codeql-clean-db          - Remove codeql-db, results.sarif and the downloaded CodeQL CLI"
    @echo "  codeql-status            - Show CodeQL binary and DB info (if present)"
    @echo "  codeql-run               - download-codeql, create-db, then analyze"
    @echo "  gitnexus-analyze           - Analyze with gitnexus"
    @echo "  gitnexus-wiki           - make wiki with gitnexus"
    @echo "  pnpm-test           - unit tests with pnpm"
    @echo "  act           - unit tests with pnpm"
    @echo "  act-run           - unit tests with pnpm"
    @echo "  test-mocha           - test with mocha"
    @echo "  setup-solana-for-local-validator           - setup solana for local validator"
    @echo "  run-solana-local-validator           - run solana local validator"
    @echo "  npm-publish-dry-run           - npm-publish-dry-run"
    @echo "  run           - combines download-codeql codeql-create-db codeql-analyze gitnexus-analyze"


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

gitnexus-analyze:
    @echo "analyzing with gitnexus"
    npx gitnexus analyze

gitnexus-wiki:
    @echo "analyzing with gitnexus"
    npx gitnexus wiki


gitnexus-serve:
    @echo "serve gitnexus, gui at https://gitnexus.vercel.app/ "
    @if ss -ltnp 2>/dev/null | grep -q ':4747' || lsof -i :4747 >/dev/null 2>&1; then \
        echo "Port 4747 already in use; skipping gitnexus serve."; \
    else \
        npx gitnexus@latest serve; \
    fi



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
    just gitnexus-analyze
    just gitnexus-serve
