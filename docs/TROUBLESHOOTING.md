# BinGo Troubleshooting Guide / 故障排除指南

**Solutions to common issues** / **常见问题的解决方案**

---

## Installation Issues / 安装问题

### Issue 1: Joern Not Found / 未找到 Joern

**Symptom / 症状：**
```
❌ Error: Joern not found
```

**What happened / 发生了什么：**
BinGo couldn't locate the Joern binary analysis tool.
BinGo 无法找到 Joern 二进制分析工具。

**Why it matters / 为什么重要：**
Joern is required for all binary vulnerability analysis. It creates the Code Property Graph (CPG) that powers our analysis.
Joeng 是所有二进制漏洞分析的必要工具。它创建用于分析的代码属性图（CPG）。

**How to fix (choose one) / 如何修复（三选一）：**

**Option 1: Quick Install (5 minutes) / 选项 1：快速安装（5 分钟）**
```bash
git clone https://github.com/joernio/joern ~/joern
cd ~/joern && ./build.sh
export PATH=$PATH:~/joern
```

**Option 2: Check if Already Installed / 选项 2：检查是否已安装**
```bash
# Search for Joern / 搜索 Joern
find ~ -name joern -type f 2>/dev/null

# If found, add to PATH / 如果找到，添加到 PATH
export PATH=$PATH:/path/to/joern
```

**Option 3: Install Guide / 选项 3：安装指南**
See: https://joern.io/installation

**Verify installation / 验证安装：**
```bash
./bingo/scripts/joern/validate_joern.sh
```

---

### Issue 2: OutOfMemory Error During CPG Construction / CPG 构建时内存不足

**Symptom / 症状：**
```
java.lang.OutOfMemoryError: Java heap space
```

**What happened / 发生了什么：**
Binary is too large for default JVM heap size.
二进制对于默认 JVM 堆大小来说太大了。

**How to fix / 如何修复：**
```bash
# Increase JVM heap size / 增加 JVM 堆大小
export JOERN_MAX_HEAP_SIZE=16G

# Re-run analysis / 重新运行分析
./bingo/scripts/analyze.sh binary.elf ./output
```

**Heap size guide / 堆大小指南：**
| Binary Size / 二进制大小 | Recommended Heap / 推荐堆大小 |
|------------------------|---------------------------|
| < 1 MB | 2G |
| 1-10 MB | 4G |
| 10-50 MB | 8G |
| > 50 MB | 16G or higher / 16G 或更高 |

**Prevention / 预防：**
Add to `~/.bashrc`:
```bash
export JOERN_MAX_HEAP_SIZE=8G
```

---

### Issue 3: Joern Version Incompatible / Joern 版本不兼容

**Symptom / 症状：**
```
Error: binary2cpg not found
Joern version too old
```

**What happened / 发生了什么：**
Joern version is too old or doesn't have binary2cpg frontend.
Joern 版本太旧或没有 binary2cpg 前端。

**How to fix / 如何修复：**
```bash
# Check Joern version / 检查 Joern 版本
joern --version

# Must be 1.1.0 or higher / 必须是 1.1.0 或更高
# If older, update Joern / 如果更旧，更新 Joern
cd ~/joern
git pull
./build.sh
```

---

## Analysis Issues / 分析问题

### Issue 4: No Vulnerabilities Found / 未发现漏洞

**Possible reasons / 可能原因：**

1. **Binary is well-protected** / **二进制保护良好**
   - This is GOOD! / 这是好事！
   - Input validation is working / 输入验证有效
   - Security protections are in place / 安全保护已到位

2. **Sources/sinks don't match binary functions** / **源/汇不匹配二进制函数**
   - Default sources/sinks may not match your binary / 默认源/汇可能不匹配您的二进制
   - Custom source/sink discovery needed / 需要自定义源/汇发现

3. **CPG too small (binary stripped)** / **CPG 太小（二进制被剥离）**
   - See Issue 5 below / 见下面的第 5 个问题

**How to tell which / 如何判断是哪个：**

```bash
# Check CPG size / 检查 CPG 大小
cat ./output/cpg-validation.txt

# If nodeCount < 100: Binary is stripped / 如果 nodeCount < 100：二进制被剥离
# If nodeCount > 100: May need custom sources/sinks / 如果 nodeCount > 100：可能需要自定义源/汇
```

**What to do for each / 每种情况的操作：**

1. **Well-protected binary / 保护良好的二进制：**
   - Celebrate! Your binary is secure / 庆祝！您的二进制是安全的
   - Report will state: "No confirmed vulnerabilities found" / 报告将说明："未发现已确认的漏洞"

