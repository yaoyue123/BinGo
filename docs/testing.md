# Testing BinGo

This document describes how to test BinGo skills and the complete binary vulnerability analysis pipeline.

## Overview

BinGo provides several testing approaches:

1. **Unit Tests**: Test individual components (config loading, Joern detection)
2. **Integration Tests**: Test skill workflows end-to-end
3. **Explicit Skill Tests**: Verify skills load when explicitly requested
4. **Skill Triggering Tests**: Verify skills trigger from natural language prompts

## Test Structure

```
tests/
├── binaries/           # Test binary files
│   └── compile_test_binaries.sh
├── expected/           # Expected outputs
├── scripts/            # Test scripts
│   └── test_full_pipeline.sh
├── claude-code/        # Claude Code integration tests
├── explicit-skill-requests/  # Explicit skill invocation tests
└── skill-triggering/   # Skill triggering behavior tests
```

## Running Tests

### Compile Test Binaries

```bash
# Compile vulnerable test binaries
cd tests/binaries
./compile_test_binaries.sh
```

This creates test binaries with known vulnerabilities:
- `buffer_overflow_elf` - Classic strcpy buffer overflow
- `format_string_elf` - Format string vulnerability
- `command_injection_elf` - system() command injection
- `integer_overflow_elf` - Integer overflow leading to buffer overflow

### Full Pipeline Test

```bash
# Run the complete analysis pipeline
cd tests/scripts
./test_full_pipeline.sh
```

This tests:
1. Binary info extraction
2. CPG construction with Joern
3. Source/sink discovery
4. Taint analysis
5. STRICT audit (5 checks)
6. Report generation

### Expected Results

After a successful test run, check `expected/` directory:
- `binary_info.json` - Expected binary metadata
- `flows/*.json` - Expected taint flows
- `confirmed_vulns.json` - Expected confirmed vulnerabilities
- `vulnerability_report.md` - Expected final report

## Claude Code Integration Tests

### Running Integration Tests

```bash
cd tests/claude-code
./run-bingo-tests.sh
```

### What It Tests

The integration test verifies the `bingo:binary-vuln-assessment` skill correctly:
1. Loads and reads the skill
2. Executes the full pipeline
3. Creates all expected outputs
4. Validates findings with STRICT audit

### Test Output

```
========================================
 BinGo Integration Test
========================================

Test 1: Skill loaded...
  [PASS] bingo:binary-vuln-assessment skill invoked

Test 2: Binary info extracted...
  [PASS] binary_info.json created

Test 3: CPG constructed...
  [PASS] cpg.bin created
  [PASS] CPG has > 100 nodes

Test 4: Taint analysis completed...
  [PASS] flows/ directory created
  [PASS] Found expected taint flows

Test 5: STRICT audit passed...
  [PASS] confirmed_vulns.json created
  [PASS] All 5 checks enforced

Test 6: Report generated...
  [PASS] vulnerability_report.md created

STATUS: PASSED
```

## Explicit Skill Request Tests

### Test Scenarios

`tests/explicit-skill-requests/` contains test prompts for each skill:

1. **binary-analysis**: "Use bingo:binary-analysis to get info about this binary"
2. **cpg-construction**: "Use bingo:cpg-construction to build CPG"
3. **source-sink-discovery**: "Use bingo:source-sink-discovery"
4. **taint-analysis**: "Use bingo:taint-analysis to track data flows"
5. **vuln-audit**: "Use bingo:vuln-audit to validate findings"
6. **vuln-reporting**: "Use bingo:vuln-reporting to generate report"
7. **binary-vuln-assessment**: "Use bingo:binary-vuln-assessment for full analysis"
8. **joern-automation**: "Use bingo:joern-automation to check installation"
9. **binary-poc-generator**: "Use bingo:binary-poc-generator"

### Running Tests

```bash
cd tests/explicit-skill-requests
./run-all.sh
```

## Skill Triggering Tests

### Test Purpose

Verify that BinGo skills trigger from natural language prompts without explicit skill naming.

### Test Prompts

`tests/skill-triggering/prompts/` contains natural language prompts:

1. **analyze-binary.txt**: "Analyze this ELF binary for security vulnerabilities"
2. **check-buffer-overflow.txt**: "Check if this binary has buffer overflow vulnerabilities"
3. **data-flow-analysis.txt**: "Track data flow from user input to dangerous functions"

### Running Tests

```bash
cd tests/skill-triggering
./run-all.sh
```

## Troubleshooting

### Joern Not Found

**Problem**: Test fails with "joern: command not found"

**Solution**:
```bash
export PATH=$PATH:~/joern
# Or set JOERN_HOME
export JOERN_HOME=~/joern
```

### CPG Validation Fails

**Problem**: CPG has fewer than 100 nodes

**Solution**:
- Check binary is stripped or has insufficient symbols
- Try a different binary with more functions
- Lower the min_cpg_nodes threshold in `bingo-config.json`

### No Taint Flows Found

**Problem**: Taint analysis returns no flows

**Solution**:
- Verify sources.json and sinks.json are correct
- Check if binary has actual vulnerabilities
- Review Joern query in `scripts/joern/dataflow.sc`

### Tests Timeout

**Problem**: Tests take too long and timeout

**Solution**:
```bash
# Increase timeout in bingo-config.json
{
  "analysis": {
    "timeout_minutes": 120
  }
}
```

## Writing New Tests

### Test Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Setup
TEST_BINARY="$PROJECT_ROOT/tests/binaries/buffer_overflow_elf"
OUTPUT_DIR=$(mktemp -d)
trap "rm -rf $OUTPUT_DIR" EXIT

# Run test
echo "Running test..."
# Your test code here

# Verify
if [ -f "$OUTPUT_DIR/vulnerability_report.md" ]; then
    echo "[PASS] Report generated"
else
    echo "[FAIL] Report not generated"
    exit 1
fi
```

### Best Practices

1. **Always cleanup**: Use trap to remove temp directories
2. **Set -euo pipefail**: Fail on errors
3. **Verify outputs**: Check expected files exist
4. **Print results**: Use [PASS]/[FAIL] prefixes
5. **Document dependencies**: Note required tools (Joern, etc.)

## Requirements

- Joern CLI with binary2cpg
- bash 4.0+
- jq (JSON processing)
- readelf, nm, file (binary analysis tools)
- gcc, clang (for compiling test binaries)

## Continuous Integration

For CI/CD integration:

```yaml
# Example GitHub Actions
- name: Install Joern
  run: |
    git clone https://github.com/joernio/joern ~/joern
    cd ~/joern && ./build.sh
    echo "$HOME/joern" >> $GITHUB_PATH

- name: Compile test binaries
  run: ./tests/binaries/compile_test_binaries.sh

- name: Run full pipeline test
  run: ./tests/scripts/test_full_pipeline.sh

- name: Run skill tests
  run: ./tests/claude-code/run-bingo-tests.sh
```

## References

- Main documentation: `../docs/QUICKSTART.md`
- Troubleshooting: `../docs/TROUBLESHOOTING.md`
- Skill documentation: `../skills/*/SKILL.md`
