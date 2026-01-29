# Ghidra Script Issues - Resolution Summary

## Issues Fixed

### 1. Script Filename Mismatch ✓
**Problem:** The Ghidra script filename didn't match the class name
- Filename: `decompile_and_export_12.java`
- Class name: `DecompileAndExport`

**Solution:** Renamed scripts
- `decompile_and_export_12.java` → `DecompileAndExport.java` (Ghidra 12 compatible)
- `DecompileAndExport.java` → `DecompileAndExport_11.java` (Ghidra 11 backup)

**Result:** Script now loads correctly in Ghidra 12.0.1

### 2. Improved analyze_binary.sh ✓
**Changes:**
- Removed deprecated `-deleteProject` flag (deprecated in Ghidra 12)
- Added process cleanup (`pkill -f "GhidraRun"`) to prevent hanging
- Added exit code checking and detailed error reporting
- Added verification of decompiled output directory
- Added metadata file validation
- Added decompilation statistics display

### 3. Added Setup Verification Script ✓
**Created:** `bingo/scripts/utils/test_ghidra_setup.sh`

**Verifies:**
- Ghidra 12.0.1 installation
- analyzeHeadless availability
- Java version compatibility
- Script file existence
- Class name/filename match
- Basic syntax check

## Usage

### Verify Setup
```bash
cd /home/mcj/workspace/re-skills/bingo/scripts/utils
./test_ghidra_setup.sh
```

### Run Analysis
```bash
cd /home/mcj/workspace/re-skills/bingo/scripts/utils
./analyze_binary.sh /path/to/binary.elf ./output_dir
```

## Output Structure
```
output_dir/
├── logs/
│   └── ghidra.log                    # Detailed Ghidra execution log
├── ghidra_project/
│   └── <project_name>/
│       ├── decompiled/               # Decompiled C files (.c)
│       └── decompile_metadata.txt   # Analysis metadata
├── binary_functions.txt
├── r2_analysis.txt
├── r2_functions.txt
└── vulns/
    └── summary.txt
```

## Troubleshooting

### If Ghidra Hangs
```bash
# Kill existing Ghidra processes
pkill -f "GhidraRun"

# Or kill by PID
ps aux | grep GhidraRun
kill -9 <PID>
```

### If Script Doesn't Execute
Check the log file:
```bash
cat output_dir/logs/ghidra.log
```

Look for:
- Script loading errors
- Decompilation failures
- File I/O errors

### Check Decompiled Output
```bash
# List decompiled functions
ls -1 output_dir/ghidra_project/<project_name>/decompiled/*.c | wc -l

# View metadata
cat output_dir/ghidra_project/<project_name>/decompile_metadata.txt

# View a specific decompiled function
cat output_dir/ghidra_project/<project_name>/decompiled/<function_name>.c
```

## Next Steps

1. **Test with a small binary first**
   ```bash
   ./analyze_binary.sh /path/to/small_binary ./test_output
   ```

2. **Verify output**
   - Check `ghidra.log` for errors
   - Confirm `decompiled/` directory exists
   - Review `decompile_metadata.txt` for statistics

3. **Proceed with full analysis**
   - Use larger binaries once verified
   - Monitor memory usage (Ghidra can be memory intensive)
   - Adjust `-analysisTimeoutPerFile` if needed (default: 300 seconds)

## Known Limitations

1. **Memory Usage:** Ghidra headless mode requires significant RAM (4GB+ recommended)
2. **Timeout:** Large binaries may exceed the 300-second timeout per file
3. **Auto-named Functions:** Functions starting with `FUN_`, `sub_`, `thunk_`, `stub_` are skipped

## Performance Tips

1. **Increase Ghidra memory:**
   ```bash
   export VMARGS="-Xmx8G"
   ~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless ...
   ```

2. **Reduce timeout for quick tests:**
   ```bash
   -analysisTimeoutPerFile 60
   ```

3. **Reuse projects:** Skip `-import` for subsequent runs on same binary
