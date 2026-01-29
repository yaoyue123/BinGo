---
name: taint-analysis
description: Use when tracking data flow from source to sink in binary. Triggers: "data flow", "taint tracking", "taint analysis", "track data", after source-sink-discovery. Joern taint tracking is MANDATORY.
---

# Taint Analysis / 污点分析

## Overview / 概述

Tracks data flow from untrusted sources to dangerous sinks using Joern taint tracking (MANDATORY).
使用 Joern 污点追踪（必须）追踪从不可信源到危险汇的数据流。

## MANDATORY: Joern Taint Tracking / 必须使用 Joern 污点追踪

**CRITICAL:** All taint analysis MUST use Joern's built-in taint tracking.
**关键：** 所有污点分析必须使用 Joern 内置污点追踪。

### Why Joern Taint Tracking / 为什么必须使用 Joern

1. **Proven accuracy** - Reliable data flow analysis / 经过验证的准确性
2. **Path sensitivity** - Tracks complete execution paths / 路径敏感
3. **Context sensitivity** - Understands calling context / 上下文敏感

### No Alternatives / 无替代方案

- ❌ No manual data flow tracing / 不使用手动数据流追踪
- ❌ No alternative taint analysis tools / 不使用其他污点分析工具
- ✅ ONLY Joern taint tracking / 仅使用 Joern 污点追踪

## When to Use / 使用场景

Use this skill when:
- User says "data flow", "taint tracking", "taint analysis"
- User asks "how does data reach this dangerous function"
- After source-sink-discovery completes
- Before vulnerability audit

## Quick Start / 快速开始

```bash
joern cpg.bin --script bingo/scripts/joern/dataflow.sc sources.json sinks.json flows/
```

## How Taint Analysis Works / 污点分析工作原理

```
Source Function (untrusted input)
    ↓
Taint propagation through variables/parameters
    ↓
Intermediate functions (pass-through)
    ↓
Sink Function (dangerous operation) ← VULNERABILITY!
```

## Data Flow Query / 数据流查询

```scala
// Load source/sink definitions
val sources = io.circe.parser.parse(sourcesJson)
val sinks = io.circe.parser.parse(sinksJson)

// Find flows from sources to sinks
val flows = cpg.taintTracking(sources).flowsTo(sinks)

// Output paths
flows.p.foreach { flow =>
  println(s"${flow.source} -> ${flow.sink}")
  flow.pathElements.foreach(e => println(s"  ${e.method}:${e.line}"))
}
```

## Output / 输出

### Directory Structure / 目录结构

```
flows/
├── flow_001.json  # Individual flow data
├── flow_002.json
└── ...
```

### Flow JSON Format / Flow JSON 格式

```json
{
  "flow_id": "flow_001",
  "source": {
    "function": "recv",
    "location": "handle_connection:0x401020",
    "line": 25
  },
  "sink": {
    "function": "strcpy",
    "location": "process_input:0x4012a5",
    "line": 45
  },
  "path": [
    {"function": "handle_connection", "line": 25, "type": "source"},
    {"function": "extract_user_input", "line": 30, "type": "intermediate"},
    {"function": "pass_to_buffer", "line": 15, "type": "intermediate"},
    {"function": "process_input", "line": 45, "type": "sink"}
  ],
  "vulnerability_type": "buffer_overflow"
}
```

## Interpreting Results / 解释结果

### Good Flow (Vulnerability Found) / 好的流（发现漏洞）

- ✅ Complete path from source to sink
- ✅ All functions in path identified
- ✅ Line numbers verified
- ✅ Clear vulnerability type

### Bad Flow (False Positive) / 坏的流（误报）

- ❌ Incomplete path (gaps in trace)
- ❌ Unknown intermediate functions
- ❌ Missing line numbers
- ❌ Unclear vulnerability type

## Common Issues / 常见问题

### Issue: No flows found / 未发现流

**Possible causes:**
1. Sources/sinks don't match binary functions
2. Binary has proper input validation
3. CPG is incomplete/stripped

**Action:** Re-run source-sink-discovery with custom patterns

### Issue: Too many flows / 流太多

**Possible causes:**
1. Sources too broad (e.g., all memory reads)
2. Sinks too broad (e.g., all string operations)
3. Lack of sanitization in binary

**Action:** Refine sources/sinks, audit will filter false positives

### Issue: Incomplete paths / 路径不完整

**Possible causes:**
1. Binary is partially stripped
2. Complex control flow
3. Joern limitations

**Action:** Mark for manual review, may not pass audit

## Validation / 验证

After taint analysis, validate:
1. Flow files created in output directory
2. Each flow has source, sink, and path
3. Line numbers are present
4. Vulnerability type is clear

## Example / 示例

```
User: "Track data flow from network input to strcpy"
Agent: [Uses taint-analysis with recv as source, strcpy as sink]
       [Runs Joern taint tracking]
       [Outputs flows to flows/ directory]
Output: "Found 3 data flows from recv to strcpy:
        flow_001: recv → handle_connection → process_input → strcpy
        flow_002: recv → read_data → buffer_copy → strcpy
        flow_003: recv → get_client_input → strcpy"
```

## Integration / 集成

**Used by:**
- vuln-audit (requires flows as input)

**Uses:**
- source-sink-discovery (gets sources/sinks)
- cpg-construction (requires CPG as input)
