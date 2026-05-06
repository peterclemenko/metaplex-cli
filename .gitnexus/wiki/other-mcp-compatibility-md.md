# Other — MCP_COMPATIBILITY.md

# MCP Compatibility Tracker

This document tracks the compatibility status of CLI commands with MCP (Model Context Protocol) tools. MCP allows AI assistants like Claude to interact with the CLI as tools, passing arguments and receiving structured results programmatically.

## Purpose

MCP tools need to:

1. **Accept arguments programmatically** — Commands must have non-interactive paths (no prompts, wizards, or TTY-dependent flows)
2. **Return structured data** — Commands must return parseable JSON that MCP tools can consume

This tracker identifies which commands meet these requirements and which need fixes.

## Key Issues

### Issue 1: `--json` Returns `null`

Most commands extend `TransactionCommand` or `BaseCommand` which set `enableJsonFlag = true`, enabling the `--json` flag. However, the `run()` method returns `void`, so `--json` outputs `{"result": null}` — useless for MCP consumption.

**Root cause:** Commands perform side effects (logging, RPC calls) but don't return the data.

**Fix required:** Commands must return structured data from `run()`.

```typescript
// Current (broken for MCP)
async run(): Promise<void> {
  const result = await this.doThing();
  console.log(result); // Only goes to stdout, not returned
}

// Required for MCP
async run(): Promise<{ result: string }> {
  const result = await this.doThing();
  return { result };
}
```

### Issue 2: Always-Interactive Commands

Three commands have no non-interactive path. They always prompt for input and cannot be used by MCP tools.

### Issue 3: Config Commands Lack `--json` Support

Config commands (`config rpcs`, `config wallets`, `config explorer`, `config storage`) extend plain `Command` instead of `BaseCommand`, so they lack the `--json` flag entirely.

## Status Categories

| Status | Meaning |
|--------|---------|
| **Ready** | Works with MCP as-is |
| **Needs JSON Return** | Non-interactive but `--json` returns null; needs `run()` to return data |
| **Conditional** | Works only when specific flags/args are provided; avoid wizard/interactive flags |
| **Incompatible** | Always interactive; needs a non-interactive path added |
| **No --json** | Extends plain `Command`; no JSON output support |

## Command Inventory

### Core Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `core asset create` | Conditional + Needs JSON Return | `--wizard`, `--plugins` are interactive | Returns null | Avoid `--wizard`/`--plugins`; use `--name`/`--uri` |
| `core asset burn` | Needs JSON Return | No | Returns null | Should return signature |
| `core asset fetch` | Needs JSON Return | No | Returns null | Should return asset data |
| `core asset update` | Needs JSON Return | No | Returns null | Should return signature |
| `core asset template` | Needs JSON Return | No | Returns null | Should return file path |
| `core collection create` | Conditional + Needs JSON Return | `--wizard`, `--plugins` are interactive | Returns null | Should return collection address + sig |
| `core collection fetch` | Ready | No | Returns on-chain asset object | Best fetch command |
| `core collection template` | Needs JSON Return | No | Returns null | Should return file path |
| `core plugins add` | Conditional + Needs JSON Return | `--wizard` is interactive | Returns null | Use JSON file arg |
| `core plugins update` | Conditional + Needs JSON Return | `--wizard` is interactive | Returns null | Use JSON file arg |
| `core plugins generate` | **Incompatible** | Always interactive | Returns null | Needs non-interactive flag path |

### Config Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `config get` | No --json | No | No `--json` flag | `run()` returns ConfigJson but no flag to use it |
| `config set` | No --json | No | No `--json` flag | |
| `config rpcs add` | No --json | No | No `--json` flag | |
| `config rpcs list` | No --json | No | No `--json` flag | Uses `console.table()` |
| `config rpcs remove` | No --json | No | No `--json` flag | |
| `config rpcs set` | Conditional + No --json | Interactive if `name` arg omitted | No `--json` flag | Always provide `name` arg |
| `config wallets add` | No --json | No | No `--json` flag | |
| `config wallets list` | No --json | No | No `--json` flag | Uses `console.table()` |
| `config wallets new` | Needs JSON Return | No | Returns null | Should return keypair path + pubkey |
| `config wallets remove` | No --json | No | No `--json` flag | |
| `config wallets set` | Conditional + No --json | Interactive if `name` arg omitted | No `--json` flag | Always provide `name` arg |
| `config explorer set` | **Incompatible** | Always interactive | No `--json` flag | Needs `--explorer` arg |
| `config storage set` | **Incompatible** | Always interactive | No `--json` flag | Needs `--provider` arg |

### Toolbox - SOL Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox sol airdrop` | Needs JSON Return | No | Returns null | Should return signature + balance |
| `toolbox sol balance` | Needs JSON Return | No | Returns null | Should return balance value |
| `toolbox sol transfer` | Ready | No | Returns "success" | Could be improved to return sig |
| `toolbox sol wrap` | Ready | No | Returns "success" | |
| `toolbox sol unwrap` | Ready | No | Returns "success" | |

