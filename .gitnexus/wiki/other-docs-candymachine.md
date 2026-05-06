# Other — docs-candyMachine

# Candy Machine Module

The Candy Machine module provides CLI commands for creating, managing, and deploying MPL Core Candy Machines on Solana. Candy machines control NFT minting with configurable rules called "guards" that enforce payment requirements, access restrictions, timing constraints, and more.

## Overview

The candy machine system consists of three main components:

1. **Commands** — CLI operations for creating candy machines, uploading assets, and inserting items
2. **Guards** — Rules that control who can mint, when they can mint, and what they must pay
3. **Guard Groups** — Collections of guards that apply to specific minting phases (whitelist, public sale, etc.)

## Command Structure

All candy machine commands use the `mplx cm` prefix:

```bash
mplx cm <command> [options]
```

### Available Commands

| Command | Description |
|---------|-------------|
| `create` | Creates a new candy machine with optional wizard guidance |
| `upload` | Uploads assets to decentralized storage |
| `insert` | Inserts uploaded assets into the candy machine |
| `validate` | Validates the asset cache file |

### Wizard Mode (Recommended)

The `--wizard` flag provides an interactive, guided experience:

```bash
mplx cm create --wizard
```

The wizard walks through:
- Directory setup and validation
- Asset discovery and validation
- Collection configuration
- Candy machine settings and guards
- Asset upload with progress tracking
- On-chain candy machine creation
- Item insertion with transaction progress

Type `q` at any prompt to abort gracefully.

## Asset Directory Structure

Candy machine commands operate from a specific directory structure:

```
candy-machine-name/
├── assets/
│   ├── 0.png              # NFT image files
│   ├── 0.json             # NFT metadata
│   ├── 1.png
│   ├── 1.json
│   ├── ...
│   ├── collection.png     # Collection image (optional)
│   └── collection.json    # Collection metadata (required)
├── asset-cache.json       # Generated: upload URIs
└── cm-config.json         # Generated: candy machine config
```

### Asset Requirements

- **Naming**: Files must be numbered sequentially (0.png, 1.png, 2.png...)
- **Metadata**: Each image needs a corresponding JSON file with the same number
- **Collection**: `collection.json` must contain a `name` field
- **Formats**: PNG and JPG images are supported

### Metadata JSON Format

```json
{
  "name": "Asset Name",
  "symbol": "SYMBOL",
  "description": "Asset description",
  "image": "https://example.com/image.png",
  "attributes": [
    { "trait_type": "Background", "value": "Blue" },
    { "trait_type": "Eyes", "value": "Green" }
  ],
  "properties": {
    "files": [
      { "type": "image/png", "uri": "https://example.com/image.png" }
    ]
  }
}
```

## Guards

Guards are rules that control the minting process. They can require payment, restrict access, enforce limits, and more.

### Guard Categories

#### Payment Guards

| Guard | Description |
|-------|-------------|
| `solPayment` | Require SOL payment |
| `solFixedFee` | Fixed SOL fee |
| `tokenPayment` | Require SPL token payment |
| `token2022Payment` | Require Token-2022 payment |
| `nftPayment` | Require NFT from specific collection as payment |
| `assetPayment` | Require asset as payment |
| `assetPaymentMulti` | Require multiple assets as payment |
| `freezeSolPayment` | SOL payment with freeze period |
| `freezeTokenPayment` | Token payment with freeze period |

**Example: SOL Payment**
```json
{
  "solPayment": {
    "lamports": 1000000000,
    "destination": "WalletAddress..."
  }
}
```

**Example: Token Payment**
```json
{
  "tokenPayment": {
    "amount": 1000000,
    "mint": "TokenMintAddress...",
    "destinationAta": "DestinationATA..."
  }
}
```

#### Access Control Guards

| Guard | Description |
|-------|-------------|
| `addressGate` | Restrict to specific wallet |
| `allowList` | Merkle tree allowlist |
| `nftGate` | Require NFT from collection |
| `tokenGate` | Require specific token amount |
| `assetGate` | Require asset from collection |
| `programGate` | Require specific programs in transaction |
| `thirdPartySigner` | Require additional signer |

**Example: Allow List**
```json
{
  "allowList": {
    "merkleRoot": "MerkleRootHash..."
  }
}
```

**Example: NFT Gate**
```json
{
  "nftGate": {
    "requiredCollection": "CollectionAddress..."
  }
}
```

