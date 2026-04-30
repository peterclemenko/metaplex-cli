# justfile

dependabot-update:
    @echo "running dependabot update (local CLI)"
    # Use explicit package manager + repo to avoid CLI 'unknown package manager' error
    PM="${PM:-npm_and_yarn}"; REPO="${REPO:-peterclemenko/ghost-datatype-support-lib}"; \
    echo "Running: dependabot update $PM $REPO"; \
    dependabot update "$PM" "$REPO"
