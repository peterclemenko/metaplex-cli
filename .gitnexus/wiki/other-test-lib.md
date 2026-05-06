# Other — test-lib

# deserializeInstruction Test Suite

## Overview

This test module (`test/lib/deserializeInstruction.test.ts`) validates the `serializeInstruction` and `deserializeInstruction` functions located in `src/lib/execute/deserializeInstruction.js`. These functions handle binary encoding and decoding of Solana instructions for transmission or storage.

## What is Being Tested

The test suite verifies roundtrip serialization/deserialization of Solana `Instruction` objects. A successful roundtrip means:

```
Instruction → serializeInstruction → Base64 string → deserializeInstruction → Instruction
```

The deserialized instruction must match the original exactly.

## Test Cases

### 1. Simple Instruction (No Accounts, No Data)

Tests the minimal instruction structure:

```typescript
{
    programId: SYSTEM_PROGRAM,
    keys: [],
    data: new Uint8Array(0),
}
```

This verifies the serialization format handles empty collections correctly.

### 2. Instruction with Accounts and Data

Tests a fully populated instruction with:
- Two accounts with different permissions
- Non-empty byte data

Verifies that account metadata (pubkey, isSigner, isWritable) and arbitrary byte data are preserved exactly.

### 3. Signer-Only (Non-Writable) Account

Tests an account where `isSigner: true` but `isWritable: false`. This is common for authority accounts that must sign but cannot be modified.

### 4. Writable Non-Signer Account

Tests an account where `isSigner: false` but `isWritable: true`. This represents data accounts that can be modified but don't require a signature.

### 5. Error: Data Too Short

Verifies that deserialization throws an appropriate error when the encoded data is truncated and cannot contain a valid instruction.

### 6. Error: Truncated Account Data

Tests the boundary case where the account count indicates accounts exist, but the data ends before all account metadata is read. The error message should indicate "Unexpected end of data".

## Serialization Format

Based on the test cases, the binary format appears to be:

| Field | Size | Description |
|-------|------|-------------|
| Program ID | 32 bytes | Public key of the program |
| Account count | 2 bytes (LE) | Number of accounts |
| Accounts | Variable | For each account: 32-byte pubkey + 1 byte flags |
| Data length | 4 bytes (LE) | Size of instruction data |
| Data | Variable | Raw byte array |

The serialized output is encoded as Base64.

## Relationship to Source Module

The tested functions live in `src/lib/execute/deserializeInstruction.js`. This test file is the contract that defines expected behavior for those functions. When modifying the serialization format, update these tests accordingly.

## Running the Tests

```bash
npm test -- --grep "deserializeInstruction"
```

Or run the specific file:

```bash
npx mocha test/lib/deserializeInstruction.test.ts
```