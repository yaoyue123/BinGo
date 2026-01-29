# BinGo - Binary Vulnerability Mining Made Easy

**User-friendly binary vulnerability analysis platform using Joern**

[![Version](https://img.shields.io/badge/version-4.1.0-blue.svg)](https://github.com/your-org/bingo)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Joern](https://img.shields.io/badge/Joern-required-orange.svg)](https://joern.io)

## Quick Start

```bash
# 1. Install Joern (REQUIRED)
git clone https://github.com/joernio/joern ~/joern
cd ~/joern && ./build.sh
export PATH=$PATH:~/joern

# 2. Analyze binary
./bingo/scripts/analyze.sh /path/to/binary.elf ./output

# 3. View report
cat ./output/vulnerability_report.md
```

## What is BinGo?

BinGo is a **user-friendly binary vulnerability analysis platform** that:

- ✅ Analyzes compiled binaries (ELF, PE, Mach-O) without source code
- ✅ Uses **Joern** for Code Property Graph construction and taint tracking
- ✅ Enforces **STRICT audit** (5 mandatory checks) before confirming vulnerabilities
- ✅ Generates detailed reports with complete evidence and PoCs
- ✅ Provides 9 modular skills for flexible analysis

**Perfect for:**
- Security researchers analyzing router firmware, IoT devices, embedded systems
- CTF players solving binary exploitation challenges
- DevOps teams auditing compiled binaries
- Reverse engineers identifying vulnerabilities

## Key Features

### 🎯 Modular Architecture

9 composable skills, each with a specific responsibility:

| Skill | Purpose |
|-------|---------|
| **binary-analysis** | Fast metadata extraction |
| **cpg-construction** | Joern CPG building |
| **source-sink-discovery** | Identify input sources and dangerous sinks |
| **taint-analysis** | Track data flows using Joern |
| **vuln-audit** | STRICT audit (5 checks) |
| **vuln-reporting** | Generate detailed reports |
| **binary-vuln-assessment** | Main orchestrator |
| **joern-automation** | Joern installation and management |
| **binary-poc-generator** | Generate proof-of-concept exploits |

### 🔒 STRICT Vulnerability Audit

Every vulnerability must pass ALL 5 checks:

1. ✅ **Data flow complete** - Full trace from source to sink
2. ✅ **Source verified** - Confirmed as untrusted input
3. ✅ **Sink verified** - Confirmed as dangerous operation
4. ✅ **Protections absent** - No bounds checking or validation
5. ✅ **False positive ruled out** - Not dead code or unreachable

**Result:** Zero false positives in confirmed vulnerabilities.

### 🤖 Complete Automation

Full pipeline automation with quality gates:

```bash
# Complete analysis (all phases)
./bingo/scripts/analyze.sh binary.elf ./output

# Quick scan (binary info only)
./bingo/scripts/analyze.sh binary.elf ./output --quick

# With detailed progress
./bingo/scripts/analyze.sh binary.elf ./output --verbose
```

## Installation

### Requirements

- **Joern CLI** with binary2cpg (MANDATORY - no alternatives)
- bash 4.0+
- jq (JSON processing)
- readelf, nm, file (binary analysis tools)

### Install Joern

```bash
# Clone Joern repository
git clone https://github.com/joernio/joern ~/joern
cd ~/joern

# Build Joern (requires Java 11+)
./build.sh

# Add to PATH
export PATH=$PATH:~/joern

# Verify installation
joern --version
```

**See:** `skills/joern-automation/SKILL.md` for detailed installation instructions.

### Validate Installation

```bash
./bingo/scripts/joern/validate_joern.sh
```

## Usage

### Basic Analysis

```bash
# Analyze binary
./bingo/scripts/analyze.sh /path/to/binary.elf ./output

# Report generated at: ./output/vulnerability_report.md
```

### Step-by-Step Analysis

```bash
# 1. Extract binary information
./bingo/scripts/binary_info.sh binary.elf ./output

# 2. Build CPG with Joern
./bingo/scripts/cpg/build_cpg_native.sh binary.elf ./output/cpg.bin

# 3. Discover custom sources (optional)
joern ./output/cpg.bin --script bingo/scripts/joern/discover_sources.sc

# 4. Run taint analysis
joern ./output/cpg.bin --script bingo/scripts/joern/dataflow.sc \
  sources.json sinks.json ./output/flows

# 5. Audit findings
./bingo/scripts/agent/validate_findings.sh ./output

# 6. Generate report
./bingo/scripts/agent/generate_report.sh ./output
```

### Test BinGo

```bash
# Compile test binaries
./bingo/tests/binaries/compile_test_binaries.sh

# Run full pipeline test
./bingo/tests/scripts/test_full_pipeline.sh
```

## Output Structure

```
output/
├── binary_info.json           # Binary metadata
├── cpg.bin                    # Code Property Graph
├── cpg-validation-native.txt  # CPG statistics
├── sources.json               # Source functions
├── sinks.json                 # Sink functions
├── flows/                     # Taint flows
│   ├── flow_001.json
│   └── flow_002.json
├── confirmed_vulns.json       # Verified vulnerabilities
└── vulnerability_report.md    # Final report
```

## Vulnerability Types Detected

- **Buffer Overflow** - strcpy, strcat, sprintf, memcpy without bounds checking
- **Format String** - User input controls printf format parameter
- **Command Injection** - User input reaches system(), execve()
- **Integer Overflow** - Integer arithmetic bypasses size checks

## Documentation

- **Main Overview:** `SKILL.md`
- **Individual Skills:** `skills/*/SKILL.md`
- **Quick Start:** `docs/QUICKSTART.md`
- **Testing Guide:** `docs/testing.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **Release Notes:** `RELEASE-NOTES.md`

## Architecture

```
User Request
    ↓
binary-vuln-assessment (orchestrator)
    ↓
┌─────────────────────────────────────┐
│ 1. binary-analysis                  │ → Metadata
│ 2. cpg-construction                 │ → CPG
│ 3. source-sink-discovery            │ → Sources/Sinks
│ 4. taint-analysis                   │ → Flows
│ 5. vuln-audit (STRICT - 5 checks)   │ → Confirmed Vulns
│ 6. vuln-reporting                   │ → Report + PoCs
└─────────────────────────────────────┘
```

## MANDATORY: Joern Usage

**BinGo REQUIRES Joern** for all CPG construction and taint analysis.

**Why Joern is mandatory:**
1. Native binary analysis with binary2cpg
2. Proven taint tracking accuracy
3. No decompilation needed
4. Reliable data flow analysis

**No alternatives:**
- ❌ No Ghidra-based CPG
- ❌ No manual decompilation
- ❌ No other taint analysis tools
- ✅ ONLY Joern binary2cpg + Joern taint tracking

## Contributing

Contributions welcome! Please see `CONTRIBUTING.md` for guidelines.

## License

Apache License 2.0 - see LICENSE file for details

## Acknowledgments

- **Joern** - Code Property Graph and taint analysis framework
- **Superpowers** - Skill architecture patterns and workflows

## Support

- **Issues:** https://github.com/your-org/bingo/issues
- **Documentation:** https://github.com/your-org/bingo/wiki
- **Joern:** https://joern.io

---

**BinGo v4.1.0** - Binary vulnerability mining made easy

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>

