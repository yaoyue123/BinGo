---
description: Build Code Property Graph from binary using Joern
disable-model-invocation: true
---

Invoke the `bingo:cpg-construction` skill and follow it exactly to build a Code Property Graph from a binary file.

**Usage:**
- The user should provide: binary file path and output CPG file path
- Example: "Build CPG from `binary.elf` to `cpg.bin`"
- Example: "Create a Code Property Graph for `firmware.elf`"

**What it does:**
1. Validates Joern installation
2. Runs Joern binary2cpg to convert binary to CPG
3. Validates CPG construction (node count, structure)
4. Outputs CPG statistics for verification

**Output:**
- `cpg.bin` - Code Property Graph file for Joern analysis
- `cpg-validation.txt` - CPG statistics and validation results

**Quality Gate:**
- CPG must have > 100 nodes to be considered valid
- If validation fails, diagnostics are provided

**Requirements:**
- Joern CLI with binary2cpg must be installed
- Binary must be supported format (ELF, PE, Mach-O)

**See also:** `bingo:binary-vuln-assessment` for complete analysis pipeline
