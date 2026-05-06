# Other — CLAUDE.md

# CLAUDE.md — Claude Code Guidance File

## Overview

`CLAUDE.md` is a special metadata file that provides operational guidance to Claude Code (claude.ai/code), an AI assistant that helps developers work with the codebase. This file serves as the primary configuration document for AI-assisted development, instructing the AI on project conventions, available commands, architecture patterns, and development workflows.

Unlike traditional documentation that serves human developers, CLAUDE.md is specifically designed to be read and followed by an AI assistant. It ensures the AI understands project-specific context before making changes, reducing errors and maintaining consistency with project standards.

## File Location and Naming

The file must be named exactly `CLAUDE.md` and placed at the repository root. Claude Code automatically detects and reads this file when working in the project directory. The filename is case-sensitive and must match exactly.

## How Claude Code Uses This File

When Claude Code initializes in the repository, it:

1. **Reads the entire file** to understand project context
2. **References the development commands** section for build, test, and lint operations
3. **Consults architecture overview** when explaining code or making structural changes
4. **Follows development guidelines** when writing new code or modifying existing patterns
5. **Uses GitNexus integration** for impact analysis before making changes

The AI does not execute this file—it reads it as guidance and applies the principles when helping with development tasks.

## Key Sections

### Project Overview

The opening section identifies the project as the Metaplex CLI (`mplx`), a command-line interface for the Metaplex ecosystem on Solana. This establishes the domain context (Solana blockchain, digital assets, NFTs) that informs all subsequent guidance