#### Time-Based Guards

| Guard | Description |
|-------|-------------|
| `startDate` | Minting start time (Unix timestamp) |
| `endDate` | Minting end time (Unix timestamp) |

**Example: Time-Restricted Sale**
```json
{
  "startDate": { "date": 1700000000 },
  "endDate": { "date": 1735689600 }
}
```

#### Limit Guards

| Guard | Description |
|-------|-------------|
| `mintLimit` | Mints per wallet (uses unique ID) |
| `allocation` | Specific mint allocation to wallet |
| `nftMintLimit` | Limit based on NFT holdings |
| `assetMintLimit` | Limit based on asset holdings |
| `redeemedAmount` | Total mint limit for candy machine |

**Example: Mint Limit**
```json
{
  "mintLimit": {
    "id": 1,
    "limit": 1
  }
}
```

**Note**: Use different `id` values for different groups to prevent conflicts.

#### Burn Guards

| Guard | Description |
|-------|-------------|
| `nftBurn` | Burn NFT from collection to mint |
| `tokenBurn` | Burn tokens to mint |
| `assetBurn` | Burn asset to mint |
| `assetBurnMulti` | Burn multiple assets to mint |

**Example: NFT Burn**
```json
{
  "nftBurn": {
    "requiredCollection": "CollectionAddress..."
  }
}
```

#### Special Guards

| Guard | Description |
|-------|-------------|
| `botTax` | Penalty for bot-like behavior |
| `edition` | Control edition numbering |
| `vanityMint` | Regex pattern for mint address |

**Example: Bot Tax**
```json
{
  "botTax": {
    "lamports": 1000000,
    "lastInstruction": true
  }
}
```

### Guard Configuration

Guards are configured in the `guardConfig` section:

```json
{
  "guardConfig": {
    "solPayment": {
      "lamports": 1000000000,
      "destination": "WalletAddress..."
    },
    "mintLimit": {
      "id": 1,
      "limit": 1
    }
  }
}
```

## Guard Groups

Guard groups enable phased minting with different rules for each phase. Common use cases include:

- Whitelist → Public sale
- NFT holder exclusive → Public sale
- Early bird → Regular → Final phases

### Group Structure

```json
{
  "groups": [
    {
      "label": "wl",
      "guards": {
        "allowList": { "merkleRoot": "..." },
        "solPayment": { "lamports": 500000000, "destination": "..." }
      }
    },
    {
      "label": "public",
      "guards": {
        "solPayment": { "lamports": 1000000000, "destination": "..." }
      }
    }
  ]
}
```

**Important**: Group labels are limited to **6 characters maximum**.

### Common Abbreviations

- `wl` — whitelist
- `reg` — regular
- `nft` — NFT holders
- `token` — token holders
- `burn` — burn to mint
- `vip` — VIP access
- `early` — early bird
- `final` — final phase

### Group vs Global Guards

- **Global guards** (`guardConfig`): Apply to all groups and the entire candy machine
- **Group guards** (`groups[].guards`): Apply only to that specific group

Global guards cannot be overridden by group guards. Use global guards for universal restrictions like bot protection.

### Example: Whitelist to Public Sale

```json
{
  "guardConfig": {
    "botTax": {
      "lamports": 1000000,
      "lastInstruction": true
    }
  },
  "groups": [
    {
      "label": "wl",
      "guards": {
        "allowList": { "merkleRoot": "WhitelistRoot..." },
        "solPayment": { "lamports": 500000000, "destination": "..." },
        "mintLimit": { "id": 1, "limit": 1 },
        "startDate": { "date": 1700000000 },
        "endDate": { "date": 1700086400 }
      }
    },
    {
      "label": "public",
      "guards": {
        "solPayment": { "lamports": 1000000000, "destination": "..." },
        "mintLimit": { "id": 2, "limit": 2 },
        "startDate": { "date": 1700086400 }
      }
    }
  ]
}
```

## Workflows

### Option 1: Wizard Mode (Recommended)

```bash
mplx cm create --wizard
```

This single command handles the entire process:
1. Validates assets and configuration
2. Uploads assets with progress tracking
3. Creates the candy machine on-chain
4. Inserts all items
5. Provides completion summary

### Option 2: Manual Mode

For full control, run commands individually:

