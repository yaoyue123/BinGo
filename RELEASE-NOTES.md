# BinGo Release Notes

## v4.1.0 (2025-01-29)

### Restructuring

**Restructured to match superpowers reference architecture**

This release reorganizes the BinGo project structure to align with the superpowers framework reference, improving consistency and maintainability.

### Changes

**New Directories:**
- `agents/` - Agent definitions (code-reviewer.md for binary analysis)
- `commands/` - Slash commands (/analyze-binary, /build-cpg)
- `docs/plans/` - Design and implementation documentation
- `docs/testing.md` - Comprehensive testing guide
- `hooks/` - Session start hooks for context injection
- `lib/` - Core library utilities (bingo-core.js)
- `.claude-plugin/` - Standard plugin configuration

**Reorganized:**
- All 9 skills moved from root to `skills/` directory
- Documentation moved: QUICKSTART.md, TROUBLESHOOTING.md, MIGRATION.md → `docs/`
- Test structure enhanced with claude-code/, explicit-skill-requests/, skill-triggering/

**New Files:**
- `agents/code-reviewer.md` - Binary security code reviewer agent
- `commands/analyze-binary.md` - Slash command for binary analysis
- `commands/build-cpg.md` - Slash command for CPG building
- `hooks/hooks.json` - Hook configuration
- `hooks/session-start.sh` - Session start hook script
- `hooks/run-hook.cmd` - Windows compatibility wrapper
- `lib/bingo-core.js` - Core utilities (config, Joern detection)
- `docs/plans/2025-01-29-bingo-restructure-design.md` - Design document
- `docs/plans/2025-01-29-bingo-restructure-implementation.md` - Implementation plan
- `docs/testing.md` - Testing documentation
- `.claude-plugin/plugin.json` - Plugin metadata
- `.claude-plugin/marketplace.json` - Marketplace configuration
- `RELEASE-NOTES.md` - This file

**Removed:**
- `CLEANUP_COMPLETE.md` - Development artifact
- `MANIFEST.md` - Replaced by `.claude-plugin/` configuration

### Breaking Changes

**Skill Locations:**
- All skills moved from root level to `skills/` directory
- Update skill references to use namespace: `bingo:skill-name`

**Documentation Paths:**
- `QUICKSTART.md` → `docs/QUICKSTART.md`
- `TROUBLESHOOTING.md` → `docs/TROUBLESHOOTING.md`
- `MIGRATION.md` → `docs/MIGRATION.md`

### Migration

See `docs/MIGRATION.md` for detailed migration instructions.

**Script Paths Unchanged:**
All user-facing script paths remain the same:
- `./bingo/scripts/analyze.sh` (unchanged)
- `./bingo/scripts/binary_info.sh` (unchanged)

### Compatibility

- CLI scripts: No changes to user-facing script paths
- Configuration: `bingo-config.json` format unchanged
- Output structure: Analysis output format unchanged
- Skills: All 9 skills preserved with same functionality

---

## v4.0.0 (2025-01-XX)

### Initial Release

**Rebrand from VulRe to BinGo**

- Rebranded from VulRe to BinGo
- 9 modular skills for binary vulnerability analysis
- STRICT audit with 5 mandatory checks
- Joern-only CPG construction (no alternatives)
- Complete automation pipeline
- 5-minute quick start guide

### Features

**Skills:**
- `binary-analysis` - Fast metadata extraction
- `cpg-construction` - Joern CPG building
- `source-sink-discovery` - Source/sink identification
- `taint-analysis` - Joern taint tracking
- `vuln-audit` - STRICT 5-check audit
- `vuln-reporting` - Detailed reports with PoCs
- `binary-vuln-assessment` - Main orchestrator
- `joern-automation` - Joern installation and management
- `binary-poc-generator` - Proof-of-concept generation

**Vulnerabilities Detected:**
- Buffer Overflow (strcpy, strcat, sprintf, memcpy)
- Format String (printf family)
- Command Injection (system, execve)
- Integer Overflow

### Documentation

- QUICKSTART.md - 5-minute getting started guide
- TROUBLESHOOTING.md - Common issues and solutions
- MIGRATION.md - Migration from VulRe to BinGo
- references/ - Technical documentation (CPG, taint, sources, sinks)

---

## Future Releases

### Planned Features

- [ ] Additional vulnerability patterns (race conditions, use-after-free)
- [ ] Enhanced CPG validation with quality metrics
- [ ] Parallel analysis support for multiple binaries
- [ ] Integration with additional decompilers
- [ ] Web-based report viewer
- [ ] CI/CD integration guides

### Known Issues

- Joern installation requires manual setup (automated installation planned)
- Large binaries (>100MB) may require increased JVM heap
- Some stripped binaries have limited analysis results

---

## Contributing

Contributions welcome! Please see CONTRIBUTING.md for guidelines.

## Support

- **Issues:** https://github.com/your-org/bingo/issues
- **Documentation:** See `docs/` directory
- **Joern:** https://joern.io

---

**BinGo v4.1.0** - Binary vulnerability mining made easy

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
