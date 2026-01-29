# BinGo Quick Start Guide / 快速入门指南

**Get results in 5 minutes** / **5 分钟获得结果**

---

## Prerequisites Check / 前置检查 (30 seconds / 30 秒)

### Verify Joern Installation / 验证 Joern 安装

```bash
./bingo/scripts/joern/validate_joern.sh
```

**If Joern is found:** ✅ You're ready to analyze!
**如果找到 Joern：** ✅ 准备就绪！

**If Joern is NOT found:** Install it first (see below)
**如果未找到 Joern：** 先安装（见下文）

---

## Install Joern (One Time Only / 仅一次) / 安装 Joern

```bash
# Clone Joern repository / 克隆 Joern 仓库
git clone https://github.com/joernio/joern ~/joern
cd ~/joern

# Build Joern (takes 5-10 minutes) / 构建 Joern（需 5-10 分钟）
./build.sh

# Add to PATH / 添加到 PATH
export PATH=$PATH:~/joern

# Verify installation / 验证安装
joern --version
```

**Why Joern?** Joern is required for Code Property Graph construction and taint analysis. It's the only tool that performs native binary-to-CPG conversion.
**为什么需要 Joern？** Joern 是构建代码属性图和进行污点分析的必要工具。它是唯一执行原生二进制到 CPG 转换的工具。

---

## Option 1: Analyze Your Binary (30 seconds / 30 秒)
## 选项 1：分析你的二进制文件

```bash
./bingo/scripts/analyze.sh /path/to/binary.elf ./output
```

**That's it!** BinGo will:
**就这样！** BinGo 将：

1. Extract binary metadata / 提取二进制元数据
2. Build Code Property Graph / 构建代码属性图
3. Identify sources and sinks / 识别源和汇
4. Track data flows / 追踪数据流
5. Audit findings (STRICT 5-check audit) / 审计发现（严格 5 项检查）
6. Generate detailed report / 生成详细报告

**View your report:** / **查看报告：**
```bash
cat ./output/vulnerability_report.md
```

---

## Option 2: Try Example Binary (2 minutes / 2 分钟)
## 选项 2：尝试示例二进制文件

### Step 1: Compile Test Binary / 编译测试二进制

```bash
./bingo/tests/binaries/compile_test_binaries.sh
```

This creates a vulnerable test binary with intentional buffer overflow.
这将创建一个带有故意缓冲区溢出的漏洞测试二进制。

### Step 2: Analyze It / 分析它

```bash
./bingo/scripts/analyze.sh ./tests/binaries/vulnerable_buffer ./example_output
```

### Step 3: View Results / 查看结果

```bash
cat ./example_output/vulnerability_report.md
```

**Expected output:** You should see 1 buffer overflow vulnerability with complete data flow trace.
**预期输出：** 您应该看到 1 个缓冲区溢出漏洞，包含完整的数据流追踪。

---

## Understanding Your Results / 理解结果

### What You'll See / 您将看到什么

The report contains:
报告包含：

- **Executive Summary** / **执行摘要**
  - Total vulnerabilities found / 发现的漏洞总数
  - Severity breakdown / 严重性细分

- **Vulnerability Details** / **漏洞详情**
  - Complete data flow from source to sink / 从源到汇的完整数据流
  - Pseudo-code showing the vulnerable path / 显示漏洞路径的伪代码
  - Severity and exploitability / 严重性和可利用性
  - Proof-of-concept exploit / 概念验证利用

- **Audit Results** / **审计结果**
  - All 5 STRICT audit checks / 所有 5 项严格审计检查
  - Only confirmed vulnerabilities are reported / 仅报告已确认的漏洞

### Severity Levels / 严重性级别

| Level / 级别 | Description / 说明 | Action / 行动 |
|-------------|------------------|---------------|
| **Critical** / **严重** | Easy exploit, high impact / 易利用，高影响 | Fix immediately / 立即修复 |
| **High** / **高** | Exploitable, significant impact / 可利用，重大影响 | Fix soon / 尽快修复 |
| **Medium** / **中** | Requires specific conditions / 需要特定条件 | Fix in next release / 下个版本修复 |
| **Low** / **低** | Hard to exploit, low impact / 难利用，低影响 | Best practice fix / 最佳实践修复 |

---

## Common Issues / 常见问题

### Issue 1: Joern Not Found / 未找到 Joern

**Symptom / 症状：**
```
Error: Joern not found
```

