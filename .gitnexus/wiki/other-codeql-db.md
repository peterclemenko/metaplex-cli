# Other — codeql-db

# CodeQL Database — codeql-db

## Overview

This module is a **CodeQL static analysis database** for the Metaplex CLI project. CodeQL databases store extracted semantic information about codebases, enabling security researchers and developers to run queries against the code to find bugs, vulnerabilities, and code quality issues.

## Database Metadata

| Property | Value |
|----------|-------|
| **Primary Language** | JavaScript/TypeScript |
| **Lines of Code** | 27,619 |
| **CodeQL Version** | 2.25.2 |
| **Creation Date** | 2026-04-30 |
| **Source Location** | `/home/aoi/dev/metaplex-cli` |
| **Status** | In Progress (not finalised) |

## Supported Languages

The database has extractors installed for the following languages:

- **JavaScript/TypeScript** (primary)
- YAML
- HTML
- Ruby
- GitHub Actions
- Go
- C/C++
- C#
- Properties
- Swift
- XML
- CSV
- Java
- Rust
- Python

## Analyzed Project: Metaplex CLI

This CodeQL database analyzes the **Metaplex CLI** — a command-line interface for interacting with the Metaplex protocol on Solana. The codebase is built with OCLIF (the Open CLI Framework) and provides commands for managing:

### Command Categories

| Category | Description |
|----------|-------------|
| **bg** | Bubblegum (compressed NFTs) operations — create collections, mint NFTs, transfer, burn, update |
| **cm** | Candy Machine operations — create, upload, validate, insert, guard management |
| **core** | Core NFT operations — create assets, collections, transfer, burn, plugins |
| **genesis** | Genesis NFT launch operations — presale, launch pools, bucket management, claiming |
| **tm** | Token Metadata operations |
| **toolbox** | Utility commands — SOL transfers, wrapping/unwrapping, token operations, storage, LUT management |
| **distro** | Token distribution operations |
| **agents** | Agent management — registration, delegation, token setting |
| **config** | CLI configuration — RPCs, wallets, storage providers, explorers |

### Library Modules

The codebase includes shared libraries for:

- **Uploader** — Storage provider integration (Irys, Cascade, Turbo)
- **UMI** — Transaction sending and confirmation utilities
- **Candy Machine** — CM-specific utilities, validation, guard parsing
- **Core** — Asset creation, updates, burning, fetching
- **Genesis** — Launch API, wizard prompts, operations
- **Metadata** — JSON metadata handling
- **Signers** — FileSigner, LedgerSigner implementations

## Usage

This CodeQL database can be used to:

1. **Run security queries** — Identify common vulnerabilities (SQL injection, path traversal, insecure crypto)
2. **Find code quality issues** — Detect dead code, performance anti-patterns, best practice violations
3. **Perform taint analysis** — Track data flow from user input to sensitive operations
4. **Generate reports** — Create summaries of code health and security posture

### Example Query Execution

```bash
# Run a built-in query suite
codeql database analyze codeql-db --format=sarif-latest -o results.sarif

# Run custom queries
codeql database analyze codeql-db /path/to/custom-queries --output results
```

## Database Structure

The database contains:

- **AST extraction** — Abstract syntax trees for all source files
- **Type information** — TypeScript type relationships
- **Control flow graphs** — Execution flow within functions
- **Data flow graphs** — How data propagates through the codebase
- **Call graph** — Function and method invocation relationships

> **Note:** The current call graph shows no detected execution flows, which may indicate the database extraction is incomplete or the queries haven't been run yet.

## Integration Notes

This CodeQL database is a standalone analysis artifact. It does not:

- Execute at runtime
- Import into the main application
- Have outgoing or incoming code dependencies

It serves as a read-only analysis target for CodeQL tooling.