```bash
# Navigate to candy machine directory
cd ./my-candy-machine

# Upload assets (can be done before or after create)
mplx cm upload

# Create candy machine
mplx cm create

# Insert items (must be after both create and upload)
mplx cm insert

# Validate uploads (optional)
mplx cm validate
```

**Command Order Rules:**
- `upload` and `create` can run in any order
- `insert` must run after both `upload` and `create`
- `validate` can run at any time

## Configuration Files

### cm-config.json

```json
{
  "name": "My Candy Machine",
  "candyMachineId": "CandyMachinePublicKey...",
  "config": {
    "collection": "CollectionPublicKey...",
    "itemsAvailable": 100,
    "isMutable": true,
    "isSequential": false,
    "guardConfig": { ... },
    "groups": [ ... ]
  }
}
```

### asset-cache.json

```json
{
  "candyMachineId": "CandyMachinePublicKey...",
  "collection": "CollectionPublicKey...",
  "assetItems": {
    "0": {
      "name": "Asset 0",
      "image": "0.png",
      "imageUri": "https://gateway.irys.xyz/...",
      "imageType": "image/png",
      "json": "0.json",
      "jsonUri": "https://gateway.irys.xyz/...",
      "loaded": false
    }
  }
}
```

## Common Patterns

### Basic Public Mint

```json
{
  "guardConfig": {
    "solPayment": {
      "lamports": 1000000000,
      "destination": "WalletAddress..."
    },
    "mintLimit": {
      "id": 1,
      "limit": 1
    }
  }
}
```

### NFT Holder Exclusive

```json
{
  "guardConfig": {
    "nftGate": {
      "requiredCollection": "CollectionAddress..."
    },
    "solPayment": {
      "lamports": 750000000,
      "destination": "WalletAddress..."
    },
    "mintLimit": {
      "id": 1,
      "limit": 2
    }
  }
}
```

### Three-Phase Launch

```json
{
  "groups": [
    {
      "label": "vip",
      "guards": {
        "allowList": { "merkleRoot": "VIPRoot..." },
        "solPayment": { "lamports": 500000000, "destination": "..." },
        "mintLimit": { "id": 1, "limit": 3 },
        "startDate": { "date": 1700000000 },
        "endDate": { "date": 1700040000 }
      }
    },
    {
      "label": "wl",
      "guards": {
        "allowList": { "merkleRoot": "WLRoot..." },
        "solPayment": { "lamports": 750000000, "destination": "..." },
        "mintLimit": { "id": 2, "limit": 2 },
        "startDate": { "date": 1700040000 },
        "endDate": { "date": 1700080000 }
      }
    },
    {
      "label": "public",
      "guards": {
        "solPayment": { "lamports": 1000000000, "destination": "..." },
        "mintLimit": { "id": 3, "limit": 1 },
        "startDate": { "date": 1700080000 }
      }
    }
  ]
}
```

## Best Practices

1. **Use the Wizard**: For most cases, `mplx cm create --wizard` provides the best experience with validation and progress tracking

2. **Test on Devnet**: Always test configurations on devnet before mainnet deployment

3. **Set At Least One Guard**: A candy machine without guards may not function properly

4. **Use Unique Mint Limit IDs**: When using multiple groups, use different `id` values for `mintLimit` guards to prevent conflicts

5. **Validate Assets**: Run `mplx cm validate` before inserting items to ensure all uploads succeeded

6. **Keep Cache Files**: The `asset-cache.json` and `cm-config.json` files are needed for future operations

7. **Monitor Progress**: The wizard and upload commands provide detailed progress — watch for errors

8. **Plan Phase Timing**: When using guard groups, ensure start/end dates don't overlap unintentionally

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not in Candy Machine Directory" | Ensure you're in a directory with `assets/` folder |
| "Asset Cache Not Found" | Run `mplx cm upload` first |
| "Missing Candy Machine ID" | Run `mplx cm create` first |
| "All Items Already Loaded" | Use the reload option when prompted |
| "Collection Name Missing" | Ensure `collection.json` has a valid `name` field |
| "Directory Already Exists" | Choose different name or confirm overwrite |

## Related Documentation

- [Guard Documentation](./guards.md) — Complete reference for all guard types
- [Guard Groups Documentation](./groups.md] — Detailed guide to phased minting
- [Metaplex Documentation](https://developers.metaplex.com)