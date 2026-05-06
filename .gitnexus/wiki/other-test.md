# Other — test

# Test Utilities Module

This module (`test/`) provides shared utilities for integration testing the CLI application. It contains helpers for spawning CLI processes, simulating user input, and generating blockchain explorer links.

## Overview

The test utilities serve three main purposes:

1. **Process Execution** — Spawn the CLI as a child process with configurable arguments
2. **Input Simulation** — Simulate keyboard interactions for interactive CLI tests
3. **Result Validation** — Parse CLI output and generate explorer links for transaction verification

## Constants

### `CLI_PATH`

```typescript
export const CLI_PATH = join(process.cwd(), 'bin', 'run.js')
```

Path to the CLI entry point. Assumes the CLI has been built to `bin/run.js` in the project root.

### `TEST_RPC`

```typescript
export const TEST_RPC = 'http://127.0.0.1:8899'
```

RPC endpoint for test transactions. Points to a local Solana test validator running on port 8899.

### `KEYPAIR_PATH`

```typescript
export const KEYPAIR_PATH = join(process.cwd(), 'test-files', 'key.json')
```

Path to the test wallet keypair JSON file used for signing transactions.

## runCli Function

```typescript
export const runCli = (args: string[], stdin?: string[]): Promise<{ stdout: string; stderr: string; code: number }>
```

Spawns the CLI as a child process with the specified arguments and optional stdin input.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `args` | `string[]` | Command-line arguments to pass to the CLI |
| `stdin` | `string[]` (optional) | Array of strings to write to stdin, one per `write()` call |

### Returns

A promise that resolves with an object containing:
- `stdout`: Complete stdout output from the process
- `stderr`: Complete stderr output from the process
- `code`: Exit code (always `0` on success, rejected promise on failure)

### Behavior

- Automatically appends `-r TEST_RPC` and `-k KEYPAIR_PATH` to all commands
- Rejects the promise if the process exits with a non-zero code, including stdout/stderr in the error message
- If `stdin` is provided, writes each string to stdin sequentially, then closes the stream

### Example Usage

```typescript
// Simple command
const result = await runCli(['balance', 'my-address'])

// Command requiring stdin input (e.g., confirmation prompts)
await runCli(['transfer', 'recipient-address', '1'], ['y\n'])

// Access output
try {
    const { stdout, stderr } = await runCli(['some-command'])
    expect(stdout).toContain('expected output')
} catch (err) {
    // Handle CLI failure
}
```

## IO Utilities

Keyboard input simulation for testing interactive CLI prompts:

```typescript
export const io = {
    up: '\x1B\x5B\x41',      // Arrow Up
    down: '\x1B\x5B\x42',    // Arrow Down
    enter: '\x0D',          // Enter/Return
    space: '\x20'           // Spacebar
}
```

These are raw ANSI escape sequences. Use them when testing CLI menus or prompts that require keyboard navigation:

```typescript
await runCli(['interactive-command'], [io.down, io.enter])
```

## Explorer Link Helpers

Generate direct links to view transactions and accounts on blockchain explorers.

### LinkType Enum

```typescript
export enum LinkType {
    Transaction = 'transaction',
    Account = 'account'
}
```

### explorerLink Function

```typescript
export const explorerLink = (explorerPlatform: Explorer, type: LinkType, id: string): string
```

Generates a URL for viewing a transaction or account on a supported explorer.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `explorerPlatform` | `Explorer` | Which explorer to use: `'solanaExplorer'`, `'solscan'`, `'solanaFm'`, or `'core'` |
| `type` | `LinkType` | Either `LinkType.Transaction` or `LinkType.Account` |
| `id` | `string` | The transaction signature or account address |

#### Returns

A fully-formed URL string.

#### Example

```typescript
import { explorerLink, LinkType } from './utils'

// Generate transaction link
const txLink = explorerLink('solscan', LinkType.Transaction, 'abc123...')
// Returns: 'https://solscan.io/tx/abc123...'

// Generate account link
const accountLink = explorerLink('core', LinkType.Account, 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA')
// Returns: 'https://core.app/address/TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'
```

## extractAssetId Function

```typescript
export const extractAssetId = (str: string): string | null
```

Parses CLI output to extract an asset ID from strings formatted as `Asset: <id>`.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `str` | `string` | String to parse |

#### Returns

The extracted asset ID, or `null` if not found.

#### Example

```typescript
const output = 'Minted new token!\nAsset: MyToken123'
const assetId = extractAssetId(output)
// Returns: 'MyToken123'
```

## Integration Notes

### Test Setup Requirements

Before running tests that use these utilities:

1. **Build the CLI** — Ensure `bin/run.js` exists (run `npm run build` or equivalent)
2. **Start local validator** — The test RPC (`127.0.0.1:8899`) must be running (e.g., `solana-test-validator`)
3. **Provide test keypair** — Place a funded keypair JSON at `test-files/key.json`

### Common Test Patterns

```typescript
import { runCli } from './runCli'
import { explorerLink, LinkType, io } from './utils'

describe('CLI integration tests', () => {
    it('executes a command and returns output', async () => {
        const { stdout } = await runCli(['some-command'])
        expect(stdout).toContain('Expected output')
    })

    it('handles interactive prompts', async () => {
        await runCli(['confirm-action'], [io.enter])
    })

    it('generates explorer links for transactions', () => {
        const link = explorerLink('solscan', LinkType.Transaction, 'sig123')
        expect(link).toBe('https://solscan.io/tx/sig123')
    })
})
```