# Candy Machine — Upload Optimization Shim Analysis

Date: 2026-04-30

Objective: Insert an upload-optimization step into the Candy Machine creation wizard to minimize Arweave duplication. This document analyzes the wizard creation flow, produces a call graph, and recommends insertion points for a shim that deduplicates uploads.

**Quick Summary**
- Entry point: `src/commands/cm/create.ts` (`CmCreate.runWizard`).
- Key upload path: `runWizard` -> `uploadAssets` -> `uploadCandyMachineItems` -> `uploadFiles` -> `umi.uploader.upload` -> provider implementations.
- Collection uploads also call `uploadFiles` (see `createCollection`).
- Insertion points: wrap/extend `uploadFiles`, or add a middleware between `uploadCandyMachineItems` and `uploadFiles` to check and reuse existing URIs.

**Files examined**
- `src/commands/cm/create.ts` — wizard orchestration and high-level steps (`runWizard`, `uploadAssets`, `createCollection`, `createCandyMachine`).
- `src/lib/cm/prompts/createCandyMachineWizardPrompt.ts` — interactive prompts that build the `cm-config` and assets selection.
- `src/lib/cm/uploadItems.ts` — high-level upload sequence: images -> update JSON -> JSON upload; updates `assetCache` with `imageUri` and `jsonUri`.
- `src/lib/uploader/uploadFiles.ts` — batching + per-file retry logic; calls `umi.uploader.upload([file])`.
- `src/lib/cm/insertItems.ts` — validates uploads (`validateCacheUploads`) then uses `addConfigLines` to insert items on-chain.
- `src/lib/cm/validateCacheUploads.ts` — ensures `imageUri` and `jsonUri` are present before insertion.
- `src/lib/cm/cm-utils.ts` — filesystem helpers and `asset-cache.json` read/write helpers.

**High-level behavior (text)**
1. User runs `mplx cm create --wizard` which triggers `CmCreate.runWizard()`.
2. `createCandyMachinePrompt` collects project directory, validates `assets/`, builds `cm-config` and determines JSON/image files.
3. `runWizard` constructs an initial `assetCache` mapping indices -> { name, image, json, loaded: false }.
4. `uploadAssets` checks for `asset-cache.json`. If missing or incomplete it writes initial cache then calls `uploadCandyMachineItems(umi, assetCache, candyMachineDir, handler)`.
5. `uploadCandyMachineItems`:
   - Computes items needing image upload, calls `uploadFiles(umi, imagePaths, progressCb)`
   - Writes image URIs back into `assetCache` and updates local JSON files on disk with `image` URIs
   - Calls `uploadFiles(umi, jsonPaths, progressCb)` to upload metadata JSONs
   - Writes JSON URIs back into `assetCache` and returns the updated cache
6. `uploadFiles` batches files (BATCH_SIZE = 50), reads file buffers, wraps into `createGenericFile(...)` and calls `umi.uploader.upload` which uses configured storage provider implementations under `src/lib/uploader/uploadProviders`.
7. `runWizard` then creates collection (which also uses `uploadFiles`) and `createCandyMachine`, then calls `insertItems` to add config lines on-chain.

**Call Graph (compact)**

