#!/bin/bash
# BinGo - Binary Fast Analysis
# Extracts basic binary metadata for analysis strategy selection

set -e

BINARY="$1"
OUTPUT_DIR="${2:-.}"

if [ -z "$BINARY" ] || [ ! -f "$BINARY" ]; then
    echo "Usage: $0 <binary> [output_dir]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

OUTPUT_JSON="$OUTPUT_DIR/binary_info.json"

# Gather binary information
FILE_TYPE=$(file "$BINARY")
ARCH=$(echo "$FILE_TYPE" | grep -oE 'x86-64|x86|ARM|aarch64|MIPS' | head -1)
FORMAT=$(echo "$FILE_TYPE" | grep -oE 'ELF|PE|Mach-O' | head -1)

# Detect compiler from strings
COMPILER=$(strings "$BINARY" | grep -iE 'gcc|clang|mingw|llvm|visual studio' | head -1)
if [ -z "$COMPILER" ]; then
    COMPILER="unknown"
fi

# Check security features
NX=$(readelf -l "$BINARY" 2>/dev/null | grep -q 'GNU_STACK' && echo 'enabled' || echo 'disabled')
PIE=$(readelf -h "$BINARY" 2>/dev/null | grep -q 'DYN' && echo 'enabled' || echo 'disabled')
CANARY=$(strings "$BINARY" | grep -q '__stack_chk_fail' && echo 'enabled' || echo 'disabled')
RELRO=$(readelf -l "$BINARY" 2>/dev/null | grep -q 'GNU_RELRO' && echo 'partial' || echo 'disabled')

# Function counts
IMPORTED_FUNCS=$(nm -D "$BINARY" 2>/dev/null | wc -l || echo "0")
EXPORTED_FUNCS=$(nm -D "$BINARY" 2>/dev/null | grep -w 'T' | wc -l || echo "0")

# Interesting strings
STRINGS_OUTPUT="$OUTPUT_DIR/interesting_strings.txt"
strings "$BINARY" | grep -iE 'password|secret|flag|key|input|user|admin|login|cmd|exec|system|shell' | head -50 > "$STRINGS_OUTPUT"

# Output JSON
cat > "$OUTPUT_JSON" <<EOF
{
  "file": "$BINARY",
  "file_type": "$FILE_TYPE",
  "format": "$FORMAT",
  "architecture": "$ARCH",
  "compiler": "$COMPILER",
  "security": {
    "nx": "$NX",
    "pie": "$PIE",
    "canary": "$CANARY",
    "relro": "$RELRO"
  },
  "functions": {
    "imported": $IMPORTED_FUNCS,
    "exported": $EXPORTED_FUNCS
  },
  "interesting_strings": "$STRINGS_OUTPUT"
}
EOF

echo "Binary info saved to: $OUTPUT_JSON"
jq '.' "$OUTPUT_JSON" 2>/dev/null || cat "$OUTPUT_JSON"
