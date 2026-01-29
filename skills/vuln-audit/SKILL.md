---
name: vuln-audit
description: Use when performing STRICT vulnerability audit on taint flows. Triggers: "audit findings", "verify vulnerabilities", after taint analysis, before reporting. Enforces 5 mandatory checks - only flows passing all checks are confirmed.
---

# Vulnerability Audit / 漏洞审计

## Overview / 概述

STRICT audit enforcement - every taint flow MUST pass all 5 checks before being confirmed as vulnerability.
严格审计强制执行 - 每个污点流必须通过所有 5 项检查才能确认为漏洞。

## MANDATORY: Strict Audit / 必须执行严格审计

**CRITICAL:** Automatic enforcement of all audit checks. No exceptions.
**关键：** 自动强制执行所有审计检查。无例外。

### The 5 Mandatory Checks / 5 项必须检查

| Check / 检查 | Description / 描述 | Pass Condition / 通过条件 |
|-------------|-------------------|------------------------|
| **1. Data Flow Complete** | Full trace from source to sink documented | Every step identified with line numbers |
| **2. Source Verified** | Source is untrusted input | Confirmed as external/user input |
| **3. Sink Verified** | Sink is dangerous operation | Confirmed as vulnerability type |
| **4. Protections Absent** | No bounds checking, validation, sanitization | Explicitly verified as ABSENT |
| **5. False Positive Ruled Out** | Not dead code, not unreachable, no mitigations | Reachable and exploitable |

### Audit Failure = No Report / 审计失败 = 不报告

**CRITICAL:** If ANY check fails, the flow is NOT a vulnerability.
**关键：** 如果任何检查失败，该流不是漏洞。

- ❌ Incomplete trace → Discard
- ❌ Unclear source/sink → Discard
- ❌ Protections present → Discard
- ❌ Dead code path → Discard
- ✅ Only report flows passing ALL 5 checks

## When to Use / 使用场景

Use this skill when:
- Taint analysis completes
- User says "audit findings", "verify vulnerabilities"
- Before generating vulnerability report
- Need to filter false positives

## Audit Process / 审计流程

### Step 1: Load Taint Flows / 步骤 1：加载污点流

```bash
# Load flows from taint analysis
flows_dir="./output/flows"
```

### Step 2: For Each Flow - Run All 5 Checks / 步骤 2：对每个流运行所有 5 项检查

```python
def audit_flow(flow):
    results = {
        "data_flow_complete": False,
        "source_verified": False,
        "sink_verified": False,
        "protections_absent": False,
        "not_false_positive": False
    }

    # Check 1: Verify data flow is complete
    if flow.has_complete_trace():
        results["data_flow_complete"] = True
    else:
        return {"passed": False, "reason": "Incomplete data flow trace"}

    # Check 2: Verify source is untrusted
    if is_untrusted_source(flow.source):
        results["source_verified"] = True
    else:
        return {"passed": False, "reason": "Source not verified as untrusted"}

    # Check 3: Verify sink is dangerous
    if is_dangerous_sink(flow.sink):
        results["sink_verified"] = True
    else:
        return {"passed": False, "reason": "Sink not verified as dangerous"}

    # Check 4: Verify protections are absent
    protections = check_protections(flow.path)
    if protections.count == 0:
        results["protections_absent"] = True
    else:
        return {"passed": False, "reason": f"Protections found: {protections.list}"}

    # Check 5: Verify not a false positive
    if not is_false_positive(flow):
        results["not_false_positive"] = True
    else:
        return {"passed": False, "reason": "False positive detected"}

    return {"passed": True, "results": results}
```

### Step 3: Report Only Passed Audits / 步骤 3：仅报告通过审计的

```bash
confirmed_vulns = []
for flow in flows:
    audit = audit_flow(flow)
    if audit["passed"]:
        confirmed_vulns.append(flow)
```

## Check Details / 检查详情

### Check 1: Complete Data Flow Trace / 完整数据流追踪

**Required / 必须:**
- [ ] Every function in path identified
- [ ] Line numbers verified for each step
- [ ] Variable names traced through entire flow
- [ ] No gaps in the trace

**Fail if:** Missing functions, unknown line numbers, broken trace

### Check 2: Source Validation / 源验证

**Required / 必须:**
- [ ] Source function confirmed as untrusted input
- [ ] Input size/characteristics documented
- [ ] No upstream filtering identified

**Fail if:** Source is trusted/internal, unclear origin

### Check 3: Sink Validation / 汇验证

**Required / 必须:**
- [ ] Sink function confirmed as dangerous operation
- [ ] Vulnerability type correctly classified
- [ ] Exploitation conditions documented

**Fail if:** Sink is safe operation, unclear vulnerability type

### Check 4: Missing Protections Verification / 缺失保护验证

**Required / 必须:**
- [ ] Bounds checking explicitly verified as ABSENT
- [ ] Input validation explicitly verified as ABSENT
- [ ] Sanitization explicitly verified as ABSENT
- [ ] Safe functions NOT used

**Fail if:** Any protections found (length check, validation, etc.)

### Check 5: False Positive Checks / 误报检查

**Required / 必须:**
- [ ] Not a dead code path
- [ ] Not unreachable due to prior conditions
- [ ] Not protected by compiler/runtime checks
- [ ] Not mitigated by system protections

**Fail if:** Code is unreachable, has mitigations, or is protected

## Output / 输出

### confirmed_vulns.json / 确认漏洞 JSON

```json
{
  "audit_summary": {
    "total_flows": 15,
    "passed_audit": 3,
    "failed_audit": 12
  },
  "vulnerabilities": [
    {
      "flow_id": "flow_001",
      "vulnerability_type": "buffer_overflow",
      "severity": "critical",
      "confidence": "high",
      "audit_complete": true,
      "audit_results": {
        "data_flow_complete": true,
        "source_verified": true,
        "sink_verified": true,
        "protections_absent": true,
        "not_false_positive": true
      }
    }
  ]
}
```

## Audit Sign-off / 审计签署

Each confirmed vulnerability MUST include:
每个确认的漏洞必须包括：

```json
{
  "audit_complete": true,
  "data_flow_verified": true,
  "protections_verified_absent": true,
  "false_positive_checks": true,
  "confidence": "high|medium|low",
  "auditor_notes": "Detailed explanation of audit findings"
}
```

## Common Audit Failures / 常见审计失败

| Failure Reason / 失败原因 | Example / 示例 |
|------------------------|---------------|
| Incomplete trace / 不完整追踪 | Missing intermediate function in path |
| Source unclear / 源不明 | Source is internal function, not external input |
| Protections present / 存在保护 | `if (len < 64) strcpy(dest, src)` |
| Dead code / 死代码 | Sink in `if (false)` block |
| Unreachable / 不可达 | Prior condition prevents reaching sink |

## Validation / 验证

After audit, validate:
1. confirmed_vulns.json created
2. All vulnerabilities have audit_complete: true
3. Failed flows are NOT included
4. Confidence level is assigned

## Example / 示例

```
User: "Audit the 15 flows found by taint analysis"
Agent: [Uses vuln-audit]
       [Runs all 5 checks on each flow]
       [Filter: only 3 pass all checks]
Output: "Audit complete: 3/15 flows confirmed as vulnerabilities.
        12 discarded (5 incomplete traces, 4 had protections,
        3 were false positives)"
```

## Integration / 集成

**Used by:**
- vuln-reporting (requires confirmed_vulns.json as input)

**Uses:**
- taint-analysis (gets flows as input)
- binary-analysis (for context on protections)
