#!/bin/bash
# BinGo - Path Pseudo-code Extraction
# Extracts pseudo-code for all functions along a data flow path

set -e

FLOW_JSON="$1"
DECOMPILED_DIR="${2:-./decompiled}"
OUTPUT_DIR="${3:-./paths}"

if [ -z "$FLOW_JSON" ] || [ ! -f "$FLOW_JSON" ]; then
    echo "Usage: $0 <flow.json> <decompiled_dir> <output_dir>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Extract flow ID from filename
FLOW_ID=$(basename "$FLOW_JSON" .json)

# Extract function names from the flow JSON
# The JSON contains pathElements with method names
FUNCTIONS=$(jq -r '.pathElements[].method' "$FLOW_JSON" | xargs -n1 basename | sort -u)

echo "=== Extracting Path Code: $FLOW_ID ==="
echo "Functions in path:"
echo "$FUNCTIONS"
echo ""

OUTPUT_FILE="$OUTPUT_DIR/${FLOW_ID}.c"

# Create header
cat > "$OUTPUT_FILE" <<EOF
// Data Flow Path: $FLOW_ID
// Generated from: $FLOW_JSON
//

EOF

# Append code for each function
while IFS= read -r func_name; do
    if [ -n "$func_name" ]; then
        # Find the decompiled file (may have different sanitization)
        # Try exact match first
        DECOMPILED_FILE="$DECOMPILED_DIR/${func_name}.c"

        # Try with underscore sanitization if not found
        if [ ! -f "$DECOMPILED_FILE" ]; then
            SANITIZED=$(echo "$func_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
            DECOMPILED_FILE="$DECOMPILED_DIR/${SANITIZED}.c"
        fi

        if [ -f "$DECOMPILED_FILE" ]; then
            echo "// ===== Function: $func_name =====" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            cat "$DECOMPILED_FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "Extracted: $func_name"
        else
            echo "// ===== Function: $func_name =====" >> "$OUTPUT_FILE"
            echo "// Source not found" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "Warning: Source for $func_name not found"
        fi
    fi
done <<< "$FUNCTIONS"

echo ""
echo "Path code saved to: $OUTPUT_FILE"
wc -l "$OUTPUT_FILE"
