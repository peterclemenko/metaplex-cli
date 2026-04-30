set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

import "just/codeql.just"
import "just/solana.just"
import "just/github-act.just"
import "just/dependabot.just"
import "just/gitnexus.just"
import "just/pnpm.just"
import "just/uncategorized.just"

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
    @echo "  solana-airdrop           - run airdrop 5 sol"
    @echo "  npm-publish-dry-run           - npm-publish-dry-run"
    @echo "  run           - combines download-codeql codeql-create-db codeql-analyze gitnexus-analyze"



run:
    just gitnexus-analyze
    just gitnexus-wiki
    just gitnexus-serve
    just run-solana-local-validator  
