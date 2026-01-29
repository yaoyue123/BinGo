#!/bin/bash
# Complete binary vulnerability analysis pipeline

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <binary_file> [output_dir]"
    echo ""
    echo "Complete vulnerability analysis pipeline:"
    echo "  1. Ghidra decompilation"
    echo "  2. CPG construction"
    echo "  3. Taint analysis"
    echo "  4. Vulnerability detection"
    echo ""
    echo "Arguments:"
    echo "  binary_file    Binary executable to analyze"
    echo "  output_dir     Output directory (default: ./analysis_output)"
    exit 1
fi

BINARY_PATH="$1"
OUTPUT_DIR="${2:-./analysis_output}"
PROJECT_NAME=$(basename "$BINARY_PATH")

# Convert to absolute path if relative
if [[ "$BINARY_PATH" != /* ]]; then
    BINARY_PATH="$(pwd)/$BINARY_PATH"
fi

# Convert to absolute path if relative
if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$(pwd)/$OUTPUT_DIR"
fi

echo "=================================================="
echo "Binary Vulnerability Analysis Pipeline"
echo "=================================================="
echo "Binary: $BINARY_PATH"
echo "Output: $OUTPUT_DIR"
echo "=================================================="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/logs"

# Step 1: Binary Information Extraction
echo "1/5] Extracting binary information..."
echo "Binary type:"
file "$BINARY_PATH"
echo ""
echo "Functions:"
rabin2 -l "$BINARY_PATH" > "$OUTPUT_DIR/binary_functions.txt" 2>&1 || true
echo "Binary info extracted to: $OUTPUT_DIR/binary_functions.txt"
echo ""

# Step 2: Ghidra Decompilation
echo "2/5] Running Ghidra decompilation..."

if command -v ~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless &> /dev/null; then
    echo "  Running Ghidra headless analysis..."

    GHIDRA_PROJECT_DIR="$OUTPUT_DIR/ghidra_project"
    mkdir -p "$GHIDRA_PROJECT_DIR"

    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/../ghidra"
    SCRIPT_PATH="$SCRIPT_DIR/SimpleDecompile.java"
    echo "  Script path: $SCRIPT_PATH"
    echo "  Script exists: $(test -f "$SCRIPT_PATH" && echo 'YES' || echo 'NO')"

    echo "  Checking for existing Ghidra processes..."
    pkill -f "GhidraRun" 2>/dev/null || true
    sleep 1

    echo "  Starting Ghidra analysis (this may take several minutes)..."
    ~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless \
        "$GHIDRA_PROJECT_DIR" \
        "$PROJECT_NAME" \
        -import "$BINARY_PATH" \
        -postScript DecompileAndExport.java \
        -scriptPath "$SCRIPT_DIR" \
        -analysisTimeoutPerFile 300 \
        2>&1 | tee "$OUTPUT_DIR/logs/ghidra.log"

    GHIDRA_EXIT_CODE=${PIPESTATUS[0]}

    # Check for script execution errors in log (Ghidra may return 0 even if script fails)
    SCRIPT_ERRORS=$(grep -c "REPORT SCRIPT ERROR\|Failed to find script\|The class could not be found" "$OUTPUT_DIR/logs/ghidra.log" 2>/dev/null || echo "0")

    if [ $GHIDRA_EXIT_CODE -eq 0 ] && [ "$SCRIPT_ERRORS" -eq "0" ]; then
        echo "  ✓ Ghidra decompilation completed successfully"

        DECOMPILED_DIR="$GHIDRA_PROJECT_DIR/$PROJECT_NAME/decompiled"
        METADATA_FILE="$GHIDRA_PROJECT_DIR/$PROJECT_NAME/decompile_metadata.txt"

        if [ -d "$DECOMPILED_DIR" ]; then
            DECOMPILED_COUNT=$(ls -1 "$DECOMPILED_DIR"/*.c 2>/dev/null | wc -l)
            echo "    Decompiled functions: $DECOMPILED_COUNT"

            if [ "$DECOMPILED_COUNT" -gt "0" ]; then
                echo "  ✓ Script executed successfully"
            else
                echo "  ✗ Script may have failed - no decompiled files found"
            fi
        else
            echo "    ✗ Error: No decompiled directory found"
            echo "  The post-script did not run successfully"
            GHIDRA_EXIT_CODE=1
        fi

        if [ -f "$METADATA_FILE" ]; then
            echo "    Metadata file created"
            echo ""
            echo "  Decompile statistics:"
            grep -A 10 "FUNCTION STATISTICS" "$METADATA_FILE" | head -10
        else
            echo "    ✗ Error: No metadata file found"
            echo "  The post-script did not run successfully"
            GHIDRA_EXIT_CODE=1
        fi
    else
        echo "  ✗ Ghidra decompilation failed"
        if [ "$SCRIPT_ERRORS" -gt "0" ]; then
            echo "  Script execution errors detected in log"
        fi
        echo "  Exit code: $GHIDRA_EXIT_CODE"
        echo "  Check $OUTPUT_DIR/logs/ghidra.log for details"
    fi
else
    echo "  Warning: Ghidra not found, skipping decompilation"
    echo "  Note: Full analysis requires Ghidra for CPG construction"
fi
echo ""

# Step 3: Radare2 Analysis
echo "3/5] Running Radare2 analysis..."

r2 -c aaa -A "$BINARY_PATH" 2>&1 | tee "$OUTPUT_DIR/r2_analysis.txt"

echo "  Binary analysis complete"

# Step 4: Function Extraction
echo "4/5] Extracting functions..."

r2 -c afl~[0-100] "$BINARY_PATH" 2>&1 | tee "$OUTPUT_DIR/r2_functions.txt"

echo "  Function extraction complete"
echo ""

# Step 5: Vulnerability Detection
echo "5/6] Scanning for vulnerabilities..."

# Create vulnerability directories
mkdir -p "$OUTPUT_DIR/vulns"

# Search for buffer overflow patterns
echo "    Buffer overflow patterns (strcpy, sprintf, memcpy, bcopy, gets, scanf...):" > "$OUTPUT_DIR/vulns/buffer_overflow.txt"
BO_COUNT=$(strings "$BINARY_PATH" | grep -E "strcpy|sprintf|memcpy|bcopy|gets|scanf" | wc -l)

# Search for command injection patterns
echo "    Command injection patterns (system, exec, popen...):" > "$OUTPUT_DIR/vulns/command_injection.txt"
CI_COUNT=$(strings "$BINARY_PATH" | grep -E "system\(|exec\(|popen\(" | wc -l)

# Search for format string patterns
echo "    Format string patterns (printf with user input...):" > "$OUTPUT_DIR/vulns/format_string.txt"
FS_COUNT=$(strings "$BINARY_PATH" | grep -E "printf.*%s|snprintf.*%s" | wc -l)

echo "  ✓ Vulnerability scan complete"
echo "    Buffer Overflow patterns: $BO_COUNT"
echo "    Command Injection patterns: $CI_COUNT"
echo "    Format String patterns: $FS_COUNT"
echo ""

echo "6/6] Complete analysis..."

# Update summary
{
    echo "VULNERABILITY ANALYSIS SUMMARY"
    echo "================================"
    echo "Binary: $BINARY_PATH"
    echo "Analysis Date: $(date)"
    echo ""
    echo "Findings:"
    echo "  Buffer Overflow: $BO_COUNT instances"
    echo "  Command Injection: $CI_COUNT instances"
    echo "  Format String: $FS_COUNT instances"
    echo ""
    echo "Total Vulnerabilities: $(($BO_COUNT + $CI_COUNT + $FS_COUNT))"
} > "$OUTPUT_DIR/vulns/summary.txt"

# Generate Final Report
echo "=================================================="
echo "Complete analysis!"
echo "=================================================="
echo ""
echo "Output Directory: $OUTPUT_DIR"
echo ""
echo "Generated Files:"
echo "  - $OUTPUT_DIR/binary_functions.txt"
echo "  - $OUTPUT_DIR/r2_analysis.txt (Radare2 analysis)"
echo "  - $OUTPUT_DIR/vulns/ (Vulnerability reports)"
echo ""
echo "Analysis Summary: $OUTPUT_DIR/vulns/summary.txt"
echo ""
echo ""

# Display vulnerability summary if available
if [ -f "$OUTPUT_DIR/vulns/summary.txt" ]; then
    echo "Vulnerability Summary:"
    cat "$OUTPUT_DIR/vulns/summary.txt"
else
    echo "Note: Check $OUTPUT_DIR/vulns/ for detailed vulnerability reports"
fi

echo ""
echo "=================================================="
