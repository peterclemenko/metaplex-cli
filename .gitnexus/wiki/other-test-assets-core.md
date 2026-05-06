# Other — test-assets-core

# Test Assets: Core Module

## Overview

The `test-assets/core` directory contains static test data for NFT (Non-Fungible Token) testing within the broader Candy Machine or similar Solana NFT minting project. These assets simulate real NFT metadata, plugin configurations, and binary data that the codebase processes during testing.

## Asset Structure

The module contains three categories of test assets:

| File Pattern | Count | Purpose |
|--------------|-------|---------|
| `{n}.json` | 16 files (0-15) | NFT metadata JSON files |
| `{n}-plugins.json` | 1 file (1-plugins.json) | Plugin configuration for NFT #1 |
| `plugins.json` | 1 file | Default plugin configuration |
| `test.json` | 1 file | Binary data (byte array) |

## NFT Metadata Files (`{n}.json`)

These files follow the Metaplex NFT metadata standard (version 1.0), which defines the on-chain and off-chain data structure for Solana NFTs.

### Standard Fields

```json
{
  "name": "Numbers #N",
  "symbol": "NUMBERS",
  "image": "https://...",
  "properties": {
    "files": [{ "uri": "...", "type": "image/png" }],
    "category": "image",
    "creators": [{ "address": "...", "share": 100 }]
  },
  "description": "A set of test NFTs for the Solana blockchain",
  "seller_fee_basis_points": 500,
  "attributes": [{ "trait_type": "Number", "value": "N" }]
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name of the NFT |
| `symbol` | string | Token symbol (max 10 chars) |
| `image` | string | Primary image URL (Irys or Arweave) |
| `properties.files` | array | Additional file references with MIME types |
| `properties.category` | string | Asset category (e.g., "image", "video") |
| `properties.creators` | array | Creator addresses and share percentages |
| `description` | string | Human-readable description |
| `seller_fee_basis_points` | number | Royalty percentage (500 = 5%) |
| `attributes` | array | On-chain traits for rarity/filtering |

### Notable Variations

**File 0.json** — Uses an embedded Irys gateway URL in both `image` and `properties.files[0].uri`:

```json
{
  "image": "https://gateway.irys.xyz/AaVaCEGBAqAVBSAGvgWgh3SNcidZ29BxhhETFENTvVMx",
  "properties": {
    "files": [{
      "uri": "https://gateway.irys.xyz/AaVaCEGBAqAVBSAGvgWgh3SNcidZ29BxhhETFENTvVMx",
      "type": "image/png"
    }]
  }
}
```

**Files 1-15** — Use Arweave URLs for images and relative paths (`"uri": "N.png"`) in the files array.

## Plugin Configuration Files

The plugin system extends standard NFT metadata with programmable behavior.

### `plugins.json` and `1-plugins.json`

Both files contain identical plugin configurations:

```json
[
  {
    "type": "Attributes",
    "authority": { "type": "Address", "address": "..." },
    "attributeList": [{ "key": "Background", "value": "Blue" }]
  },
  {
    "type": "FreezeDelegate",
    "authority": { "type": "UpdateAuthority" },
    "frozen": false
  },
  {
    "type": "Royalties",
    "authority": { "type": "UpdateAuthority" },
    "basisPoints": 500,
    "creators": [{ "address": "...", "percentage": 100 }],
    "ruleSet": { "type": "None" }
  }
]
```

### Plugin Types

| Plugin | Purpose |
|--------|---------|
| **Attributes** | Key-value metadata that can be modified by an authority |
| **FreezeDelegate** | Controls whether the NFT is frozen (non-transferable) |
| **Royalties** | Defines royalty distribution and enforcement rules |

### Authority Types

- **`Address`** — A specific Solana address has authority
- **`UpdateAuthority`** — The NFT's update authority has authority

### Rule Sets

- **`{ "type": "None" }`** — No additional rules enforce the plugin

## Binary Test Data (`test.json`)

```json
[196,167,246,133,208,120,170,18,64,212,95,148,36,206,189,163,59,113,199,38,51,79,43,205,37,0,217,184,194,97,243,55,6,184,75,232,112,213,134,67,249,246,201,68,2,51,17,2,37,158,150,210,205,74,250,134,165,134,20,86,102,248,233,233]
```

This is a 64-byte array representing raw binary data. Use cases include:

- Testing image encoding/decoding pipelines
- Verifying file upload handling for non-JSON assets
- Simulating arbitrary file payloads

## Creator Address

All assets reference the same creator address:

```
4xbJp9sjeTEhheUDg8M1nJUomZcGmFZsjt9Gg3RQZAWp
```

This address receives:
- 100% of creator shares
- 5% royalty (`seller_fee_basis_points: 500`)

## Usage in Tests

These assets are loaded by test suites to verify:

1. **Metadata parsing** — Correct extraction of name, symbol, attributes
2. **Plugin deserialization** — Loading and validating plugin configurations
3. **URI resolution** — Handling both absolute URLs and relative paths
4. **Creator/royalty validation** — Verifying royalty calculations
5. **Binary handling** — Processing non-JSON file formats

## Integration Points

```
test-assets/core/
    │
    ├── {n}.json          → MetadataParser, NFTBuilder
    ├── plugins.json     → PluginSystem, AuthorityResolver
    └── test.json        → FileHandler, BinaryProcessor
```

The assets are consumed by core modules that handle:
- NFT metadata validation and serialization
- Plugin lifecycle management (attach, authorize, execute)
- Asset upload to storage providers (Irys, Arweave)