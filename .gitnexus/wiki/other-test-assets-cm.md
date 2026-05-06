# Other — test-assets-cm

# Test Assets — Candy Machine (test-assets-cm)

## Overview

This module contains a collection of six NFT metadata files (`0.json` through `5.json`) in the Metaplex standard format. These files serve as test assets for a Solana Candy Machine deployment, representing a minimal collection of numbered NFTs.

## Purpose

These JSON files are designed to:

- Provide valid NFT metadata for testing Candy Machine minting workflows
- Serve as reference examples for the Metaplex JSON schema
- Enable end-to-end testing of NFT collection deployments on Solana

## Metadata Schema

Each file follows the Metaplex standard for NFT metadata. Below is the complete schema with field descriptions:

```json
{
  "name": "Numbers #N",           // Display name of the NFT
  "symbol": "NUMBERS",            // Token symbol (max 10 chars)
  "image": "https://...",         // URL to the NFT image
  "properties": {                 // Extended metadata
    "files": [...],               // Array of file references
    "category": "image",          // Asset category
    "creators": [...]             // Royalty distribution
  },
  "description": "...",           // Human-readable description
  "seller_fee_basis_points": 500, // Royalty percentage (500 = 5%)
  "attributes": [...]             // On-chain traits for rarity/display
}
```

## Collection Details

| Field | Value |
|-------|-------|
| Collection Name | Numbers |
| Symbol | NUMBERS |
| Total Items | 6 (indexed 0–5) |
| Creator Address | `4xbJp9sjeTEhheUDg8M1nJUomZcGmFZsjt9Gg3RQZAWp` |
| Royalty | 5% (500 basis points) |
| Category | Image |

## Attribute Traits

Each NFT includes a single attribute defining its number:

```json
{
  "trait_type": "Number",
  "value": "0"  // Ranges from "0" through "5"
}
```

This trait is stored on-chain and can be used by marketplaces to display rarity information or enable filtering.

## Creator Configuration

All NFTs assign 100% of royalties to a single creator address:

```json
"creators": [
  {
    "address": "4xbJp9sjeTEhheUDg8M1nJUomZcGmFZsjt9Gg3RQZAWp",
    "share": 100
  }
]
```

## Image Sources

The collection uses two different storage providers for demonstration purposes:

- **Index 0**: Irys gateway (`gateway.irys.xyz`)
- **Indices 1–5**: Arweave (`arweave.net`)

This variation reflects common real-world scenarios where NFT collections may migrate storage or use different providers for different mint batches.

## Usage in Candy Machine

When deploying a Candy Machine, these JSON files would typically be:

1. Uploaded to a permanent storage solution (Arweave, Irys, or IPFS)
2. Referenced in the Candy Machine configuration via their URI paths
3. Minted sequentially or randomly based on the collection's settings

## File Inventory

```
test-assets/cm/
├── 0.json  → Numbers #0
├── 1.json  → Numbers #1
├── 2.json  → Numbers #2
├── 3.json  → Numbers #3
├── 4.json  → Numbers #4
└── 5.json  → Numbers #5
```

## Integration Notes

This module is a **static data module** — it contains no executable code. It is consumed by:

- Candy Machine deployment scripts
- NFT minting utilities
- Testing frameworks that validate metadata parsing

When integrating, ensure your tooling supports the Metaplex JSON schema version used here (standard v1.0 format).