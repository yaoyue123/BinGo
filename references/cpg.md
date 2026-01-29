# CPG Construction Scripts

## Scripts

### build_cpg.sh
Main script for building CPGs from Ghidra projects with validation.

**Usage:**
```bash
./build_cpg.sh <ghidra_project_path> <output_cpg_path> [options]
```

**Options:**
- `--memory <size>` - JVM memory (default: 8G)
- `--verbose` - Enable verbose output

**Example:**
```bash
./build_cpg.sh ~/ghidra-projects/VulnBinary ./cpg.bin --memory 16G --verbose
```

### build_cpg.sc
Scala script for direct CPG building using Joern's API.

**Usage:**
```bash
joern --script cpg-construction/scripts/build_cpg.sc <ghidra_project> [output_path]
```

## Workflow

1. Prepare Ghidra project (via `ghidra-decompile` skill)
2. Run `build_cpg.sh` to construct CPG with validation
3. Verify output in `cpg-validation.txt`

## Output

- `cpg.bin` - Binary CPG file
- `cpg-build.log` - Construction log
- `cpg-validation.txt` - Validation report with statistics
