# justfile

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
