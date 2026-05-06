# Other — scripts

# Test Candy Machine Directory Creator

A development utility script that creates a complete test candy machine directory structure with assets, metadata, and optional configuration files. This is useful for testing candy machine operations without needing to go through the full upload and minting flow.

## Overview

The script generates a local directory containing:

- **Asset files** — Numbered PNG images and JSON metadata files
- **Asset cache** — A `asset-cache.json` file tracking asset state
- **Collection files** — A collection NFT image and metadata
- **Config file** (optional) — A `cm-config.json` with guard configurations

This mimics the directory structure that would be created during a real candy machine asset preparation process, making it useful for integration testing and local development workflows.

## CLI Usage

```bash
node scripts/createTestCandyMachineDirectory.js [options]
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--with-config` | Include `cm-config.json` with guard settings | `false` |
| `--no-assets` | Skip creating asset files | `false` |
| `--name=<value>` | Name of the candy machine directory | `candy1` |
| `--assets=<number>` | Number of assets to create | `50` |
| `--collection=<mint>` | Collection mint address | `undefined` |
| `--uploaded` | Mark assets as already uploaded (includes URIs) | `false` |

### Examples

```bash
# Create minimal test directory with 50 assets
node scripts/createTestCandyMachineDirectory.js

# Create with config and custom name
node scripts/createTestCandyMachineDirectory.js --with-config --name=my-candy-machine

# Create 100 assets with collection
node scripts/createTestCandyMachineDirectory.js --assets=100 --collection=4xbJp9sjeTEhheUDg8M1nJUomZcGmFZsjt9Gg3RQZAWp

# Create pre-uploaded assets (with URIs in cache)
node scripts/createTestCandyMachineDirectory.js --uploaded
```

## Programmatic Usage

The script exports `createTestCandyMachineAssetDirectory` for use in other code:

```javascript
import { createTestCandyMachineAssetDirectory } from './scripts/createTestCandyMachineDirectory.js';

// Basic usage
await createTestCandyMachineAssetDirectory();

// Custom options
await createTestCandyMachineAssetDirectory({
    withConfig: true,
    withAssets: true,
    name: 'test-candy',
    numberOfAssets: 25,
    collection: '4xbJp9sjeTEhheUDg8M1nJUomZcGmFZsjt9Gg3RQZAWp',
    uploaded: true
});
```

## Output Directory Structure

When run with default options, creates:

```
candy1/
├── asset-cache.json
└── assets/
    ├── 0.png
    ├── 0.json
    ├── 1.png
    ├── 1.json
    ├── ...
    ├── 49.png
    ├── 49.json
    ├── collection.png
    └── collection.json
```

When run with `--with-config`:

```
candy1/
├── asset-cache.json
├── cm-config.json
└── assets/
    └── ...
```

## Key Components

### createTestCandyMachineAssetDirectory(options)

Main orchestration function. Creates the directory structure and delegates to helper functions based on options.

**Parameters:**
- `options.withConfig` — Whether to create the config file
- `options.withAssets` — Whether to create asset files
- `options.name` — Directory name (also used in config)
- `options.numberOfAssets` — Count of assets to generate
- `options.collection` — Collection mint address
- `options.uploaded` — Whether to populate URI fields in cache

### createDummyConfig(candyMachineDir, numberOfAssets, collection)

Generates a `cm-config.json` file with sample guard configurations. The config includes:

- Two guard groups (`test1` and `test2`)
- `solPayment` guard with lamport amounts and destination addresses
- `assetBurn` guard with required collection
- `thirdPartySigner` guard

### createAssetMetadata(index, collection)

Creates JSON metadata for an individual asset following standard NFT metadata format:

```json
{
    "name": "Asset 0",
    "description": "Asset 0 description",
    "image": "https://example.com/0.png",
    "attributes": [{ "trait_type": "Index", "value": "0" }],
    "properties": {
        "files": [{ "uri": "https://example.com/0.png", "type": "image/png" }],
        "category": "image"
    }
}
```

### createDummyPNG()

Generates a minimal valid 1x1 PNG file as a Buffer. This is used for all asset images to avoid needing external image files during testing.

## Integration Notes

This script is standalone and has no dependencies on other modules in the codebase. It writes files to the current working directory, creating a subdirectory with the candy machine name.

The generated structure is compatible with candy machine upload and mint operations that expect:
- Numbered PNG/JSON pairs in an `assets/` subdirectory
- A `asset-cache.json` tracking upload state
- Optional `cm-config.json` with guard definitions