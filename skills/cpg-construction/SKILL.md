---
name: cpg-construction
description: Use when building Code Property Graph from binary. Triggers: "build CPG", "create CPG", after binary-analysis, before taint analysis. Joern binary2cpg is MANDATORY - no alternatives, no fallback.
---

# CPG Construction / CPG 构建

## Overview / 概述

Builds Code Property Graph from binary using Joern binary2cpg (MANDATORY).
使用 Joern binary2cpg（必须）从二进制构建代码属性图。

## MANDATORY: Joern binary2cpg Only / 必须使用 Joern binary2cpg

**CRITICAL:** Joern binary2cpg is NOT optional. All CPG construction MUST use Joern.
**关键：** Joern binary2cpg 不是可选项。所有 CPG 构建必须使用 Joern。

### Why Joern is Mandatory / 为什么必须使用 Joern

1. **Native binary analysis** - Direct binary-to-CPG conversion / 原生二进制分析
2. **Proven reliability** - Tested on real-world binaries / 经过验证的可靠性
3. **No decompilation needed** - Works directly on binary / 无需反编译

### No Alternatives / 无替代方案

- ❌ No Ghidra-based CPG / 不使用基于 Ghidra 的 CPG
- ❌ No manual decompilation / 不使用手动反编译
- ✅ ONLY Joern binary2cpg / 仅使用 Joern binary2cpg

## When to Use / 使用场景

Use this skill when:
- User says "build CPG", "create CPG", "generate code property graph"
- After binary-analysis completes
- Before running taint analysis
- Need to validate binary can be analyzed

## Quick Start / 快速开始

```bash
./bingo/scripts/cpg/build_cpg_native.sh /path/to/binary.elf cpg.bin
```

## Validation / 验证

After building CPG, validate:

```bash
joern cpg.bin --script "
  println(s\"Nodes: \${cpg.graph.nodeCount}\")
  println(s\"Edges: \${cpg.graph.edgeCount}\")
  println(s\"Methods: \${cpg.method.name.toSet.size}\")
"
```

### Quality Gates / 质量门

| Metric / 指标 | Threshold / 阈值 | Action / 操作 |
|--------------|-----------------|--------------|
| **Node Count** | > 100 | Binary likely analyzable / 二进制可能可分析 |
| **Node Count** | < 100 | Binary may be stripped / 二进制可能被剥离 |
| **Method Count** | > 10 | Sufficient for analysis / 足够进行分析 |

## Output / 输出

| File / 文件 | Description / 说明 |
|------------|-------------------|
| `cpg.bin` | Code Property Graph (Joern format) |
| `cpg-validation.txt` | Validation statistics |

## Common Issues / 常见问题

### Issue: Joern not found / Joern 未找到

**Error:** `joern: command not found`
**Solution:**
```bash
# Check Joern installation
which joern

# Check binary2cpg availability
ls ~/bin/joern-cli/binary2cpg

# Install if missing
# See joern-automation skill
```

### Issue: CPG too small (< 100 nodes) / CPG 太小

**Possible causes:**
- Binary is stripped (no symbols)
- Binary is packed/compressed
- Architecture not supported

**Action:** Warn user that analysis may be limited

## Architecture Support / 架构支持

| Architecture / 架构 | Status / 状态 | Notes / 说明 |
|-------------------|--------------|------------|
| x86 (32-bit) | ✅ Supported | Fully supported |
| x86-64 (64-bit) | ✅ Supported | Fully supported |
| ARM (32-bit) | ✅ Supported | Fully supported |
| ARM64 (aarch64) | ✅ Supported | Fully supported |
| MIPS | ⚠️ Limited | May have issues |
| PowerPC | ❌ Unsupported | Not tested |

## Example / 示例

```
User: "Build a CPG from this router firmware"
Agent: [First uses binary-analysis to check architecture]
       [Then uses cpg-construction]
       [Validates CPG has > 100 nodes]
Output: "CPG built successfully with 15,432 nodes, 45,123 edges, 234 methods"
```

## Integration / 集成

**Used by:**
- taint-analysis (requires CPG as input)
- source-sink-discovery (queries CPG for functions)

**Uses:**
- binary-analysis (gets architecture info)
- joern-automation (validates Joern installation)
