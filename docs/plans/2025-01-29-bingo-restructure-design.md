# BinGo Restructuring Design Document

**Date:** 2025-01-29
**Version:** 4.1.0
**Status:** Approved

## Overview

This document describes the design for restructuring the BinGo project to align with the superpowers reference architecture. The restructuring improves consistency, maintainability, and plugin compatibility while preserving all BinGo-specific functionality.

## Motivation

### Problems with Current Structure

1. **Skills at root level**: 9 skill directories mixed with other files make navigation difficult
2. **Missing standard directories**: No agents/, commands/, hooks/, lib/ directories
3. **Scattered documentation**: Docs mixed with code files
4. **No plugin configuration**: Uses MANIFEST.md instead of standard .claude-plugin/
5. **Inconsistent test structure**: Tests don't follow superpowers patterns

### Benefits of Restructuring

1. **Improved discoverability**: All skills under skills/ directory
2. **Plugin compatibility**: Standard .claude-plugin/ configuration
3. **Better organization**: Separate concerns with dedicated directories
4. **Enhanced testing**: Test infrastructure matches superpowers patterns
5. **Documentation clarity**: Design docs in docs/plans/, guides in docs/

## Design Decisions

### 1. Directory Structure

```
bingo/
├── .claude-plugin/          # Plugin metadata (NEW)
├── agents/                  # Agent definitions (NEW)
├── assets/                  # BinGo-specific patterns (PRESERVED)
├── commands/                # Slash commands (NEW)
├── docs/
│   ├── plans/              # Design/implementation docs (NEW)
│   ├── QUICKSTART.md       # Moved from root
│   ├── TROUBLESHOOTING.md  # Moved from root
│   ├── MIGRATION.md        # Moved from root
│   └── testing.md          # NEW
├── hooks/                   # Hook configuration (NEW)
├── lib/                     # Core utilities (NEW)
├── references/              # BinGo-specific technical docs (PRESERVED)
├── scripts/                 # BinGo-specific automation (PRESERVED)
├── skills/                  # ALL skills (NEW LOCATION)
├── templates/               # BinGo-specific report templates (PRESERVED)
└── tests/                   # Restructured with new subdirectories
```

### 2. Skill Organization

All 9 skills moved from root to `skills/`:
- binary-analysis
- cpg-construction
- source-sink-discovery
- taint-analysis
- vuln-audit
- vuln-reporting
- binary-vuln-assessment
- joern-automation
- binary-poc-generator

### 3. Preserved BinGo-Specific Content

The following directories remain unchanged as they contain domain-specific content:
- `assets/patterns/` - Custom Joern patterns
- `references/` - Technical documentation (CPG, taint, sources, sinks)
- `scripts/` - All automation scripts
- `templates/` - Report templates

### 4. New Components

#### Agents
- `agents/code-reviewer.md` - Binary analysis specialized code reviewer

#### Commands
- `commands/analyze-binary.md` - Slash command for binary vulnerability analysis
- `commands/build-cpg.md` - Slash command for CPG building

#### Hooks
- `hooks/hooks.json` - Hook configuration
- `hooks/session-start.sh` - Injects Bingo context on session start
- `hooks/run-hook.cmd` - Windows compatibility wrapper

#### Library
- `lib/bingo-core.js` - Core utilities (config loading, Joern path finding)

#### Documentation
- `docs/plans/2025-01-29-bingo-restructure-design.md` - This document
- `docs/plans/2025-01-29-bingo-restructure-implementation.md` - Implementation steps
- `docs/testing.md` - Testing guide

### 5. File Reference Updates

The following files require path updates after restructuring:
1. `SKILL.md` (root) - Update all skill references
2. `README.md` - Update documentation paths
3. `skills/binary-vuln-assessment/SKILL.md` - Update skill orchestration
4. `skills/*/SKILL.md` - Update cross-references
5. `docs/MIGRATION.md` - Update migration paths

## Migration Path

### For Users

**Script paths unchanged:**
```bash
# These paths remain the same
./bingo/scripts/analyze.sh binary.elf ./output
./bingo/scripts/binary_info.sh binary.elf
```

**Skill invocation format:**
```bash
# Old implicit format
Use binary-analysis skill

# New explicit namespace (preferred)
Use bingo:binary-analysis skill
```

### For Developers

**Internal references:**
```bash
# Old
See: binary-analysis/SKILL.md

# New
See: skills/binary-analysis/SKILL.md
```

## Compatibility

### Backward Compatibility

1. **CLI scripts**: All user-facing script paths unchanged
2. **Configuration**: bingo-config.json format unchanged
3. **Output structure**: Analysis output format unchanged

### Breaking Changes

1. **Skill locations**: Skills moved from root to skills/
2. **Documentation paths**: Some docs moved to docs/
3. **Removed files**: CLEANUP_COMPLETE.md, MANIFEST.md removed

## Testing Strategy

### Unit Tests
- Validate lib/bingo-core.js functions
- Test config loading with various inputs
- Test Joern path detection logic

### Integration Tests
- Test skill invocation after restructuring
- Verify all 9 skills load correctly
- Test hooks execute properly

### End-to-End Tests
- Run full binary analysis pipeline
- Verify output structure unchanged
- Test all slash commands

## Timeline

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Directory creation | Create new dirs, move skills | 1 hour |
| 2. File creation | Create agents, commands, hooks, lib | 2 hours |
| 3. Documentation | Create docs, update references | 2 hours |
| 4. Testing | Verify all functionality | 2 hours |
| 5. Cleanup | Remove old files, final verification | 1 hour |

## Success Criteria

1. All 9 skills exist under skills/ with correct paths
2. All new directories and files created
3. BinGo-specific content preserved (scripts, references, assets)
4. All file references updated consistently
5. Tests pass with new structure
6. Documentation reflects new paths

## References

- Superpowers reference structure: `../superpowers/`
- Original BinGo documentation: `docs/QUICKSTART.md`, `docs/TROUBLESHOOTING.md`
- Implementation plan: `2025-01-29-bingo-restructure-implementation.md`