2. **Custom sources/sinks needed / 需要自定义源/汇：**
   ```bash
   # Run binary analysis to identify custom functions
   # 运行二进制分析以识别自定义函数
   ./bingo/scripts/binary_info.sh binary.elf

   # Manually specify custom sources
   # 手动指定自定义源
   echo '{"sources": ["custom_read_input", "process_user_data"]}' > custom_sources.json

   # Re-run taint analysis with custom sources
   # 使用自定义源重新运行污点分析
   joern cpg.bin --script dataflow.sc custom_sources.json sinks.json flows/
   ```

3. **Stripped binary / 被剥离的二进制：**
   - See Issue 5 below / 见下面的第 5 个问题

---

### Issue 5: CPG Has Very Few Nodes (< 100) / CPG 节点很少（< 100）

**Symptom / 症状：**
```
WARNING: CPG has fewer than 100 nodes
Binary may be stripped
```

**What this means / 含义：**
Binary has no debug symbols. This limits but doesn't prevent analysis.
二进制没有调试符号。这会限制但不会阻止分析。

**Can I still analyze?** / **还能分析吗？**
- **Yes, but limited** / **可以，但有限**
- Focus on functions that ARE present / 专注于存在的函数
- Consider using unstripped binary if available / 如果可能，考虑使用未剥离的二进制

**How to verify / 如何验证：**
```bash
# Check if binary is stripped / 检查二进制是否被剥离
file binary.elf
# Look for "stripped" in output / 在输出中查找 "stripped"

# Check symbol table / 检查符号表
nm binary.elf | wc -l
# If very low (e.g., < 50 symbols), binary is stripped
# 如果非常低（例如，< 50 个符号），二进制被剥离
```

**What to do / 操作：**
1. **Use unstripped binary if available** / **如果可能，使用未剥离的二进制**
   - Debug builds / 调试版本
   - Development versions / 开发版本
   - Symbols from crash dumps / 从崩溃转储中获取符号

2. **Continue with limited analysis** / **继续有限的分析**
   - Analysis will still run / 分析仍会运行
   - Focus on present functions / 专注于存在的函数
   - May miss vulnerabilities in stripped functions / 可能遗漏被剥离函数中的漏洞

---

### Issue 6: All Flows Fail Audit / 所有流审计失败

**Symptom / 症状：**
```
All flows failed STRICT audit
0/15 flows passed audit
```

**This is NORMAL!** / **这是正常的！**

**What this means / 含义：**
BinGo's strict audit is working correctly. False positives are being filtered out.
BinGo 的严格审计正在正确工作。误报正被过滤掉。

**STRICT audit requires ALL 5 checks to pass / 严格审计要求所有 5 项检查都通过：**
1. Data flow complete / 数据流完整
2. Source verified / 源已验证
3. Sink verified / 汇已验证
4. Protections absent / 保护缺失
5. False positive ruled out / 误报排除

**What to do / 操作：**
- **Report will state:** "No confirmed vulnerabilities found" / **报告将说明：** "未发现已确认的漏洞"
- **This is good:** Your binary is secure / **这是好事：** 您的二进制是安全的
- **Don't worry:** False positives were correctly filtered / **别担心：** 误报被正确过滤

**Example / 示例：**
```
Input:  15 potential data flows found
Audit:  15/15 flows analyzed
Result: 0 passed STRICT audit
Output: "No confirmed vulnerabilities found"
Why:   All flows were false positives (dead code, unreachable, etc.)
```

---

## Performance Issues / 性能问题

### Issue 7: Analysis Taking Too Long / 分析时间过长

**Expected analysis times / 预期分析时间：**

| Binary Size / 二进制大小 | Expected Time / 预期时间 |
|------------------------|----------------------|
| < 1 MB | 1-2 minutes / 1-2 分钟 |
| 1-10 MB | 2-5 minutes / 2-5 分钟 |
| 10-50 MB | 5-15 minutes / 5-15 分钟 |
| > 50 MB | 15-60 minutes / 15-60 分钟 |

**If taking longer than expected / 如果时间超过预期：**

1. **Check JVM heap size** / **检查 JVM 堆大小**
   ```bash
   echo $JOERN_MAX_HEAP_SIZE
   # Should be at least 4G for larger binaries
   # 对于较大的二进制，应至少为 4G
   ```

2. **Check if analysis is hung** / **检查分析是否挂起**
   ```bash
   # Check Joern process / 检查 Joern 进程
   ps aux | grep joern

   # If CPU usage is 0% for > 5 minutes, may be hung
   # 如果 CPU 使用率在 5 分钟以上为 0%，可能挂起
   # Restart with more memory / 用更多内存重新启动
   ```