**Solution / 解决方案：**
```bash
# Install Joern (see above) / 安装 Joern（见上文）
git clone https://github.com/joernio/joern ~/joern
cd ~/joern && ./build.sh
export PATH=$PATH:~/joern
```

---

### Issue 2: Binary is Stripped / 二进制被剥离

**Symptom / 症状：**
```
WARNING: CPG has fewer than 100 nodes
Binary may be stripped
```

**What this means / 含义：**
Your binary has no debug symbols. This limits analysis but doesn't prevent it.
您的二进制没有调试符号。这会限制分析，但不会阻止分析。

**What to do / 操作：**
- Analysis continues with limited capabilities / 分析继续，但能力受限
- Consider using unstripped binary if available / 如果可能，考虑使用未剥离的二进制
- Results will focus on functions that ARE present / 结果将专注于存在的函数

---

### Issue 3: No Vulnerabilities Found / 未发现漏洞

**This is NORMAL and GOOD!** / **这是正常和好的！**

**Possible reasons / 可能原因：**
1. Binary has proper input validation / 二进制有适当的输入验证
2. Security protections are in place / 安全保护已到位
3. Sources/sinks don't match binary functions / 源/汇不匹配二进制函数

**What to do / 操作：**
- Celebrate! Your binary is secure / 庆祝！您的二进制是安全的
- If you suspect vulnerabilities exist, try custom sources/sinks / 如果怀疑存在漏洞，尝试自定义源/汇
- See: `bingo/source-sink-discovery/SKILL.md` / 参见：`bingo/source-sink-discovery/SKILL.md`

---

## What's Happening? / 发生了什么？

BinGo performs 6 analysis phases / BinGo 执行 6 个分析阶段：

```
1️⃣ Binary Analysis (fast metadata extraction)
   快速二进制信息收集

2️⃣ CPG Construction (Joern creates code graph)
   Joern 构建代码属性图

3️⃣ Source/Sink Discovery (find input points and dangerous operations)
   发现输入点和危险操作

4️⃣ Taint Analysis (track data flow)
   追踪数据流

5️⃣ STRICT Audit (5 mandatory checks)
   严格审计（5 项检查）

6️⃣ Report Generation (complete evidence with PoCs)
   生成报告（含完整证据和 PoC）
```

**Total time:** 2-10 minutes depending on binary size
**总时间：** 2-10 分钟，取决于二进制大小

---

## Next Steps / 下一步

### For Your Binary / 对于您的二进制

1. **Review the report** / **审查报告**
   - Check severity levels / 检查严重性级别
   - Understand data flow paths / 理解数据流路径

2. **Verify findings** / **验证发现**
   - Each vulnerability passed 5 STRICT checks / 每个漏洞都通过了 5 项严格检查
   - Proof-of-concept exploits provided / 提供了概念验证利用

3. **Plan remediation** / **计划修复**
   - Prioritize by severity / 按严重性优先排序
   - Use pseudo-code to understand fixes / 使用伪代码理解修复方法

### Learn More / 学习更多

- **Full documentation:** `bingo/SKILL.md` / **完整文档：** `bingo/SKILL.md`
- **Individual skills:** `bingo/*/SKILL.md` / **各个技能：** `bingo/*/SKILL.md`
- **Troubleshooting:** `bingo/TROUBLESHOOTING.md` / **故障排除：** `bingo/TROUBLESHOOTING.md`

---

## Quick Commands Reference / 快速命令参考

```bash
# Full analysis / 完整分析
./bingo/scripts/analyze.sh binary.elf ./output

# Binary info only / 仅二进制信息
./bingo/scripts/binary_info.sh binary.elf

# Validate Joern / 验证 Joern
./bingo/scripts/joern/validate_joern.sh

# View report / 查看报告
cat ./output/vulnerability_report.md
```

---

## Need Help? / 需要帮助？

- **Troubleshooting guide:** `bingo/TROUBLESHOOTING.md` / **故障排除指南：** `bingo/TROUBLESHOOTING.md`
- **Full documentation:** `bingo/SKILL.md` / **完整文档：** `bingo/SKILL.md`
- **Individual skill docs:** `bingo/*/SKILL.md` / **各个技能文档：** `bingo/*/SKILL.md`

---

**BinGo v4.0.0** - Binary vulnerability mining made easy / 二进制漏洞挖掘工具

**Generated with [Claude Code](https://claude.ai/code)**
**via [Happy](https://happy.engineering)**
