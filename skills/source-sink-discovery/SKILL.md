---
name: source-sink-discovery
description: Use when discovering vulnerability source and sink functions in binary. Triggers: "find sources", "identify sinks", after CPG construction, before taint analysis. Combines built-in definitions with LLM-driven custom discovery.
---

# Source/Sink Discovery / 源汇函数发现

## Overview / 概述

Identifies source functions (untrusted input) and sink functions (dangerous operations) for taint analysis.
识别源函数（不可信输入）和汇函数（危险操作）用于污点分析。

## When to Use / 使用场景

Use this skill when:
- User mentions "sources", "sinks", "taint sources"
- After CPG construction completes
- Before running taint analysis
- Need to find input functions or dangerous operations

## Two-Phase Discovery / 两阶段发现

### Phase 1: Built-in Definitions / 内置定义

Standard vulnerability sources and sinks from BinGo reference materials.
来自 BinGo 参考材料的标准漏洞源和汇。

### Phase 2: LLM-Driven Discovery / LLM 驱动发现

Analyzes CPG and pseudo-code to identify custom input functions.
分析 CPG 和伪代码以识别自定义输入函数。

## Built-in Sources / 内置源函数

| Category / 类别 | Functions / 函数 |
|----------------|-----------------|
| **User Input** | `scanf`, `gets`, `fgets`, `gets_s` |
| **Network** | `read`, `recv`, `recvfrom`, `recvmsg` |
| **File I/O** | `fread`, `fgetc`, `getline`, `readlink` |
| **Environment** | `getenv`, `__secure_getenv` |
| **Arguments** | `argv`, `argc` (main parameters) |

## Built-in Sinks / 内置汇函数

| Category / 类别 | Functions / 函数 | Vulnerability / 漏洞 |
|----------------|-----------------|---------------------|
| **Buffer Ops** | `strcpy`, `strcat`, `sprintf`, `gets` | Buffer Overflow |
| **Memory Ops** | `memcpy`, `memset`, `bcopy` | Buffer Overflow |
| **Command** | `system`, `execve`, `popen`, `execl` | Command Injection |
| **Format** | `printf`, `fprintf`, `snprintf` (user format) | Format String |

## LLM Discovery of Custom Sources / LLM 发现自定义源

### Naming Patterns / 命名模式

```
userinput, getvar, read_input, get_data, parse_input,
receive_msg, handle_data, get_param, fetch_input,
process_request, get_user_input, read_from_client
```

### Code Characteristics / 代码特征

Functions identified as custom sources when:
- Function name contains: input/get/read/receive/parse/fetch
- Parameters include: buffer/size/input/data
- Returns pointer or buffer
- Calls standard input functions internally
- Called by multiple functions as data source

### Discovery Process / 发现过程

```bash
# 1. Query CPG for function signatures
joern cpg.bin --script bingo/scripts/joern/discover_sources.sc

# 2. Analyze pseudo-code of candidates
# 3. Confirm as sources if they match patterns
# 4. Add to sources.json
```

## Output Files / 输出文件

| File / 文件 | Content / 内容 |
|------------|--------------|
| `sources.json` | All identified sources (built-in + discovered) |
| `sinks.json` | All identified sinks |
| `discovered_sources.md` | Discovered sources with reasoning |

## Output Format / 输出格式

```json
{
  "sources": [
    {
      "name": "recv",
      "type": "built-in",
      "category": "network",
      "description": "Receive data from socket"
    },
    {
      "name": "custom_get_input",
      "type": "discovered",
      "category": "user-input",
      "reasoning": "Calls recv(), returns buffer, name contains 'input'"
    }
  ]
}
```

## Validation / 验证

After discovery, validate:
1. Sources are actually present in CPG (check with Joern)
2. Sinks match vulnerability types being searched
3. Custom sources have clear evidence
4. No duplicate entries

## Example / 示例

```
User: "What are the taint sources in this binary?"
Agent: [Uses source-sink-discovery]
       [Loads built-in definitions]
       [Queries CPG for custom functions]
       [Analyzes function names and pseudo-code]
Output: "Found 12 sources: 8 built-in (recv, read, getenv, etc.)
        and 4 custom (process_user_input, get_client_data, etc.)"
```

## Integration / 集成

**Used by:**
- taint-analysis (requires sources/sinks as input)

**Uses:**
- cpg-construction (queries CPG for functions)
- binary-analysis (informs discovery based on binary type)
