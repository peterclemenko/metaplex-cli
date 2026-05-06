# Base Command Classes

# Base Command Classes

This module provides the foundational command classes for the MPLX CLI toolkit. It defines two abstract base classes that all CLI commands extend: `BaseCommand` for general commands and `TransactionCommand` for commands that interact with the blockchain.

## Overview

The CLI uses [OCLIF](https://github.com/oclif/core) (Open CLI Framework) for command infrastructure. Rather than having each command redefine common flags and initialization logic, these base classes encapsulate:

- **Global flags** (config file, keypair, RPC URL, log level, payer)
- **Context initialization** (creating a shared context object with connection settings)
- **JSON output support** (via `--json` flag)
- **Standardized logging** (including success messages with colored output)

## Class Hierarchy

```
Command (OCLIF)
    │
    └── BaseCommand
            │
            └── TransactionCommand
```

`BaseCommand` provides the minimal foundation for all commands. `TransactionCommand` extends it with blockchain-specific features like commitment level configuration.

---

## BaseCommand

The abstract base class for all CLI commands.

### Static Properties

```typescript
static baseFlags = {
  config: Flags.file({
    char: 'c',
    description: 'Path to config file. Default is ~/.config/mplx/config.json',
    helpGroup: 'GLOBAL',
  }),
  keypair: Flags.string({
    char: 'k',
    summary: 'Path to keypair file (/path/keypair.json) or ledger (e.g. usb://ledger?key=0)',
    helpGroup: 'GLOBAL',
  }),
  'log-level': Flags.option({
    default: 'info',
    helpGroup: 'GLOBAL',
    options: ['debug', 'warn', 'error', 'info', 'trace'] as const,
    summary: 'Specify level for logging.',
  })(),
  payer: Flags.string({
    char: 'p',
    summary: 'Path to keypair file (/path/keypair.json) or ledger (e.g. usb://ledger?key=0)',
    helpGroup: 'GLOBAL',
  }),
  rpc: Flags.string({
    char: 'r',
    name: 'rpc',
    summary: 'RPC URL for the cluster',
    helpGroup: 'GLOBAL',
  }),
}
```

| Flag | Short | Description |
|------|-------|--------------|
| `--config` | `-c` | Path to config file (default: `~/.config/mplx/config.json`) |
| `--keypair` | `-k` | Path to keypair file or ledger device |
| `--log-level` | — | Logging level: `debug`, `warn`, `error`, `info`, `trace` (default: `info`) |
| `--payer` | `-p` | Payer keypair path (distinct from signing keypair) |
| `--rpc` | `-r` | RPC endpoint URL |

```typescript
static enableJsonFlag = true
```

Enables the `--json` flag for structured output, allowing commands to return machine-readable JSON instead of human-formatted text.

### Instance Properties

```typescript
protected args!: Args<T>
protected flags!: Flags<T>
public context!: Context
```

- `args` — Parsed command arguments
- `flags` — Parsed command flags (including inherited base flags)
- `context` — The initialized context object containing RPC connection, commitment, keypair, and other runtime configuration

### Methods

#### `init(): Promise<void>`

Initializes the command by parsing flags/args and creating the context. Called automatically by OCLIF before `run()`.

```typescript
public async init(): Promise<void> {
  await super.init()
  const { args, flags } = await this.parse({...})
  this.flags = flags as Flags<T>
  this.args = args as Args<T>

  const configPath = this.flags.config ?? getDefaultConfigPath()
  this.context = await createContext(configPath, {
    commitment: this.flags.commitment as Commitment | undefined,
    keypair: this.flags.keypair,
    payer: this.flags.payer,
    rpcUrl: this.flags.rpc,
  })
}
```

The initialization flow:
1. Parse OCLIF arguments and flags (including base flags)
2. Determine config file path (from `--config` flag or default location)
3. Create a `Context` object with the resolved configuration

#### `logSuccess(message: string): void`

Logs a message using the standard success color (green). Used to indicate successful command completion.

```typescript
public logSuccess(message: string): void {
  this.log(StandardColors.success(message))
}
```

#### `catch(err: Error): Promise<unknown>`

Error handler hook. Override in subclasses to add custom error handling.

#### `finally(_: Error | undefined): Promise<unknown>`

Cleanup hook called after `run()` and `catch()` regardless of success or failure.

---

## TransactionCommand

Extends `BaseCommand` with blockchain transaction capabilities. Use this class for commands that submit transactions to the network.

### Additional Features

**Commitment Level Flag**

```typescript
static baseFlags = {
  commitment: Flags.string({
    options: ['processed', 'confirmed', 'finalized'] as const,
    summary: 'Commitment level',
    helpGroup: 'GLOBAL',
  }),
  // ... other base flags
}
```

The `--commitment` flag specifies the blockchain confirmation level for transactions:
- `processed` — Minimum confirmation, fastest
- `confirmed` — Intermediate confirmation
- `finalized` — Highest confirmation, slowest (recommended for production)

**Explorer Integration**

`TransactionCommand` passes an `explorer` flag to context creation (the call graph shows `explorer: this.flags.explorer`), enabling transaction explorer links in output.

### Static Examples

```typescript
static baseExamples = [
  '<%= config.bin %> <%= command.id %> --json',
  '<%= config.bin %> <%= command.id %> --log-level debug',
  '<%= config.bin %> <%= command.id %> --keypair /path/to/keypair.json',
  '<%= config.bin %> <%= command.id %> --keypair usb://ledger?key=0',
  '<%= config.bin %> <%= command.id %> --rpc http://localhost:8899',
  '<%= config.bin %> <%= command.id %> --commitment finalized',
]
```

These examples appear in command help output to demonstrate common usage patterns.

---

## Type Exports

Both classes export generic type utilities for type-safe flag and argument access:

```typescript
export type Flags<T extends typeof Command> = Interfaces.InferredFlags<T['flags'] & (typeof BaseCommand)['baseFlags']>
export type Args<T extends typeof Command> = Interfaces.InferredArgs<T['args']>
```

These types combine command-specific flags/args with the base flags, enabling proper type inference in subclasses:

```typescript
class MyCommand extends TransactionCommand<typeof MyCommand> {
  // this.flags is typed as Flags<typeof MyCommand>
  // this.args is typed as Args<typeof MyCommand>
}
```

---

## Usage in Commands

Commands in the toolbox extend these base classes:

```typescript
// For transaction commands
export default class CreateToken extends TransactionCommand<typeof CreateToken> {
  static description = 'Create a new token'

  async run(): Promise<void> {
    // this.context is already initialized
    // this.flags contains all base flags plus command-specific flags
    const result = await createToken(this.context, this.flags)
    this.logSuccess(`Token created: ${result}`)
  }
}

// For non-transactional commands (read-only, etc.)
export default class FetchLUT extends BaseCommand<typeof FetchLUT> {
  static description = 'Fetch a Lookup Table'

  async run(): Promise<void> {
    const lut = await fetchLUT(this.context, this.flags.address)
    this.log(lut)
  }
}
```

---

## Context Creation

Both commands create a `Context` object during initialization. The context encapsulates:

- RPC connection configuration
- Commitment level
- Keypair for signing transactions
- Payer account
- Other runtime settings

This object is then available to all command logic, providing a consistent interface to the blockchain and configuration.

---

## Extending These Classes

When creating a new command:

1. **Choose the appropriate base class**: Use `TransactionCommand` for commands that submit transactions, `BaseCommand` for read-only or utility commands.

2. **Define command-specific flags**: Add to the `static flags` property in your subclass.

3. **Define command-specific args**: Add to the `static args` property in your subclass.

4. **Implement `run()`**: The main command logic.

5. **Optionally override `catch()` or `finally()`**: For custom error handling or cleanup.

```typescript
import { Flags } from '@oclif/core'
import { TransactionCommand } from '../../src/TransactionCommand.js'

export default class MyCommand extends TransactionCommand<typeof MyCommand> {
  static description = 'Do something useful'

  static flags = {
    amount: Flags.string({
      required: true,
      summary: 'Amount to process',
    }),
    // Inherits: --config, --keypair, --rpc, --commitment, --json, etc.
  }

  async run(): Promise<void> {
    const { amount } = this.flags
    // Command logic here
    this.logSuccess('Done!')
  }
}
```