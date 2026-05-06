# Other — src

# `src/` Module

This module provides foundational configuration constants for Solana blockchain interactions and sets up the CLI entry point using OCLIF.

## Overview

```
src/
├── constants.ts    # Solana blockchain constants
└── index.ts        # CLI entry point
```

The module serves two purposes:
1. **Configuration** — Defines chain identifiers and program addresses used throughout the codebase
2. **CLI bootstrap** — Exports the OCLIF `run` function to handle command-line invocation

## Constants

### `MAINNET_GENESIS_HASH`

```typescript
export const MAINNET_GENESIS_HASH = "GH7ome3EiwEr7tu9JuTh2dpYWBJK3z69Xm1ZE3MEE6JC"
```

The genesis block hash for Solana mainnet-beta. This identifies the initial block of the Solana blockchain and is used for network validation and chain identification.

**Usage context:** Typically used when verifying network connectivity or validating that the client is connected to the expected Solana cluster.

### `TOKEN_AUTH_RULES_ID`

```typescript
export const TOKEN_AUTH_RULES_ID = publicKey('auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg')
```

The public key (program ID) for Solana's **Token Auth Rules Program**. This program handles authorization rules for programmable NFTs (pNFTs).

**Purpose:** The Token Auth Rules Program enables creators to define custom authorization conditions for NFT transfers, such as:
- Time-based unlock schedules
- Holder requirements
- Custom permission logic

**Usage context:** When working with pNFTs that have authorization rulesets, this program ID is used to validate that operations comply with the defined rules.

## CLI Entry Point

### `index.ts`

```typescript
export {run} from '@oclif/core'
```

Re-exports the `run` function from `@oclif/core`, which serves as the CLI bootstrap mechanism. When the CLI tool is invoked, OCLIF's `run` function:

1. Parses command-line arguments
2. Routes to the appropriate command handler
3. Executes the command and returns the result

This is the standard OCLIF pattern for building command-line interfaces in TypeScript/JavaScript.

## Integration

This module connects to the broader codebase as follows:

```mermaid
graph LR
    A[CLI invocation] --> B[src/index.ts - run()]
    B --> C[Command handlers]
    C --> D[src/constants.ts]
    D --> E[Solana programs]
    
    D --> F[Token Auth Rules Program]
    D --> G[Network validation]
```

- **`constants.ts`** exports values used by command implementations that interact with Solana
- **`index.ts`** is the entry point that OCLIF invokes when the CLI runs

## Dependencies

| Package | Purpose |
|---------|---------|
| `@metaplex-foundation/umi` | Provides `publicKey` helper for parsing Solana addresses |
| `@oclif/core` | CLI framework providing the `run` function |