### Toolbox - Token Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox token create` | Conditional + Needs JSON Return | `--wizard` is interactive | Returns null | Should return mint address + sig |
| `toolbox token mint` | Ready | No | Returns tx result | Good |
| `toolbox token transfer` | Needs JSON Return | No | Returns null | Should return signature |
| `toolbox token update` | Conditional + Needs JSON Return | `--editor` is interactive | Returns null | Avoid `--editor` |
| `toolbox token add-metadata` | Needs JSON Return | No | Returns null | Should return signature |

### Toolbox - Storage Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox storage balance` | Needs JSON Return | No | Returns null | Logs JSON text but doesn't return it |
| `toolbox storage fund` | Needs JSON Return | No | Returns null | |
| `toolbox storage upload` | Needs JSON Return | No | Returns null | Should return URI |
| `toolbox storage withdraw` | Needs JSON Return | No | Returns null | |

### Toolbox - LUT Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox lut create` | Needs JSON Return | No | Returns null | Should return LUT address + sig |
| `toolbox lut fetch` | Ready (custom) | No | Custom `--json` flag | Has its own JSON output logic |
| `toolbox lut deactivate` | Needs JSON Return | No | Returns null | |
| `toolbox lut close` | Needs JSON Return | No | Returns null | |

### Toolbox - Template Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox template program` | Conditional + No --json | Interactive if `template` arg omitted | No `--json` flag | Always provide arg |
| `toolbox template website` | Conditional + No --json | Interactive if `--template` omitted | No `--json` flag | Always provide flag |

### Toolbox - Other

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `toolbox rent` | Needs JSON Return | No | Returns null | Should return rent value |

### Genesis Commands

| Command | Status | Interactive? | `--json` works? | Notes |
|---|---|---|---|---|
| `genesis create` | Needs JSON Return | No | Returns null | Should return genesis address + sig |
| `genesis fetch` | Needs JSON Return | No | Returns null | Should return genesis data |
| `genesis deposit` | Needs JSON Return | No | Returns null | |
| `genesis withdraw` | Needs JSON Return | No | Returns null | |
| `genesis claim` | Needs JSON Return | No | Returns null | |
| `genesis claim-unlocked` | Needs JSON Return | No | Returns null | |
| `genesis finalize` | Needs JSON Return | No | Returns null | |
| `genesis revoke` | Needs JSON Return | No | Returns null | |
| `genesis transition` | Needs JSON Return | No | Returns null | |
| `genesis bucket add-launch-pool` | Needs JSON Return | No | Returns null | |
| `genesis bucket add-presale` | Needs JSON Return | No | Returns null | |
| `genesis bucket add-unlocked` | Needs JSON Return | No | Returns null | |
| `genesis bucket fetch` | Needs JSON Return | No | Returns null | Should return bucket data |
| `genesis presale claim` | Needs JSON Return | No | Returns null | |
| `genesis presale deposit` | Needs JSON Return | No | Returns null | |

## MCP-Only Tools

These tools should be implemented directly in the MCP server, not as CLI commands. They don't map well to CLI semantics.

| Tool | Status | Description |
|---|---|---|
| `write_temp_file` | TODO | Accept base64 data, write to temp file, return path. Used for AI-generated images. |

## Priority Order

### P0 — Incompatible Commands

These commands cannot be used by MCP tools at all. Fixes require adding non-interactive argument paths.

1. **`core plugins generate`** — Add `--plugin` and `--config` flags for non-interactive use
2. **`config explorer set`** — Add positional argument or `--explorer` flag
3. **`config storage set`** — Add positional argument or `--provider` flag

### P1 — High-Value Commands

These are the commands MCP tools will use most frequently. Fixes require returning structured data from `run()`.

1. **`core asset create`** — Return `{ asset, signature }`
2. **`core collection create`** — Return `{ collection, signature }`
3. **`core asset fetch`** — Return asset data
4. **`toolbox token create`** — Return `{ mint, signature }`
5. **`toolbox storage upload`** — Return `{ uri }` (critical for upload workflow)
6. **`toolbox sol balance`** — Return `{ balance }`
7. **`genesis create`** — Return `{ genesis, signature }`
8. **`genesis fetch`** — Return genesis data

### P2 — Remaining Commands

All other commands marked "Needs JSON Return" in the inventory above.

### P3 — Config Commands

Migrate config commands to extend `BaseCommand` or manually add `enableJsonFlag` to enable `--json` support.

## Architecture Connection

This tracker connects to the CLI codebase through the command hierarchy:

```
Command (oclif base)
    └── BaseCommand
            └── TransactionCommand
                    ├── Core Commands (core asset, core collection, etc.)
                    └── Genesis Commands
```

Config commands currently bypass this hierarchy by extending `Command` directly, which is why they lack `--json` support.

The `--json` flag is implemented via OCLIF's `enableJsonFlag` option, which intercepts the flag and formats the `run()` return value as JSON. When `run()` returns `void`, the output is `{"result": null}`.