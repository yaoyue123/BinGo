---
name: joern-automation
description: Use when managing Joern installation, execution, or JVM settings. Triggers: "Joern not found", "install Joern", "check Joern", JVM memory issues. Provides wrapper scripts and validation for all Joern operations.
---

# Joern Automation / Joern 自动化

## Overview / 概述

Manages Joern installation, validation, and execution for all BinGo skills.
管理所有 BinGo 技能的 Joern 安装、验证和执行。

## MANDATORY: Joern for All CPG/Taint Operations / 必须使用 Joern

**CRITICAL:** Joern is NOT optional. All CPG construction and taint analysis MUST use Joern.
**关键：** Joern 不是可选项。所有 CPG 构建和污点分析必须使用 Joern。

## When to Use / 使用场景

Use this skill when:
- Joern not found on system
- User asks to install Joern
- Need to validate Joern installation
- JVM memory issues during analysis
- Need to execute Joern scripts with proper settings

## Installation / 安装

### Quick Install / 快速安装

```bash
# Clone and build Joern
git clone https://github.com/joernio/joern ~/joern
cd ~/joern
./build.sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:~/joern

# Verify installation
joern --version
```

### Validation / 验证

```bash
# Check Joern is available
if ! command -v joern &> /dev/null; then
  echo "ERROR: Joern not found"
  echo "Install from: https://joern.io/installation"
  exit 1
fi

# Check binary2cpg is available
if ! ls ~/joern/frontend/binary2cpg &> /dev/null; then
  echo "ERROR: binary2cpg not found"
  echo "Joern binary frontend is required"
  exit 1
fi

# Test Joern with simple query
joern --script 'println("Joern works!")'
```

## JVM Memory Configuration / JVM 内存配置

### Default Settings / 默认设置

```bash
# Default: Use 4GB heap
export JOERN_MAX_HEAP_SIZE=4G

# For large binaries: Use 8GB heap
export JOERN_MAX_HEAP_SIZE=8G

# For router firmware: Use 16GB heap
export JOERN_MAX_HEAP_SIZE=16G
```

### Detecting Memory Issues / 检测内存问题

**Symptom:** `java.lang.OutOfMemoryError: Java heap space`

**Solution:** Increase heap size
```bash
export JOERN_MAX_HEAP_SIZE=16G
joern cpg.bin --script dataflow.sc
```

## Wrapper Scripts / 包装脚本

### Execute Joern Script with Validation / 执行 Joern 脚本并验证

```bash
#!/bin/bash
# bingo/scripts/joern/exec_joern.sh

SCRIPT="$1"
CPG="$2"
OUTPUT="$3"

# Validate Joern
if ! command -v joern &> /dev/null; then
  echo "ERROR: Joern not found"
  exit 1
fi

# Validate CPG exists
if [ ! -f "$CPG" ]; then
  echo "ERROR: CPG file not found: $CPG"
  exit 1
fi

# Execute with proper memory settings
export JOERN_MAX_HEAP_SIZE=${JOERN_MAX_HEAP_SIZE:-8G}

joern "$CPG" --script "$SCRIPT" > "$OUTPUT" 2>&1

# Check for errors
if grep -qi "error\|exception\|failed" "$OUTPUT"; then
  echo "WARNING: Joern execution may have failed. Check: $OUTPUT"
fi
```

### Build CPG with Auto-detection / 自动检测并构建 CPG

```bash
#!/bin/bash
# bingo/scripts/cpg/build_cpg_native.sh

BINARY="$1"
OUTPUT="$2"

# Detect Joern installation
if [ -n "$JOERN_HOME" ]; then
  BINARY2CPG="$JOERN_HOME/frontend/binary2cpg"
elif [ -f "$HOME/joern/frontend/binary2cpg" ]; then
  BINARY2CPG="$HOME/joern/frontend/binary2cpg"
else
  echo "ERROR: Cannot find binary2cpg"
  echo "Set JOERN_HOME or install to ~/joern"
  exit 1
fi

# Detect architecture from binary
ARCH=$(file "$BINARY" | grep -oE 'x86-64|x86|ARM|aarch64|MIPS' | head -1)

# Build CPG
"$BINARY2CPG" \
  --binary "$BINARY" \
  --output "$OUTPUT" \
  --architecture "$ARCH"
```

## Common Issues / 常见问题

### Issue: Joern Not in PATH / Joern 不在 PATH 中

**Error:** `joern: command not found`

**Solution:**
```bash
# Find Joern installation
find /home -name "joern" -type f 2>/dev/null

# Add to PATH
export PATH=$PATH:/path/to/joern

# Or set JOERN_HOME
export JOERN_HOME=/path/to/joern
```

### Issue: binary2cpg Not Found / binary2cpg 未找到

**Error:** `Cannot find binary2cpg`

**Solution:**
```bash
# Check if Joern is complete
ls ~/joern/frontend/binary2cpg

# If missing, re-build Joern
cd ~/joern
./build.sh
```

### Issue: Out of Memory / 内存不足

**Error:** `java.lang.OutOfMemoryError`

**Solution:**
```bash
# Increase heap size
export JOERN_MAX_HEAP_SIZE=16G

# Or run with JVM args
joern -J-Xmx16g cpg.bin --script dataflow.sc
```

### Issue: Architecture Detection Fails / 架构检测失败

**Error:** `Cannot determine architecture`

**Solution:**
```bash
# Manually specify architecture
./bingo/scripts/cpg/build_cpg_native.sh binary.elf cpg.bin x86-64
```

## Joern Script Library / Joern 脚本库

| Script / 脚本 | Purpose / 目的 | Location / 位置 |
|--------------|--------------|----------------|
| `dataflow.sc` | Taint analysis | `bingo/scripts/joern/` |
| `discover_sources.sc` | Custom source discovery | `bingo/scripts/joern/` |
| `validate_cpg.sc` | CPG validation | `bingo/scripts/joern/` |

## Validation Scripts / 验证脚本

### Validate Joern Installation / 验证 Joern 安装

```bash
#!/bin/bash
# bingo/scripts/joern/validate_joern.sh

echo "Checking Joern installation..."

# Check joern command
if command -v joern &> /dev/null; then
  echo "✅ joern found: $(which joern)"
else
  echo "❌ joern not found"
  exit 1
fi

# Check binary2cpg
if [ -f "$HOME/joern/frontend/binary2cpg" ]; then
  echo "✅ binary2cpg found"
else
  echo "❌ binary2cpg not found"
  exit 1
fi

# Test Joern execution
if joern --script 'println("test")' &> /dev/null; then
  echo "✅ Joern execution works"
else
  echo "❌ Joern execution failed"
  exit 1
fi

echo "✅ Joern installation validated"
```

## Integration / 集成

**Used by:**
- cpg-construction (builds CPG)
- taint-analysis (runs taint tracking)
- source-sink-discovery (queries CPG)

**Provides:**
- Joern installation validation
- JVM memory management
- Script execution wrappers
- Error detection and reporting
