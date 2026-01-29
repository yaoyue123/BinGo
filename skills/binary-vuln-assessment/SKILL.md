---
name: binary-vuln-assessment
description: Use when analyzing binary for security vulnerabilities. Triggers: "analyze binary", "find vulnerabilities in binary", "binary vulnerability assessment". Orchestrates complete workflow: binary-analysis → cpg-construction → source-sink-discovery → taint-analysis → vuln-audit → vuln-reporting.
---

# Binary Vulnerability Assessment / 二进制漏洞评估

## Overview / 概述

Main orchestrator skill for complete binary vulnerability analysis pipeline.
二进制漏洞分析完整流水线的主要编排技能。

## When to Use / 使用场景

Use this skill when:
- User says "analyze binary for vulnerabilities"
- User says "find vulnerabilities in binary"
- User says "assess binary security"
- User provides binary file and asks for security analysis
- Need complete vulnerability assessment workflow

## Workflow Orchestration / 工作流编排

This skill orchestrates the complete analysis pipeline:

```
1. binary-analysis
   ↓ (extract metadata)
2. cpg-construction
   ↓ (build CPG, validate > 100 nodes)
3. source-sink-discovery
   ↓ (identify sources/sinks)
4. taint-analysis
   ↓ (track data flows)
5. vuln-audit
   ↓ (STRICT audit, 5 checks)
6. vuln-reporting
   → (generate report with PoCs)
```

## Quick Start / 快速开始

### Complete Analysis / 完整分析

```bash
./bingo/scripts/analyze.sh /path/to/binary.elf ./output
```

### Output / 输出

```
output/
├── binary_info.json           # From binary-analysis
├── cpg.bin                    # From cpg-construction
├── cpg-validation.txt         # From cpg-construction
├── sources.json               # From source-sink-discovery
├── sinks.json                 # From source-sink-discovery
├── flows/                     # From taint-analysis
│   ├── flow_001.json
│   └── flow_002.json
├── confirmed_vulns.json       # From vuln-audit
└── vulnerability_report.md    # From vuln-reporting
```

## Quality Gates / 质量门

### Gate 1: CPG Validation / CPG 验证

**Check:** CPG must have > 100 nodes
**Action if fail:** Warn user binary may be stripped

```bash
if [ $(jq '.nodeCount' cpg-validation.txt) -lt 100 ]; then
  echo "WARNING: CPG has fewer than 100 nodes. Binary may be stripped."
fi
```

### Gate 2: Flow Discovery / 流发现

**Check:** At least 1 flow found
**Action if fail:** Suggest custom sources/sinks

```bash
if [ $(ls flows/*.json 2>/dev/null | wc -l) -eq 0 ]; then
  echo "INFO: No flows found. Binary may have proper input validation."
  echo "Consider: Custom source/sink discovery"
fi
```

### Gate 3: Audit Pass Rate / 审计通过率

**Check:** Confirm audit results
**Action:** Report only confirmed vulnerabilities

```bash
total_flows=$(jq '.audit_summary.total_flows' confirmed_vulns.json)
confirmed=$(jq '.audit_summary.passed_audit' confirmed_vulns.json)
echo "Audit: $confirmed/$total_flows flows confirmed as vulnerabilities"
```

### Gate 4: Evidence Completeness / 证据完整性

**Check:** Report has complete pseudo-code paths
**Action if fail:** Do not mark as complete

```bash
if ! grep -q "COMPLETE DATA FLOW" vulnerability_report.md; then
  echo "ERROR: Report missing complete evidence"
  exit 1
fi
```

## Error Recovery / 错误恢复

### Error: Joern Not Found / Joern 未找到

```bash
# Check Joern installation
if ! command -v joern &> /dev/null; then
  echo "ERROR: Joern not found."
  echo "Install Joern from: https://joern.io/installation"
  echo "Or use: ./bingo/scripts/install_joern.sh"
  exit 1
fi
```

### Error: CPG Too Small / CPG 太小

```bash
# Check if binary is stripped
if [ $(jq '.nodeCount' cpg-validation.txt) -lt 100 ]; then
  echo "CPG has only $(jq '.nodeCount' cpg-validation.txt) nodes."
  echo "Possible causes:"
  echo "  1. Binary is stripped (no symbols)"
  echo "  2. Binary is packed/compressed"
  echo "  3. Architecture not fully supported"
  echo ""
  echo "Recommendation: Try with unstripped binary if available"
fi
```

