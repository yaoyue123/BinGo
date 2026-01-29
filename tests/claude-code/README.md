# BinGo Claude Code Integration Tests

Tests for verifying BinGo skills work correctly with Claude Code.

## Running Tests

```bash
cd tests/claude-code
./run-bingo-tests.sh
```

## What It Tests

The integration test verifies the `bingo:binary-vuln-assessment` skill correctly:

1. **Skill Loading**: The skill loads and executes
2. **Binary Info Extraction**: Metadata is extracted correctly
3. **CPG Construction**: Joern builds a valid CPG
4. **Taint Analysis**: Data flows are tracked
5. **STRICT Audit**: All 5 checks are enforced
6. **Report Generation**: Final report with evidence is created

## Requirements

- Claude Code must be installed
- Joern CLI must be installed
- Test binaries must be compiled: `../binaries/compile_test_binaries.sh`

## Test Output

Successful test run:
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
