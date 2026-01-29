# Migrating from VulRe to BinGo / 从 VulRe 迁移到 BinGo

**Upgrade guide for VulRe v3.0.0 users** / **VulRe v3.0.0 用户升级指南**

---

## What Changed? / 有什么变化？

| Aspect / 方面 | VulRe v3.0.0 | BinGo v4.0.0 |
|--------------|-------------|-------------|
| **Name / 名称** | VulRe | BinGo |
| **Focus / 重点** | Production-ready / 生产就绪 | User-friendly / 用户友好 |
| **Quick Start / 快速开始** | ~15 minutes / ~15 分钟 | ~5 minutes / ~5 分钟 |
| **Documentation / 文档** | Comprehensive / 全面 | Progressive levels / 渐进式级别 |
| **Error Messages / 错误消息** | Technical / 技术性 | "What/Why/How to fix" / "什么/为什么/如何修复" |
| **Help / 帮助** | SKILL.md only / 仅 SKILL.md | Interactive mode / 交互模式 |

### What Stayed the Same / 什么保持不变

✅ **All core functionality / 所有核心功能**
- 9 modular skills / 9 个模块化技能
- STRICT audit with 5 checks / 5 项检查的严格审计
- Joern-only backend / 仅 Joern 后端
- Complete automation pipeline / 完整的自动化流水线

✅ **Command-line compatibility / 命令行兼容性**
- Same arguments / 相同的参数
- Same output format / 相同的输出格式
- Same workflow / 相同的工作流程

---

## Update Your Workflows / 更新您的工作流程

### Old Command / 旧命令

```bash
./vulre/scripts/analyze.sh binary.elf ./output
```

### New Command / 新命令

```bash
./bingo/scripts/analyze.sh binary.elf ./output
```

**That's it!** All command-line arguments remain the same.
**就这样！** 所有命令行参数保持不变。

---

## Quick Migration Checklist / 快速迁移清单

- [ ] **Update script paths** / **更新脚本路径**
  - Replace `./vulre/scripts/` with `./bingo/scripts/`
  - Replace `vulre/` with `bingo/` in documentation references

- [ ] **Update documentation links** / **更新文档链接**
  - Old: `vulre/SKILL.md` → New: `bingo/SKILL.md`
  - Old: `vulre/README.md` → New: `bingo/README.md`

- [ ] **Try new features** / **尝试新功能**
  - [ ] Read `bingo/QUICKSTART.md` (5-minute guide / 5 分钟指南)
  - [ ] Check `bingo/TROUBLESHOOTING.md` (enhanced help / 增强的帮助)
  - [ ] Run `./bingo/scripts/joern/validate_joern.sh` (better error messages / 更好的错误消息)

---

## New Features to Try / 试用新功能

### 1. Enhanced Quick Start / 增强的快速开始

**File:** `bingo/QUICKSTART.md`

Get results in 5 minutes with:
5 分钟内获得结果：

- One-command installation / 一键安装
- Example binary walkthrough / 示例二进制演练
- Understanding your results / 理解结果
- Common issues / 常见问题

**Try it / 试试：**
```bash
cat bingo/QUICKSTART.md
```

---

### 2. Comprehensive Troubleshooting / 综合故障排除

**File:** `bingo/TROUBLESHOOTING.md`

Every error message includes:
每个错误消息包括：

- What happened / 发生了什么
- Why it matters / 为什么重要
- How to fix (with copy-paste commands) / 如何修复（含复制粘贴命令）

**Try it / 试试：**
```bash
cat bingo/TROUBLESHOOTING.md
```

---

### 3. Better Error Messages / 更好的错误消息

**Before / 之前：**
```
Error: Joern not found
This tool REQUIRES Joern.
```

**After / 之后：**
```
❌ Error: Joern not found

What happened: BinGo couldn't locate the Joern binary analysis tool.

Why it matters: Joern is required for all binary vulnerability analysis.
          It creates the Code Property Graph (CPG) that powers our analysis.

How to fix (choose one):

  Option 1: Quick install (5 minutes)
  $ git clone https://github.com/joernio/joern ~/joern
  $ cd ~/joern && ./build.sh
  $ export PATH=$PATH:~/joern

  Option 2: Check if already installed
  $ find ~ -name joern -type f 2>/dev/null

  Option 3: Install guide
  See: https://joern.io/installation

Verify installation:
  $ ./bingo/scripts/joern/validate_joern.sh
```

---

### 4. Interactive Mode (Coming Soon) / 交互模式（即将推出）

**File:** `bingo/scripts/bingo.sh`

Guided analysis for new users:
新用户的引导式分析：

```bash
./bingo/scripts/bingo.sh --interactive
```

**Features / 功能：**
- Menu-driven analysis / 菜单驱动分析
- Built-in examples / 内置示例
- Real-time help / 实时帮助
- Progress indicators / 进度指示器

---

## Documentation Updates / 文档更新

### New Structure / 新结构

```
bingo/
├── QUICKSTART.md          ⭐ NEW - 5-minute guide / 5 分钟指南
├── README.md              ✨ Enhanced - User-friendly focus / 用户友好重点
├── TROUBLESHOOTING.md     ⭐ NEW - Comprehensive help / 综合帮助
├── MIGRATION.md           ⭐ NEW - This file / 本文件
├── SKILL.md               ✅ Updated - New branding / 新品牌
└── */SKILL.md             ✅ Updated - All 9 skills / 所有 9 个技能
```