### Error: No Flows Found / 未发现流

```bash
if [ $(ls flows/*.json 2>/dev/null | wc -l) -eq 0 ]; then
  echo "No data flows found from sources to sinks."
  echo ""
  echo "Possible causes:"
  echo "  1. Sources/sinks don't match binary functions"
  echo "  2. Binary has proper input validation"
  echo "  3. CPG incomplete"
  echo ""
  echo "Recommendation: Re-run with custom sources/sinks"
fi
```

### Error: All Flows Fail Audit / 所有流审计失败

```bash
if [ $(jq '.audit_summary.passed_audit' confirmed_vulns.json) -eq 0 ]; then
  echo "All flows failed STRICT audit."
  echo "This is NORMAL if binary has security protections."
  echo ""
  echo "Report will state: 'No confirmed vulnerabilities found'"
fi
```

## Progress Reporting / 进度报告

Show progress during analysis:

```bash
echo "Step 1/6: Binary analysis..."
./bingo/scripts/binary_info.sh "$BINARY" "$OUTPUT"

echo "Step 2/6: Building CPG..."
./bingo/scripts/cpg/build_cpg_native.sh "$BINARY" "$OUTPUT/cpg.bin"

echo "Step 3/6: Discovering sources/sinks..."
joern "$OUTPUT/cpg.bin" --script bingo/scripts/joern/discover_sources.sc

echo "Step 4/6: Running taint analysis..."
joern "$OUTPUT/cpg.bin" --script bingo/scripts/joern/dataflow.sc

echo "Step 5/6: Auditing findings..."
./bingo/scripts/agent/validate_findings.sh "$OUTPUT"

echo "Step 6/6: Generating report..."
./bingo/scripts/agent/generate_report.sh "$OUTPUT"
```

## Common Scenarios / 常见场景

### Scenario 1: Router Firmware Analysis / 路由器固件分析

```bash
# Analyze MIPS router firmware
./bingo/scripts/analyze.sh /path/to/router_firmware.bin ./router_analysis

# Expected: Command injection, buffer overflow vulnerabilities
```

### Scenario 2: IoT Device Binary / IoT 设备二进制

```bash
# Analyze ARM IoT binary
./bingo/scripts/analyze.sh iot_device.elf ./iot_analysis

# Expected: Format string, buffer overflow vulnerabilities
```

### Scenario 3: Custom Source Discovery / 自定义源发现

```bash
# Default sources don't match binary
# 1. Run binary-analysis to identify custom input functions
./bingo/scripts/binary_info.sh binary.elf .

# 2. Manually specify custom sources
echo '{"sources": ["custom_read_input", "process_user_data"]}' > custom_sources.json

# 3. Re-run taint analysis with custom sources
joern cpg.bin --script dataflow.sc custom_sources.json sinks.json flows/
```

## Example / 示例

```
User: "Analyze this router binary for vulnerabilities"
Agent: [Uses binary-vuln-assessment]
       [Orchestrates complete workflow]

[Step 1: Binary analysis]
Output: "32-bit MIPS ELF, NX disabled, PIE disabled"

[Step 2: CPG construction]
Output: "CPG built: 12,456 nodes"

[Step 3: Source/sink discovery]
Output: "Found 8 sources, 12 sinks"

[Step 4: Taint analysis]
Output: "Found 15 data flows"

[Step 5: Audit]
Output: "3/15 flows passed STRICT audit"

[Step 6: Report generation]
Output: "Report generated: vulnerability_report.md"

Final: "Analysis complete. Found 3 confirmed vulnerabilities:
        1. Critical: Buffer overflow in process_http_request
        2. High: Command injection in execute_system_cmd
        3. High: Format string in log_message"
```

## Integration / 集成

**Orchestrates:**
- binary-analysis (step 1)
- cpg-construction (step 2)
- source-sink-discovery (step 3)
- taint-analysis (step 4)
- vuln-audit (step 5)
- vuln-reporting (step 6)

**Uses:**
- joern-automation (validates Joern before starting)
- binary-poc-generator (for PoC generation in reporting)
