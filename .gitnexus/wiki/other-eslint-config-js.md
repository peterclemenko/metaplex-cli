# Other — eslint.config.js

# ESLint Configuration

## Overview

This file (`eslint.config.js`) defines the project's ESLint rules. ESLint statically analyzes JavaScript code to identify problematic patterns and enforce consistent coding conventions. This configuration applies to all JavaScript files in the project.

## Configuration Structure

The config uses ESLint's flat configuration format (ESLint v9+), exporting an array with a single configuration object:

```javascript
export default [
  {
    rules: { /* rule definitions */ },
  },
];
```

## Enabled Rules

### `prefer-const`: `"error"`

Enforces the use of `const` declarations for variables that are never reassigned. Using `let` for constant values is flagged as an error.

```javascript
// Bad
let count = 0;

// Good
const count = 0;
```

### `semi`: `"error"`

Requires semicolons at the end of statements. This prevents Automatic Semicolon Insertion (ASI)-related bugs.

```javascript
// Bad
const x = 1

// Good
const x = 1;
```

### `sort-objects`: `0`

**Disabled** (level 0). This rule would enforce alphabetical sorting of object keys, but it's turned off to allow developers to organize object properties semantically.

### `camelcase`: `0`

**Disabled** (level 0). This rule would require identifiers to use camelCase, but it's turned off to allow flexibility for:
- Snake_case variables from external APIs
- Constants that benefit from UPPER_SNAKE_CASE
- Property names that must match external schemas

## Rule Severity Levels

| Level | Value | Meaning |
|-------|-------|---------|
| Off   | `0`   | Rule is disabled |
| Warn  | `1`   | Rule triggers a warning but doesn't fail the build |
| Error | `2`   | Rule triggers an error and fails the build |

## Extending the Configuration

To add new rules or modify existing ones, edit the `rules` object:

```javascript
export default [
  {
    rules: {
      'prefer-const': 'error',
      semi: 'error',
      'sort-objects': 0,
      camelcase: 0,
      // Add new rules here
      'no-unused-vars': 'warn',
      'eqeqeq': 'error',
    },
  },
];
```

To apply different rules to specific files, add more configuration objects to the array with `files` or `ignores` patterns:

```javascript
export default [
  {
    files: ['**/*.js'],
    rules: { /* general JS rules */ },
  },
  {
    files: ['tests/**/*.js'],
    rules: { /* test-specific rules */ },
  },
];
```

## Integration

ESLint runs as part of the development workflow. When triggered, ESLint reads this configuration file and applies the defined rules to JavaScript files in the project.

This is a minimal configuration suitable for small projects or as a starting point. As the project grows, consider:
- Adding environment-specific configurations
- Integrating with Prettier for formatting (ESLint handles code quality, Prettier handles code style)
- Using shareable configs to share rule sets across projects