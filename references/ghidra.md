# Ghidra Decompilation Reference

## Important Files
- `decompile_and_export.java` - Main decompilation script with metadata export
- Output directory: `<project_dir>/decompiled/`
- Metadata file: `<project_dir>/decompile_metadata.txt`

## Usage
```bash
~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless \
  ~/ghidra-projects \
  <ProjectName> \
  -import <binary> \
  -postScript ghidra-decompile/scripts/decompile_and_export.java
```

## Customization
Edit the `dangerousFuncs` array in the script to customize which functions are flagged as dangerous.

## Output Format
Each decompiled function is saved as `<function_name>.c` with header comments containing:
- Function name
- Memory address
- Byte size
- Parameter count
- Calling convention