3. **How to speed up** / **如何加速**
   - Increase heap size / 增加堆大小
   - Use CPG caching (if available) / 使用 CPG 缓存（如果可用）
   - Analyze specific functions only / 仅分析特定函数

**When to be concerned / 何时需要担心：**
- More than 2x expected time / 超过预期时间的 2 倍
- No progress for > 10 minutes / 超过 10 分钟无进展

---

## Error Messages Explained / 错误消息解释

### "Binary format not supported" / "不支持的二进制格式"

**Meaning / 含义：**
Binary is not ELF, PE, or Mach-O format.
二进制不是 ELF、PE 或 Mach-O 格式。

**Solution / 解决方案：**
```bash
# Check file type / 检查文件类型
file binary.elf

# Supported formats / 支持的格式：
# - ELF (Linux) / ELF（Linux）
# - PE (Windows) / PE（Windows）
# - Mach-O (macOS) / Mach-O（macOS）
```

---

### "Could not find entry point" / "找不到入口点"

**Meaning / 含义：**
Binary is corrupted or not a valid executable.
二进制已损坏或不是有效的可执行文件。

**Solution / 解决方案：**
```bash
# Verify binary integrity / 验证二进制完整性
file binary.elf
readelf -h binary.elf

# If output shows errors, binary may be corrupted
# 如果输出显示错误，二进制可能已损坏
```

---

### "Taint analysis failed" / "污点分析失败"

**Meaning / 含义：**
Joern taint tracking encountered an error.
Joern 污点追踪遇到错误。

**Possible causes / 可能原因：**
1. CPG is incomplete / CPG 不完整
2. Sources/sinks not found / 未找到源/汇
3. Internal Joern error / Joern 内部错误

**Solution / 解决方案：**
```bash
# Check CPG validation / 检查 CPG 验证
cat ./output/cpg-validation.txt

# If nodeCount is very low (< 50), see Issue 5
# 如果 nodeCount 非常低（< 50），见问题 5

# Check sources/sinks / 检查源/汇
cat ./output/sources.json
cat ./output/sinks.json

# If empty, see Issue 4 (custom sources/sinks)
# 如果为空，见问题 4（自定义源/汇）
```

---

## Getting Help / 获取帮助

### Diagnostic Commands / 诊断命令

```bash
# 1. Check Joern installation / 检查 Joern 安装
./bingo/scripts/joern/validate_joern.sh

# 2. Check binary info / 检查二进制信息
./bingo/scripts/binary_info.sh binary.elf

# 3. Check CPG validation / 检查 CPG 验证
cat ./output/cpg-validation.txt

# 4. Check sources/sinks / 检查源/汇
cat ./output/sources.json
cat ./output/sinks.json

# 5. Check audit results / 检查审计结果
cat ./output/confirmed_vulns.json
```

### When to Report an Issue / 何时报告问题

**Report if / 报告如果：**
- Error message not listed here / 错误消息未在此列出
- Analysis crashes consistently / 分析持续崩溃
- Verified bug in BinGo itself / BinGo 本身的已验证错误
- Documentation is unclear / 文档不清楚

**Before reporting, gather / 报告前，收集：**
1. Binary file type (`file binary.elf`) / 二进制文件类型
2. Joern version (`joern --version`) / Joern 版本
3. CPG validation output / CPG 验证输出
4. Complete error message / 完整的错误消息

**Report at / 报告地址：**
https://github.com/your-org/bingo/issues

---

## Quick Fixes Summary / 快速修复总结

| Issue / 问题 | Quick Fix / 快速修复 |
|-------------|-------------------|
| Joern not found / 未找到 Joern | `export PATH=$PATH:~/joern` |
| Out of memory / 内存不足 | `export JOERN_MAX_HEAP_SIZE=8G` |
| No vulnerabilities found / 未发现漏洞 | Normal! Binary is secure / 正常！二进制安全 |
| CPG too small / CPG 太小 | Binary is stripped / Use unstripped version / 二进制被剥离 / 使用未剥离版本 |
| Analysis slow / 分析慢 | Increase heap size / 增加堆大小 |
| All flows fail audit / 所有流审计失败 | Normal! False positives filtered / 正常！误报被过滤 |

---

**BinGo v4.0.0** - Binary vulnerability mining made easy / 二进制漏洞挖掘工具

**Generated with [Claude Code](https://claude.ai/code)**
**via [Happy](https://happy.engineering)**
