---
name: vuln-reporting
description: Use when generating vulnerability reports from audited findings. Triggers: "generate report", "create report", after vuln-audit completes. Produces detailed reports with complete pseudo-code paths and PoCs.
---

# Vulnerability Reporting / 漏洞报告

## Overview / 概述

Generates detailed vulnerability reports from confirmed vulnerabilities that passed STRICT audit.
从通过严格审计的确认漏洞生成详细漏洞报告。

## MANDATORY: Complete Evidence / 必须完整证据

**CRITICAL:** Each vulnerability MUST include complete, detailed evidence.
**关键：** 每个漏洞必须包含完整的详细证据。

### Evidence Requirements / 证据要求

1. **Complete Pseudo-code Path** - Every function in data flow with full code
2. **Data Flow Diagram** - ASCII diagram showing source → sink
3. **Vulnerability Annotation** - Mark [SOURCE], [SINK], [UNSAFE_COPY] in code
4. **Buffer Size Analysis** - Document buffer sizes and overflow potential
5. **Executable PoC** - Complete, runnable proof-of-concept

## When to Use / 使用场景

Use this skill when:
- User says "generate report", "create report"
- After vuln-audit completes
- Need to present findings with complete evidence
- User asks for vulnerability summary

## Report Structure / 报告结构

```markdown
# Binary Vulnerability Analysis Report

## Analysis Overview
- Target: binary.elf
- Architecture: x86_64
- Security: NX=enabled, PIE=disabled

## Vulnerability Summary
- Critical: 2
- High: 3
- Medium: 1

---

## Vulnerability Details

### [1] Buffer Overflow in `process_input`
- **CWE**: CWE-120
- **Severity**: Critical
- **Confidence**: High
- **Location**: process_input:0x4012a5 (line 45)

#### Complete Pseudo-code Path
**Step 1: Source Function - handle_connection**
```c
// Full function code here
```

**Step 2: Intermediate Function - pass_to_buffer**
```c
// Full function code here
```

**Step 3: Sink Function - process_input (VULNERABLE)**
```c
// Full function code with vulnerability marked
```

#### Data Flow Analysis
```
Source: recv() → Buffer → Function → Sink: strcpy()
```

#### PoC
```python
# Complete executable PoC
```
```

## Generating the Report / 生成报告

### Input Files / 输入文件

| File / 文件 | Description / 说明 |
|------------|-------------------|
| `confirmed_vulns.json` | Vulnerabilities that passed STRICT audit |
| `binary_info.json` | Binary metadata |
| `flows/*.json` | Original taint flows (for evidence) |
| Template files | Report structure templates |

### Generation Process / 生成过程

```bash
./bingo/scripts/agent/generate_report.sh \
  ./output/confirmed_vulns.json \
  ./output/binary_info.json \
  ./output/flows \
  ./output/vulnerability_report.md
```

## Evidence Generation Details / 证据生成详情

### 1. Complete Pseudo-code Path / 完整伪代码路径

Show EVERY function in the data flow path with full pseudo-code:

```
Source Function → Intermediate 1 → Intermediate 2 → Sink
   [full code]      [full code]       [full code]     [full code]
```

**NOT just snippets** - Include complete function bodies showing:
- Variable declarations and sizes
- All function calls
- Control flow (if/else/loops)
- Comments explaining data flow
- Line numbers and addresses

### 2. Data Flow Diagram / 数据流图

ASCII diagram showing how data moves from source to sink:

```
User Input (recv)
    ↓
Buffer[4096] (unbounded)
    ↓
extract_query_string() → returns pointer
    ↓
formHandler() - no validation
    ↓
temp_buffer[512] - strcpy overflow
    ↓
processCommand() - no validation
    ↓
cmd_buffer[128] - sprintf overflow
    ↓
system(cmd_buffer) ← SINK (RCE)
```

### 3. Vulnerability Annotation / 漏洞标注

In the pseudo-code, mark:
- `[SOURCE]` - Where untrusted data enters
- `[UNSAFE_COPY]` - Dangerous string operations
- `[NO_VALIDATION]` - Missing security checks
- `[SINK]` - Where vulnerability triggers

### 4. Buffer Size Analysis / 缓冲区大小分析

For buffer overflows, document:

```markdown
**Buffer Analysis:**
- Source buffer size: 4096 bytes (from recv)
- Dest buffer size: 64 bytes (local variable)
- Safe copy limit: 64 bytes
- Actual copy: Unlimited (strcpy)
- Overflow potential: 4032 bytes
```

### 5. Missing Protections Checklist / 缺失保护检查清单

```markdown
**Security Checks Missing:**
- ❌ No length validation before strcpy
- ❌ No bounds checking on array access
- ❌ No input sanitization (for command injection)
- ❌ No use of safe functions (strncpy, snprintf)
- ❌ Stack is executable (NX disabled)
```

## PoC Generation / PoC 生成

| Vulnerability Type | PoC Language |
|-------------------|--------------|
| Buffer Overflow | Python/C |
| Format String | Python |
| Command Injection | Bash/Python |
| Integer Overflow | C/C++ |

Each PoC includes:
- Complete executable code
- Detailed comments
- Usage instructions
- Expected behavior

### PoC Example / PoC 示例

```python
#!/usr/bin/env python3
"""
PoC for Buffer Overflow in process_input
Vulnerability: strcpy() without bounds checking
"""
import socket

target = ("192.168.1.1", 8080)

# Construct payload: 200 bytes to overflow 64-byte buffer
payload = b"A" * 200

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(target)
sock.send(payload)

# If successful, service crashes or shellcode executes
print("Payload sent. Check target for crash/shell.")
sock.close()
```

## Output / 输出

### vulnerability_report.md / 漏洞报告 Markdown

Comprehensive report with:
- Analysis overview
- Vulnerability summary
- Detailed vulnerability findings with complete evidence
- PoCs for each vulnerability
- Recommendations

## Report Quality Checklist / 报告质量检查清单

Before finalizing, verify:
- [ ] Every function in path shown with FULL pseudo-code
- [ ] Data flow clearly traced from source to sink
- [ ] Buffer sizes and limits documented
- [ ] Missing security checks listed
- [ ] Vulnerability annotated in code
- [ ] PoC is complete and executable
- [ ] Impact clearly explained

## Template Customization / 模板自定义

Templates located in: `bingo/templates/`

| Template / 模板 | Purpose / 目的 |
|----------------|--------------|
| `report_template.md` | Main report structure |
| `vuln_detail_template.md` | Individual vulnerability detail |
| `poc_template.py` | Python PoC skeleton |

## Example / 示例

```
User: "Generate a vulnerability report from the audit results"
Agent: [Uses vuln-reporting]
       [Reads confirmed_vulns.json]
       [Extracts pseudo-code for each function in data flow]
       [Creates data flow diagrams]
       [Generates PoCs]
       [Outputs vulnerability_report.md]
Output: "Report generated: vulnerability_report.md
        Contains 3 confirmed vulnerabilities with complete evidence"
```

## Integration / 集成

**Used by:**
- binary-vuln-assessment (final step in workflow)

**Uses:**
- vuln-audit (requires confirmed_vulns.json)
- binary-poc-generator (generates PoCs)
