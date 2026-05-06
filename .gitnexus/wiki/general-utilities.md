# General Utilities

# General Utilities Module

The General Utilities module provides foundational helper functions, type definitions, and cross-cutting concerns used throughout the codebase. It encompasses file operations, JSON serialization with BigInt support, Solana-specific utilities, validation functions, tree storage management, progress tracking, instruction serialization, and blockchain explorer URL generation.

## Module Structure

```
src/
├── lib/
│   ├── util.ts           # Core utilities (JSON, sleep, addresses, chain detection)
│   ├── file.ts           # File system operations
│   ├── validations.ts    # Input validation functions
│   ├── treeStorage.ts    # Merkle tree persistence
│   ├── types/
│   │   └── pluginData.ts # MPL Core plugin type definitions
│   ├── ui/
│   │   └── uploadProgressHandler.ts  # Progress display
│   └── execute/
│       └── deserializeInstruction.ts # Instruction serialization
└── explorers.ts         # Blockchain explorer URL generation
```

## Core Utilities (`src/lib/util.ts`)

### JSON Serialization with BigInt Support

JavaScript's `JSON.stringify` throws an error when encountering `BigInt` values. These utilities handle that gracefully:

```typescript
// Stringify: converts BigInt to string with 'n' suffix
jsonStringify({ amount: 1000000000n, name: "Token" }
// Output: {"amount":"1000000000n","name":"Token"}

// Parse: optionally converts "123n" strings back to BigInt
jsonParse('{"amount":"1000000000n"}', true)
// Output: { amount: 1000000000n }
```

### Transaction Signature Conversion

```typescript
txSignatureToString(signature: TransactionSignature): string
```

Converts a Umi `TransactionSignature` to a base58-encoded string using the Umi serializers.

### Chain Detection

The module detects which Solana network (Mainnet, Devnet, or Localnet) a given RPC URL points to by fetching the genesis hash:

```typescript
const chain = await chain('https://api.devnet.solana.com')
// Returns: RpcChain.Devnet
```

The detection uses a hardcoded map of known genesis hashes:

| Genesis Hash | Network |
|--------------|---------|
| `5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d` | Mainnet |
| `EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG` | Devnet |
| `4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY` | Localnet (Testnet) |

### Address Utilities

```typescript
// Shorten addresses for display
shortenAddress("7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU", 4)
// Output: "7xKX...gAsU"
```

### Cross-Platform Directory Opening

```typescript
openDirectory("/path/to/folder")
```

Opens the specified folder in the system's file explorer:
- **Windows**: Uses `start` command
- **macOS**: Uses `open` command
- **Linux**: Tries `xdg-open`, `nautilus`, `dolphin`, `nemo`, or `thunar` in order

### Terminal Styling

ANSI escape codes for terminal output formatting:

```typescript
terminalStyle.bold   // '\x1b[1m'
terminalStyle.underline  // '\x1b[4m'
terminalStyle.inverse    // '\x1b[7m'
```

## File Operations (`src/lib/file.ts`)

Synchronous JSON file operations that integrate with the BigInt-aware utilities:

```typescript
// Read and parse JSON
const config = readJsonSync('./config.json')

// Write formatted JSON
writeJsonSync('./output.json', { key: "value" })

// Ensure directory exists before writing
ensureDirectoryExists('./data/nested/path')
```

The `ensureDirectoryExists` function creates directories recursively using `mkdirSync` with `{ recursive: true }`.

## Validation Functions (`src/lib/validations.ts`)

Input validation for token creation parameters:

| Function | Rules |
|----------|-------|
| `validateTokenName` | 1-32 characters |
| `validateTokenSymbol` | 2-6 characters |
| `validateMintAmount` | Greater than 0, no more than 1 trillion |

All functions throw descriptive `Error` instances on validation failure and return the validated value on success.

## Tree Storage (`src/lib/treeStorage.ts`)

Manages persistent storage of Merkle tree configurations in `~/.config/mplx/trees.json`.

### Storage Location

```typescript
getTreesFilePath()
// Returns: ~/.config/mplx/trees.json
```

### Stored Tree Schema

```typescript
interface StoredTree {
  name: string           // User-defined name
  address: string        // Tree account address
  maxDepth: number       // Tree depth
  maxBufferSize: number  // Buffer size
  canopyDepth: number   // Canopy depth
  isPublic: boolean      // Public access
  maxNfts: number        // Maximum NFTs
  createdAt: string      // ISO timestamp
  signature: string      // Creation transaction
  network: 'mainnet' | 'devnet' | 'testnet' | 'localnet'
  genesisHash: string    // Network genesis hash
}
```

### Operations

