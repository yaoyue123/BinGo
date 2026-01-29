---
name: binary-analysis
description: Use when analyzing compiled binary files to extract metadata. Triggers: user mentions binary, ELF, PE, Mach-O, file type, architecture, security features, NX, PIE, canary, RELRO, or needs to examine binary structure before vulnerability analysis.
---

# Binary Analysis / 二进制分析

## Overview / 概述

Extracts fast binary metadata to inform vulnerability analysis strategy.
提取快速二进制元数据以指导漏洞分析策略。

## When to Use / 使用场景

Use this skill when:
- User mentions "binary", "ELF", "PE", "Mach-O"
- User asks about file type, architecture, or security features
- Need to determine binary structure before CPG construction
- Quick assessment without full vulnerability analysis

## Quick Start / 快速开始

```bash
./bingo/scripts/binary_info.sh /path/to/binary.elf ./output
```

## Output Information / 输出信息

| Category / 类别 | Fields / 字段 |
|----------------|---------------|
| **File Type** | ELF, PE, Mach-O |
| **Architecture** | x86, x64, ARM, MIPS, ARM64 |
| **Compiler** | gcc, clang, mingw |
| **Security** | NX, PIE, Canary, RELRO |
| **Functions** | Imported, exported counts |
| **Strings** | Interesting clues |

## Output Format / 输出格式

```json
{
  "file": "binary.elf",
  "file_type": "ELF 64-bit LSB executable",
  "format": "ELF",
  "architecture": "x86-64",
  "compiler": "gcc",
  "security": {
    "nx": "enabled",
    "pie": "disabled",
    "canary": "enabled",
    "relro": "partial"
  },
  "functions": {
    "imported": 45,
    "exported": 12
  }
}
```

## Security Features Explained / 安全特性说明

| Feature / 特性 | Description / 说明 | Exploit Impact / 利用影响 |
|----------------|-------------------|--------------------------|
| **NX** | No-execute bit / 不可执行位 | Prevents shellcode on stack / 防止栈上 shellcode |
| **PIE** | Position-independent executable / 地址无关可执行 | Hardens ASLR / 加强 ASLR |
| **Canary** | Stack protector / 栈保护 | Detects stack overflow / 检测栈溢出 |
| **RELRO** | Relocation read-only / 重定位只读 | Prevents GOT overwrite / 防止 GOT 覆盖 |

## Agent Usage / Agent 使用

Use binary information to:
- Identify interesting functions for source discovery
- Assess exploit mitigation difficulty
- Inform Joern CPG construction parameters
- Determine if binary is stripped (affects analysis)

## Example / 示例

```
User: "What type of binary is this router firmware?"
Agent: [Uses binary-analysis]
Output: "This is a 32-bit MIPS ELF executable with NX disabled, PIE disabled,
        no canary - highly exploitable."
```
