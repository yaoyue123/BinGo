#!/bin/bash
# BinGo - Radare2 Fallback Decompilation
# Fallback decompilation using Radare2 when Ghidra is unavailable

set -e

BINARY="$1"
OUTPUT_DIR="${2:-./decompiled}"

if [ -z "$BINARY" ] || [ ! -f "$BINARY" ]; then
    echo "Usage: $0 <binary> [output_dir]"
    exit 1
fi

# Check if r2 exists
if ! command -v r2 &> /dev/null; then
    echo "Error: r2 (Radare2) not found. Install Radare2."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "=== Radare2 Fallback Decompilation ==="
echo "Binary: $BINARY"
echo "Output: $OUTPUT_DIR"
echo ""

# Get function list first
echo "Analyzing functions..."
r2 -q -c aaa "$BINARY"
r2 -q -c afl "$BINARY" > "$OUTPUT_DIR/function_list.txt"

# Decompile each function
cat "$OUTPUT_DIR/function_list.txt" | while read -r line; do
    # Extract function address/name
    func_addr=$(echo "$line" | awk '{print $1}')
    func_name=$(echo "$line" | awk '{print $3}')

    if [ -n "$func_name" ]; then
        echo "Decompiling: $func_name @ $func_addr"
        r2 -q -c "pdf @ $func_addr" "$BINARY" > "$OUTPUT_DIR/${func_name}.asm" 2>/dev/null || true
    fi
done

# Full binary dump
echo "Generating full pseudo-code dump..."
r2 -q -c 'aaaa; pdc' "$BINARY" > "$OUTPUT_DIR/full_decompiled.c" 2>/dev/null || true

# Metadata
cat > "$OUTPUT_DIR/decompile_metadata.txt" <<EOF
Decompiler: Radare2
Binary: $BINARY
Date: $(date)
Functions: $(wc -l < "$OUTPUT_DIR/function_list.txt")
EOF

echo "Fallback decompilation completed."
echo "Output directory: $OUTPUT_DIR"