### Progressive Documentation / 渐进式文档

**Level 1: Just Get Me Results** / **只要结果**
- `QUICKSTART.md` - 5-minute guide / 5 分钟指南

**Level 2: Understand What I'm Doing** / **理解我在做什么**
- `README.md` - What each step does / 每步做什么
- `TROUBLESHOOTING.md` - Common issues / 常见问题

**Level 3: Deep Technical Details** / **深入技术细节**
- `SKILL.md` - Complete workflow / 完整工作流程
- `*/SKILL.md` - Individual skills / 各个技能

**Level 4: Contributing** / **贡献**
- Future: `CONTRIBUTING.md` / 将来：`CONTRIBUTING.md`

---

## Example Migration / 迁移示例

### Before (VulRe v3.0.0) / 之前（VulRe v3.0.0）

```bash
# Analyze router firmware / 分析路由器固件
./vulre/scripts/analyze.sh router.bin ./output

# Check documentation / 检查文档
cat vulre/SKILL.md

# Validate Joern / 验证 Joern
./vulre/scripts/joern/validate_joern.sh
```

### After (BinGo v4.0.0) / 之后（BinGo v4.0.0）

```bash
# Analyze router firmware / 分析路由器固件
./bingo/scripts/analyze.sh router.bin ./output

# Check quick start (NEW!) / 检查快速开始（新！）
cat bingo/QUICKSTART.md

# Validate Joern (better errors!) / 验证 Joern（更好的错误！）
./bingo/scripts/joern/validate_joern.sh

# Troubleshooting (NEW!) / 故障排除（新！）
cat bingo/TROUBLESHOOTING.md
```

**Difference / 差异：**
- Same commands / 相同的命令
- Better documentation / 更好的文档
- Enhanced error messages / 增强的错误消息
- More help when needed / 需要时更多帮助

---

## Advanced Migration / 高级迁移

### Update Automation Scripts / 更新自动化脚本

If you have automation scripts using VulRe:
如果您有使用 VulRe 的自动化脚本：

**Before / 之前：**
```bash
#!/bin/bash
VULRE_HOME="/opt/vulre"
${VULRE_HOME}/scripts/analyze.sh $BINARY ${OUTPUT_DIR}
```

**After / 之后：**
```bash
#!/bin/bash
BINGO_HOME="/opt/bingo"
${BINGO_HOME}/scripts/analyze.sh $BINARY ${OUTPUT_DIR}
```

### Update CI/CD Pipelines / 更新 CI/CD 流水线

**Before / 之前：**
```yaml
- name: VulRe Analysis
  run: ./vulre/scripts/analyze.sh binary.elf ./output
```

**After / 之后：**
```yaml
- name: BinGo Analysis
  run: ./bingo/scripts/analyze.sh binary.elf ./output
```

---

## Compatibility Matrix / 兼容性矩阵

| Feature / 功能 | VulRe v3.0.0 | BinGo v4.0.0 | Compatible? / 兼容？ |
|---------------|-------------|-------------|-------------------|
| Command-line arguments / 命令行参数 | ✅ | ✅ | ✅ Yes / 是 |
| Output format / 输出格式 | ✅ | ✅ | ✅ Yes / 是 |
| 9 modular skills / 9 个模块化技能 | ✅ | ✅ | ✅ Yes / 是 |
| STRICT audit / 严格审计 | ✅ | ✅ | ✅ Yes / 是 |
| Joern requirement / Joern 要求 | ✅ | ✅ | ✅ Yes / 是 |
| Configuration / 配置 | ❌ | ✅ | ⚠️ New feature / 新功能 |
| Interactive mode / 交互模式 | ❌ | ✅ | ⚠️ New feature / 新功能 |

---

## Rollback Plan / 回滚计划

If you need to rollback to VulRe v3.0.0:
如果您需要回滚到 VulRe v3.0.0：

```bash
# Clone VulRe v3.0.0 / 克隆 VulRe v3.0.0
git clone https://github.com/your-org/vulre.git -b v3.0.0 ~/vulre

# Use VulRe commands / 使用 VulRe 命令
~/vulre/scripts/analyze.sh binary.elf ./output
```

**Note:** BinGo v4.0.0 is fully backward compatible with VulRe v3.0.0 output formats.
**注意：** BinGo v4.0.0 完全向后兼容 VulRe v3.0.0 输出格式。

---

## Need Help? / 需要帮助？

- **Quick Start:** `bingo/QUICKSTART.md` / **快速开始：** `bingo/QUICKSTART.md`
- **Troubleshooting:** `bingo/TROUBLESHOOTING.md` / **故障排除：** `bingo/TROUBLESHOOTING.md`
- **Full Documentation:** `bingo/SKILL.md` / **完整文档：** `bingo/SKILL.md`
- **Issues:** https://github.com/your-org/bingo/issues

---

## Summary / 总结

**Migration is simple!** / **迁移很简单！**

1. Update paths: `vulre` → `bingo` / 更新路径：`vulre` → `bingo`
2. Read new documentation / 阅读新文档
3. Try new features / 试用新功能

**All functionality preserved.** / **所有功能保留。**

**Better user experience.** / **更好的用户体验。**

---

**BinGo v4.0.0** - Binary vulnerability mining made easy / 二进制漏洞挖掘工具

**Generated with [Claude Code](https://claude.ai/code)**
**via [Happy](https://happy.engineering)**
