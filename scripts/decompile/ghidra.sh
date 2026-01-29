#!/bin/bash
# BinGo - Ghidra Decompilation
# Primary decompilation strategy using Ghidra headless mode

set -e

BINARY="$1"
OUTPUT_DIR="${2:-./decompiled}"
PROJECT_NAME="bingo_analysis_$$"
GHIDRA_PROJECT="/tmp/ghidra-projects/$PROJECT_NAME"

# Find Ghidra installation
GHIDRA_PATH="${GHIDRA_HOME:-~/ghidra}"
if [ ! -d "$GHIDRA_PATH" ]; then
    GHIDRA_PATH="~/ghidra_*"
fi
GHIDRA_HEADLESS=$(find $GHIDRA_PATH -name "analyzeHeadless" -type f 2>/dev/null | head -1)

if [ -z "$GHIDRA_HEADLESS" ]; then
    echo "Error: Ghidra not found. Set GHIDRA_HOME or install Ghidra."
    exit 1
fi

if [ -z "$BINARY" ] || [ ! -f "$BINARY" ]; then
    echo "Usage: $0 <binary> [output_dir]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$GHIDRA_PROJECT"

# Get absolute path to binary
BINARY_ABS=$(realpath "$BINARY")

echo "=== Ghidra Decompilation ==="
echo "Binary: $BINARY_ABS"
echo "Project: $GHIDRA_PROJECT"
echo "Output: $OUTPUT_DIR"
echo ""

# Run Ghidra headless with decompilation script
"$GHIDRA_HEADLESS" "$GHIDRA_PROJECT" "$PROJECT_NAME" \
    -import "$BINARY_ABS" \
    -postScript "bingo/scripts/decompile/decompile_all.java" "$OUTPUT_DIR" \
    -deleteProject \
    -analysisTimeoutPerFile 300

# Check if decompilation succeeded
if [ -f "$OUTPUT_DIR/decompile_metadata.txt" ]; then
    echo "Decompilation completed successfully."
    echo "Functions decompiled: $(cat $OUTPUT_DIR/decompile_metadata.txt | grep -c '^Function:' || echo 0)"
else
    echo "Warning: Expected output files not found."
fi

echo "Output directory: $OUTPUT_DIR"
