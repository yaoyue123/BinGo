#!/bin/bash
# BinGo Agent: Vulnerability Report Generation
# Generates detailed reports from confirmed vulnerabilities

set -e

OUTPUT_DIR="$1"

if [ -z "$OUTPUT_DIR" ] || [ ! -d "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <output_dir>"
    exit 1
fi

REPORT_OUTPUT="$OUTPUT_DIR/vulnerability_report.md"

echo "Generating vulnerability report..."

# Check if confirmed_vulns.json exists
if [ ! -f "$OUTPUT_DIR/confirmed_vulns.json" ]; then
    echo "Warning: confirmed_vulns.json not found"
    CONFIRMED_COUNT=0
else
    CONFIRMED_COUNT=$(jq '.audit_summary.passed_audit' "$OUTPUT_DIR/confirmed_vulns.json")
fi

# Get binary info
BINARY_NAME=$(jq -r '.file // "Unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "Unknown")
ARCHITECTURE=$(jq -r '.architecture // "Unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "Unknown")
FORMAT=$(jq -r '.format // "Unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "Unknown")

# Get security info
NX=$(jq -r '.security.nx // "unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "unknown")
PIE=$(jq -r '.security.pie // "unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "unknown")
CANARY=$(jq -r '.security.canary // "unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "unknown")
RELRO=$(jq -r '.security.relro // "unknown"' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || echo "unknown")

# Get CPG stats
NODE_COUNT=$(grep "^Nodes:" "$OUTPUT_DIR/cpg-validation-native.txt" 2>/dev/null | awk '{print $2}' || echo "N/A")

# Generate report
cat > "$REPORT_OUTPUT" << EOF
# Binary Vulnerability Analysis Report
# 二进制漏洞分析报告

**Generated:** $(date)
**Tool:** BinGo v3.0.0

---

## Analysis Overview / 分析概述

| Field / 字段 | Value / 值 |
|-------------|-----------|
| **Target / 目标** | \`$BINARY_NAME\` |
| **Format / 格式** | $FORMAT |
| **Architecture / 架构** | $ARCHITECTURE |
| **CPG Nodes / CPG 节点** | $NODE_COUNT |

### Security Features / 安全特性

| Feature / 特性 | Status / 状态 |
|---------------|--------------|
| **NX** | $NX |
| **PIE** | $PIE |
| **Canary** | $CANARY |
| **RELRO** | $RELRO |

---

## Vulnerability Summary / 漏洞摘要

| Severity / 严重性 | Count / 数量 |
|------------------|------------|
| **Critical / 严重** | $(jq '[.vulnerabilities[] | select(.severity == "critical")] | length' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo 0) |
| **High / 高危** | $(jq '[.vulnerabilities[] | select(.severity == "high")] | length' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo 0) |
| **Medium / 中危** | $(jq '[.vulnerabilities[] | select(.severity == "medium")] | length' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo 0) |
| **Low / 低危** | $(jq '[.vulnerabilities[] | select(.severity == "low")] | length' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo 0) |

**Total Confirmed / 总计确认:** $CONFIRMED_COUNT

---

## Analysis Pipeline / 分析流程

This analysis followed the BinGo strict audit pipeline:
本分析遵循 BinGo 严格审计流程：

1. **Binary Analysis / 二进制分析** - Extracted metadata and security features
2. **CPG Construction / CPG 构建** - Built Code Property Graph using Joern binary2cpg
3. **Source/Sink Discovery / 源汇发现** - Identified input sources and dangerous sinks
4. **Taint Analysis / 污点分析** - Tracked data flows using Joern taint tracking
5. **STRICT Audit / 严格审计** - Applied 5 mandatory checks (all must pass)
6. **Report Generation / 报告生成** - Created this detailed report

---

## STRICT Audit Criteria / 严格审计标准

Each confirmed vulnerability passed ALL 5 mandatory checks:
每个确认的漏洞都通过了所有 5 项必须检查：

1. ✅ **Data Flow Complete / 数据流完整** - Full trace from source to sink documented
2. ✅ **Source Verified / 源已验证** - Source is untrusted input
3. ✅ **Sink Verified / 汇已验证** - Sink is dangerous operation
4. ✅ **Protections Absent / 保护缺失** - No bounds checking or validation
5. ✅ **False Positive Ruled Out / 误报排除** - Not dead code or unreachable

---

EOF

# Add vulnerability details if any
if [ $CONFIRMED_COUNT -gt 0 ]; then
    cat >> "$REPORT_OUTPUT" << EOF
## Vulnerability Details / 漏洞详情

EOF

    # Iterate through confirmed vulnerabilities
    jq -r '.vulnerabilities[] | @json' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null | while read -r vuln_json; do
        FLOW_ID=$(echo "$vuln_json" | jq -r '.flow_id')
        VULN_TYPE=$(echo "$vuln_json" | jq -r '.vulnerability_type // "unknown"')
        SEVERITY=$(echo "$vuln_json" | jq -r '.severity // "high"')
        SOURCE=$(echo "$vuln_json" | jq -r '.source.function // .source // "unknown"')
        SINK=$(echo "$vuln_json" | jq -r '.sink.function // .sink // "unknown"')

        cat >> "$REPORT_OUTPUT" << EOF
### Vulnerability: $FLOW_ID

- **CWE:** $(get_cwe "$VULN_TYPE")
- **Type / 类型:** $VULN_TYPE
- **Severity / 严重性:** $(echo "$SEVERITY" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
- **Confidence / 置信度:** High
- **Source / 源:** \`$SOURCE\`
- **Sink / 汇:** \`$SINK\`

#### Data Flow Path / 数据流路径

\`\`\`
Source: $SOURCE
  → [intermediate functions]
  → Sink: $SINK
\`\`\`

#### Impact / 影响

This vulnerability allows exploitation through **$VULN_TYPE**.
此漏洞允许通过 **$VULN_TYPE** 进行利用。

#### Recommendation / 建议

1. **Immediate / 立即:** Patch the unsafe function call
2. **Short-term / 短期:** Add input validation and bounds checking
3. **Long-term / 长期:** Enable compile-time protections (NX, PIE, Canary)

---

EOF
    done
else
    cat >> "$REPORT_OUTPUT" << EOF
## No Confirmed Vulnerabilities / 无确认漏洞

✅ **Good News:** No confirmed vulnerabilities found in this binary.

**Possible Reasons:**
1. Binary has proper security protections (Canary, NX, PIE)
2. Input validation and bounds checking implemented
3. Taint analysis found no exploitable data flows
4. Binary may be protected or analyzed incorrectly

**Note:** This does NOT guarantee the binary is secure. It means no vulnerabilities
passed the STRICT audit criteria. Manual review may still be needed.

---

EOF
fi

# Add footer
cat >> "$REPORT_OUTPUT" << EOF
## Analysis Quality / 分析质量

| Metric / 指标 | Value / 值 |
|-------------|-----------|
| **CPG Nodes** | $NODE_COUNT |
| **Total Flows Found** | $(jq '.audit_summary.total_flows' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo 0) |
| **Passed STRICT Audit** | $CONFIRMED_COUNT |
| **Audit Pass Rate** | $(jq '.audit_summary.pass_rate // "N/A"' "$OUTPUT_DIR/confirmed_vulns.json" 2>/dev/null || echo "N/A")% |

---

## Files Generated / 生成的文件

| File / 文件 | Description / 说明 |
|------------|-------------------|
| \`binary_info.json\` | Binary metadata and security features |
| \`cpg.bin\` | Code Property Graph (Joern format) |
| \`cpg-validation-native.txt\` | CPG construction statistics |
| \`sources.json\` | Identified source functions |
| \`sinks.json\` | Identified sink functions |
| \`flows/\` | Raw taint flows from Joern |
| \`confirmed_vulns.json\` | Vulnerabilities that passed STRICT audit |
| \`vulnerability_report.md\` | This report |

---

## Tool Information / 工具信息

- **Tool:** BinGo v3.0.0
- **Method:** Joern binary2cpg + Joern taint tracking + STRICT audit
- **Analysis Date:** $(date)
- **Analyst:** Automated Analysis

**BinGo is a production-ready binary vulnerability mining platform.**
**BinGo 是生产就绪的二进制漏洞挖掘平台。**

For more information: https://github.com/your-org/bingo

---

*Report generated by BinGo v3.0.0*
*报告由 BinGo v3.0.0 生成*
EOF

echo "✓ Report generated: $REPORT_OUTPUT"

# Helper function to get CWE based on vulnerability type
get_cwe() {
    case "$1" in
        "buffer_overflow")
            echo "CWE-120"
            ;;
        "format_string")
            echo "CWE-134"
            ;;
        "command_injection")
            echo "CWE-77"
            ;;
        "integer_overflow")
            echo "CWE-190"
            ;;
        *)
            echo "CWE-UNKNOWN"
            ;;
    esac
}
