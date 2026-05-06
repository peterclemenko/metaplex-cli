# Other — AGENTS.md

# GitNexus — Code Intelligence Configuration

This module is a developer-facing reference for GitNexus, a code intelligence platform that indexes the codebase and provides tools for understanding code relationships, assessing change impact, and navigating safely.

## Purpose

AGENTS.md serves as an always-available guide for developers working on the metaplex-cli project. It defines mandatory practices for safe code modification:

- **Impact analysis** must run before editing any symbol
- **Change detection** must run before committing
- **Risk warnings** must be heeded for HIGH or CRITICAL changes

## Project Metadata

| Metric | Value |
|--------|-------|
| Project | metaplex-cli |
| Symbols indexed | 10,239 |
| Relationships indexed | 13,988 |
| Execution flows | 116 |

These metrics indicate the scale of code that GitNexus tracks. The relationship count (exceeding symbol count) reflects the dense interconnectedness of the codebase.

## Mandatory Practices

### Before Any Edit: Impact Analysis

```bash
gitnexus_impact({target: "symbolName", direction: "upstream"})
```

This tool returns:
- **Direct callers** — code that immediately depends on the target
- **Affected processes** — execution flows that pass through the symbol
- **Risk level** — one of LOW, MEDIUM, HIGH, or CRITICAL

The tool must be consulted before modifying any function, class, or method. The risk assessment must be reported to the user before proceeding.

### Before Any Commit: Change Detection

```bash
gitnexus_detect_changes()
```

Verifies that modifications affect only the intended symbols and execution flows. This prevents unintended side effects from spreading through the call graph.

### Risk Response

| Risk Level | Required Action |
|------------|-----------------|
| LOW / MEDIUM | Proceed with normal caution |
| HIGH / CRITICAL | **Must warn the user** before proceeding |

### Querying the Codebase

For exploration rather than modification:

```bash
gitnexus_query({query: "concept"})
```

Returns execution flows grouped by process, ranked by relevance. Use this instead of grep to find how concepts actually execute in the codebase.

For full context on a specific symbol:

```bash
gitnexus_context({name: "symbolName"})
```

Returns callers, callees, and all execution flows the symbol participates in.

## Resource References

The file references additional resources at fixed URIs:

| URI | Purpose |
|-----|---------|
| `gitnexus://repo/metaplex-cli/context` | Codebase overview, index freshness check |
| `gitnexus://repo/metaplex-cli/clusters` | All functional areas |
| `gitnexus://repo/metaplex-cli/processes` | All execution flows |
| `gitnexus://repo/metaplex-cli/process/{name}` | Step-by-step execution trace |

## CLI Skill References

The file maps tasks to skill files located in `.claude/skills/gitnexus/`:

| Task | Skill File |
|------|------------|
| Understanding architecture | `gitnexus-exploring/SKILL.md` |
| Assessing blast radius | `gitnexus-impact-analysis/SKILL.md` |
| Debugging failures | `gitnexus-debugging/SKILL.md` |
| Refactoring (rename, extract, split) | `gitnexus-refactoring/SKILL.md` |
| Tool reference and schema | `gitnexus-guide/SKILL.md` |
| Index and CLI commands | `gitnexus-cli/SKILL.md` |

## Index Freshness

The note about running `npx gitnexus analyze` indicates that the code intelligence is only useful when the index is current. If tools warn that the index is stale, re-running analysis synchronizes the graph with the current codebase state.

## Relationship to Execution Flows

Despite the project having 116 execution flows, this module shows no execution flows itself. AGENTS.md is a configuration and reference document, not code that executes within the application's runtime. Its role is static guidance—providing the rules and resource pointers that developers consult while working on the actual codebase.