```typescript
// Save a new tree (throws if name/address already exists)
saveTree(tree: StoredTree)

// Find tree by name or address
const tree = getTreeByNameOrAddress("my-tree")
const tree = getTreeByNameOrAddress("Address...", "devnet")

// List all trees, optionally filtered
const allTrees = listTrees()
const devnetTrees = listTrees("devnet")

// Remove tree
removeTree("my-tree")
removeTree("Address...", "devnet")

// Validate tree name format
isValidTreeName("My Tree 2024")  // true - alphanumeric, hyphens, underscores, spaces
isValidTreeName("tree@invalid")  // false - contains @
```

## Plugin Type Definitions (`src/lib/types/pluginData.ts`)

TypeScript type definitions for MPL Core plugins. The `PluginData` interface maps plugin names to their corresponding MPL Core plugin types:

```typescript
type Plugin = 
  | 'royalties' | 'pBurn' | 'pTransfer' | 'pFreeze'
  | 'autograph' | 'freeze' | 'transfer' | 'burn'
  | 'update' | 'masterEdition' | 'attributes'
  | 'addBlocker' | 'immutableMetadata' | 'verifiedCreators'
  | 'edition' | 'bubblegumV2'

interface PluginData {
  royalties?: { type: 'Royalties' } & BasePlugin & RoyaltiesPlugin
  burn?: { type: 'BurnDelegate' } & BasePlugin & BurnDelegatePlugin
  // ... other plugins
}
```

## Progress Handlers (`src/lib/ui/uploadProgressHandler.ts`)

Two implementations for displaying upload progress using the `ora` spinner library:

### Detailed Progress Handler

Tracks multiple phases with separate spinners:

```typescript
const handler = createUploadProgressHandler()

handler({ phase: 'images-start', message: 'Uploading images...' })
handler({ phase: 'images', message: '50/100 images uploaded' })
handler({ phase: 'images-complete', message: '100 images uploaded' })
handler({ phase: 'json-start', message: 'Updating JSON metadata...' })
handler({ phase: 'json-complete', message: 'JSON files ready' })
```

Phases: `images-start` → `images` → `images-complete` → `updating-json` → `json-start` → `json` → `json-complete` → `complete`

### Simple Progress Handler

Single spinner showing percentage:

```typescript
const handler = createSimpleProgressHandler()
handler(0.25)   // "Uploading assets... 25%"
handler(0.50)  // "Uploading assets... 50%"
handler(1.0)   // "Upload completed"
```

## Instruction Serialization (`src/lib/execute/deserializeInstruction.ts`)

Serializes and deserializes Solana instructions to/from base64 format.

### Binary Format

```
┌─────────────────────────────────────────────────────────────┐
│ 32 bytes: Program ID                                        │
├─────────────────────────────────────────────────────────────┤
│ 2 bytes (u16 LE): Number of accounts                        │
├─────────────────────────────────────────────────────────────┤
│ For each account:                                           │
│   - 32 bytes: Public key                                     │
│   - 1 byte: Flags (bit 0 = isSigner, bit 1 = isWritable)   │
├─────────────────────────────────────────────────────────────┤
│ Remaining bytes: Instruction data                           │
└─────────────────────────────────────────────────────────────┘
```

### Usage

```typescript
// Deserialize from base64
const instruction = deserializeInstruction("AgAAAA...")

// Serialize to base64
const base64 = serializeInstruction(instruction)
```

## Explorer URL Generation (`src/explorers.ts`)

Generates links to blockchain explorers for transactions and accounts.

### Supported Explorers

| Explorer | Base URL |
|----------|----------|
| `solanaExplorer` | https://explorer.solana.com/ |
| `solscan` | https://solscan.io/ |
| `solanaFm` | https://solana.fm/ |

### URL Generation

```typescript
import { explorers, generateExplorerUrl, generateCoreExplorerUrl, RpcChain } from './explorers'

// Generate transaction URL
const url = generateExplorerUrl('solscan', RpcChain.Devnet, 'txSignature...', 'transaction')
// Output: https://solscan.io/tx/txSignature?cluster=devnet

// Generate account URL
const url = generateExplorerUrl('solanaExplorer', RpcChain.Mainnet, 'Address...', 'account')
// Output: https://explorer.solana.com/address/Address...

// Generate Metaplex Core explorer URL
const coreUrl = generateCoreExplorerUrl(RpcChain.Devnet, 'CoreAddress...')
// Output: https://core.metaplex.com/explorer/CoreAddress?env=devnet
```

## Dependencies

The module integrates with several external libraries:

- **@metaplex-foundation/umi**: Transaction signatures, serialization, public keys
- **@solana/web3.js**: Connection for genesis hash fetching
- **@metaplex-foundation/mpl-core**: Plugin type definitions
- **mime**: File MIME type detection
- **ora**: Terminal spinner for progress display