```mermaid
flowchart TD
  A[User: mplx cm create --wizard]
  A --> B[`src/commands/cm/create.ts::runWizard()`]
  B --> C[`createCandyMachinePrompt()`]
  B --> D[`uploadAssets()`]
  D --> E[`src/lib/cm/uploadItems.ts::uploadCandyMachineItems()`]
  E --> F[`src/lib/uploader/uploadFiles.ts::uploadFiles()`]
  F --> G[`umi.uploader.upload()`]
  G --> H[Storage Providers (`uploadProviders/*`) (irys, turbo, cascade)]
  B --> I[`createCollection()`]
  I --> F
  B --> J[`createCandyMachine()`]
  B --> K[`insertItems()`]
  K --> L[`validateCacheUploads()`]
  K --> M[`addConfigLines()` -> on-chain txs]
  
  style A fill:#f9f,stroke:#333,stroke-width:1px
  style B fill:#bbf,stroke:#333
  style E fill:#bfb,stroke:#333
  style F fill:#fbf,stroke:#333
  style G fill:#ffd,stroke:#333
  style H fill:#eee,stroke:#333
```

**Detailed call descriptions**
- `runWizard()` (commands/cm/create.ts): orchestrates discovery, writes `cm-config.json`, builds `assetCache`, and calls `uploadAssets`, `createCollection`, `createCandyMachine`, `insertItems` in sequence.
- `uploadAssets()` (create.ts): checks for existing `asset-cache.json`, reuses if complete, otherwise saves initial cache and calls `uploadCandyMachineItems`.
- `uploadCandyMachineItems()` (lib/cm/uploadItems.ts): determines which images and jsons need uploading, calls `uploadFiles` for each phase, updates cache and on-disk JSONs with the returned URIs.
- `uploadFiles()` (lib/uploader/uploadFiles.ts): does batching (BATCH_SIZE=50), per-file retries, and delegates to `umi.uploader.upload` which uses configured storage provider implementations under `src/lib/uploader/uploadProviders`.
- `insertItems()` (lib/cm/insertItems.ts): validates cache, builds config lines and transactions from remaining items, batches into transactions and sends them via `umi` helpers.

**Where to insert an upload-optimization shim**
Option A (recommended): Middleware inside `uploadFiles()`
- Rationale: All upload traffic (images and JSONs, including collection uploads) funnels through `uploadFiles`. A dedupe layer here can:
  - Compute content hashes (e.g., SHA-256) of file buffers before creating `createGenericFile`
  - Query a dedupe index or the storage provider (if provider offers idempotent upload or lookup) for existing URIs
  - If found, return the existing URI and skip `umi.uploader.upload` for that file
  - On new uploads, record the mapping (hash -> uri) into a local cache (e.g., sidecar file `.upload-dedupe.json`) or into a shared index service
- Implementation surface: add optional `uploaderOptions` param to `uploadFiles(umi, filePaths, onProgress, opts?)` or inject a wrapper function that runs before `umi.uploader.upload`.

Option B: Higher-level shim in `uploadCandyMachineItems()`
- Rationale: This can dedupe at the asset level (images + json pairs) and also avoid writing/patching JSON files when the image already exists remotely.
- Tradeoffs: slightly more complex because you must compute hash for both image and the updated JSON (after inserting image URIs) and ensure you map the JSON to the correct uploaded image URI.

Option C: Provider-side dedupe
- If the configured storage provider (e.g., cascade, turbo) supports idempotent uploads by content hash, prefer using provider APIs to dedupe. The shim would then primarily compute content hash and call a provider lookup API before upload.

**Practical integration plan (next steps)**
1. Add a simple dedupe index read/write utility under `src/lib/uploader/dedupeIndex.ts` that maps file hash -> uri. (Low risk, local fallback when providers don't expose lookup.)
2. Extend `uploadFiles()` signature to accept an `opts?: { dedupe?: boolean, dedupeIndexPath?: string }`. Default `dedupe=true` for CM flows.
3. In `uploadFiles()`, before calling `umi.uploader.upload`, compute file hash and consult the dedupe index; if found, set `uploadResults[i] = { uri: existing }` and skip provider call.
4. On successful `umi.uploader.upload`, record created URIs in the dedupe index for future runs.
5. Update `uploadCandyMachineItems()` to optionally consult the index for JSON uploads (the JSON should be hashed after inserting the resolved image URI so identical metadata reuse is possible).
6. Add tests for the dedupe index and an opt-in flag for the wizard.

**Edge cases & constraints**
- Local index consistency: If multiple users/machines upload to same Arweave storage independently, local index won't know about remote uploads; consider adding a provider lookup API when available.
- JSON dedupe requires hashing post-image-substitution — ensure atomic handling so the image URIs used to compute the hash match the final uploaded JSON metadata.
- Backwards compatibility: keep `uploadFiles()` behavior identical when `opts.dedupe` is false.

**Suggested code touchpoints**
- `src/lib/uploader/uploadFiles.ts` — main dedupe insertion point (primary)
- `src/lib/cm/uploadItems.ts` — ensure JSON hash is computed after image URI injection (secondary)
- `src/lib/uploader/uploadProviders/*` — optional: add provider lookup API if supported
- `src/commands/cm/create.ts::uploadAssets()` — pass dedupe option when calling `uploadCandyMachineItems`

**Appendix: Mermaid call graph source**
The diagram above is included in this file as Mermaid; render it with any Mermaid-capable renderer.

-- End of analysis --
