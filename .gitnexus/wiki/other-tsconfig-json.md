# Other — tsconfig.json

# tsconfig.json — TypeScript Configuration

This file configures the TypeScript compiler for the project. It defines how TypeScript source files are compiled, what output format is generated, and what type-checking rules are enforced.

## Overview

The configuration targets **Node.js** with **ES2022** as the JavaScript output version. It uses strict type checking, generates declaration files for type consumers, and outputs compiled JavaScript to a `dist` directory.

## Compiler Options

### Module System

| Option | Value | Effect |
|--------|-------|--------|
| `module` | `Node16` | Outputs ES modules compatible with Node.js 16+ |
| `moduleResolution` | `node16` | Uses Node.js 16's native module resolution algorithm |
| `target` | `es2022` | Compiles to ES2022 JavaScript syntax |

This setup produces modern ES modules that work natively in Node.js without requiring bundlers. The `Node16` module format corresponds to the `exports` field in `package.json` and native ESM support.

### Type Checking

| Option | Value | Effect |
|--------|-------|--------|
| `strict` | `true` | Enables all strict type-checking options |
| `skipLibCheck` | `true` | Skips type checking of `@types` and declaration files |
| `declaration` | `true` | Generates `.d.ts` files alongside compiled output |

The `strict: true` setting enables options like `noImplicitAny`, `strictNullChecks`, `strictPropertyInitialization`, and others. This enforces rigorous type safety throughout the codebase.

Setting `skipLibCheck: true` improves build performance by skipping type validation of third-party type definitions, which is safe because those files are typically already validated by their maintainers.

### Interoperability

| Option | Value | Effect |
|--------|-------|--------|
| `esModuleInterop` | `true` | Allows default imports from CommonJS modules |
| `allowSyntheticDefaultImports` | `true` | Allows synthetic default exports for modules without them |

These settings ensure compatibility when importing CommonJS modules (including many npm packages) into an ESM codebase. They prevent workarounds like `import * as foo = require('foo')`.

### Output Configuration

| Option | Value | Effect |
|--------|-------|--------|
| `outDir` | `dist` | Compiled JavaScript output directory |
| `rootDir` | `src` | Source root directory |
| `composite` | `true` | Enables project references for incremental builds |

The `composite: true` option marks this as a referenceable project for TypeScript project references, enabling faster incremental builds when using monorepo structures or multi-package setups.

## File Inclusion

```json
"include": ["./src/**/*"]
```

All TypeScript files (`.ts`, `.tsx`) within the `src` directory and its subdirectories are included in compilation. Files outside `src` (such as tests in `__tests__` or test fixtures) are excluded unless explicitly added to `include` or referenced separately.

## ts-node Configuration

```json
"ts-node": {
  "esm": true
}
```

This configures [ts-node](https://typestrong.org/ts-node/) to run TypeScript files directly in an ESM-compatible manner. When using `ts-node` to execute source files (useful during development), it will treat them as ES modules rather than CommonJS.

## Build Output

Given this configuration, running `tsc` produces:

```
src/
  └── (your source files)
dist/
  └── (compiled .js files)
  └── (generated .d.ts files)
```

The directory structure under `dist` mirrors the structure under `src`, since `rootDir` is set to `src`.

## Implications for Developers

- **All code must pass strict type checking** — expect compile errors for implicit `any` types, unhandled null values, and similar issues
- **ESM-only output** — the compiled code uses `import`/`export` syntax; CommonJS `require()` is not used
- **Declaration files are generated** — other projects can consume this package's types directly
- **Node.js 16+ required** — the runtime must support ES2022 features and native ESM