---
description: Analyze binary file for security vulnerabilities using BinGo
disable-model-invocation: true
---

Invoke the `bingo:binary-vuln-assessment` skill and follow it exactly to analyze a binary file for security vulnerabilities.

**Usage:**
- The user should provide: binary file path and optional output directory
- Example: "Analyze `/path/to/binary.elf` for vulnerabilities"
- Example: "Use bingo to check `firmware.bin` for security issues"

**What it does:**
1. Extracts binary metadata (architecture, security features)
2. Builds Code Property Graph with Joern binary2cpg
3. Identifies source functions (untrusted input) and sink functions (dangerous operations)
4. Tracks data flows using Joern taint analysis
5. Audits findings with STRICT 5-check verification
6. Generates vulnerability report with complete evidence and PoCs

**Vulnerabilities detected:**
- Buffer Overflow (strcpy, strcat, sprintf, memcpy without bounds checking)
- Format String (user input controls printf format parameter)
- Command Injection (user input reaches system(), execve())
- Integer Overflow (integer arithmetic bypasses size checks)

**Requirements:**
- Joern CLI must be installed and in PATH
- Binary must be ELF, PE, or Mach-O format

**See also:** `bingo:cpg-construction` for CPG building only, `bingo:taint-analysis` for data flow analysis only
