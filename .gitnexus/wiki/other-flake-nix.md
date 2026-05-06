# Other — flake.nix

# flake.nix — Nix Flake Development Environment

This module defines a **Nix flake** that provides a reproducible development shell for the ghost-datatype-support-lib project. It uses nixpkgs/nixos-unstable to ensure access to the latest package versions.

## Overview

The flake creates a `devShell` — a self-contained development environment with all necessary tools pre-installed. When developers enter this shell via `nix develop`, they get a consistent toolchain regardless of their host system.

## Key Components

### Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-unstable` | Package repository (unstable branch for latest versions) |
| `flake-utils` | `github:numtide/flake-utils` | Utility library for multi-system flake support |

### Outputs

The flake outputs a `devShells` attribute containing a default shell definition. The `eachDefaultSystem` helper generates shells for:
- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

### Build Inputs

The following packages are included in the development environment:

| Package | Purpose |
|---------|---------|
| `nodejs` | JavaScript runtime |
| `pnpm` | Fast, disk space-efficient package manager |
| `fnm` | Fast Node Manager — version management for Node.js |
| `act` | Run GitHub Actions locally |
| `just` | Command runner (like make, but simpler) |
| `git` | Version control |
| `docker` | Container runtime |
| `sqlite` | SQLite CLI tools |
| `coreutils` | GNU core utilities |
| `nushell` | Modern shell alternative |
| `mise` | Dev tool manager (like asdf) |
| `dependabot-cli` | Dependabot command-line tool |
| `codeql` | Code analysis engine |
| `dependabot` | Automated dependency updates |

### Shell Hook

On shell startup, the following executes automatically:

1. A welcome message identifying the system architecture
2. Runs `just run` — executes the project's default task (defined in `justfile`)
3. Displays availability status for `act` and `fnm`

## Usage

```bash
# Enter the development shell
nix develop

# Or use the flake directly from any path
nix develop github:username/ghost-datatype-support-lib
```

## Configuration Notes

- **Unfree packages enabled**: The flake explicitly allows unfree packages via `config.allowUnfree = true` because `codeql` is proprietary software. This is required to avoid evaluation errors.
- **System-specific**: The shell is built for the host system automatically via `flake-utils.lib.eachDefaultSystem`.

## Integration with Project

This flake is the entry point for all development work. It delegates actual project execution to the `justfile`, which defines tasks like building, testing, and running the project.