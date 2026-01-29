#!/bin/bash
# CPG Builder - Joern Native Method ONLY
# No fallback, no alternatives - Joern is MANDATORY

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <binary_path> <output_cpg_path> [options]"
    echo ""
    echo "MANDATORY: Joern with binary2cpg must be installed"
    echo "Installation: https://joern.io"
    echo ""
    echo "Options:"
    echo "  --memory <size>      JVM memory allocation (default: 8G)"
    echo "  --architecture <arch> Binary architecture (default: auto)"
    echo "  --verbose            Enable verbose output"
    echo ""
    echo "Supported architectures:"
    echo "  x86, x86-64, arm, arm64, mips, mips64"
    exit 1
fi

BINARY_PATH="$1"
OUTPUT_CPG="$2"
MEMORY_SIZE="${MEMORY_SIZE:-8G}"
ARCHITECTURE="${ARCHITECTURE:-auto}"
VERBOSE=0

# Parse options
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --memory)
            MEMORY_SIZE="$2"
            shift 2
            ;;
        --architecture)
            ARCHITECTURE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary file not found: $BINARY_PATH"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}BinGo CPG Builder (Joern Native)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Binary: $BINARY_PATH"
echo "Output: $OUTPUT_CPG"
echo "Method: Joern binary2cpg (MANDATORY)"
echo ""

# Verify binary is executable/binary
if ! file "$BINARY_PATH" | grep -qE "(ELF|PE|Mach-O)"; then
    echo -e "${RED}Error: Not a recognized binary file${NC}"
    echo "File: $BINARY_PATH"
    echo "Expected: ELF, PE, or Mach-O executable"
    exit 1
fi

# Auto-detect architecture if not specified
if [ "$ARCHITECTURE" = "auto" ]; then
    ARCH_DETECTED=$(file "$BINARY_PATH" | grep -oE "x86-64|x86_64|Intel 80386|i386|ARM|AArch64|MIPS" | head -n 1)
    case "$ARCH_DETECTED" in
        x86-64|x86_64)
            ARCHITECTURE="x86-64"
            ;;
        "Intel 80386"|i386)
            ARCHITECTURE="x86"
            ;;
        AArch64)
            ARCHITECTURE="arm64"
            ;;
        ARM)
            ARCHITECTURE="arm"
            ;;
        MIPS)
            ARCHITECTURE="mips"
            ;;
        *)
            echo -e "${YELLOW}Warning: Could not auto-detect architecture, defaulting to x86-64${NC}"
            ARCHITECTURE="x86-64"
            ;;
    esac
    echo "Auto-detected architecture: $ARCHITECTURE"
fi

# Set JVM options
export JOERN_OPTS="-Xmx$MEMORY_SIZE -Xms2G"

# Create output directory
mkdir -p "$(dirname "$OUTPUT_CPG")"

# Joern binary2cpg invocation
# Note: This uses Joern's native binary parsing capabilities
BINARY2CPG_CMD="$HOME/bin/joern-cli/binary2cpg"

if [ ! -f "$BINARY2CPG_CMD" ]; then
    echo -e "${RED}Error: binary2cpg not found at $BINARY2CPG_CMD${NC}"
    echo ""
    echo "Joern with binary2cpg is REQUIRED for BinGo."
    echo "Please install Joern: https://joern.io"
    echo ""
    echo "If Joern is installed elsewhere, set the correct path in this script."
    exit 1
fi

# Build the command with architecture parameter
CPG_BUILD_CMD="$BINARY2CPG_CMD \
    --binary \"$BINARY_PATH\" \
    --output \"$OUTPUT_CPG\" \
    --architecture \"$ARCHITECTURE\""

echo -e "${GREEN}Building CPG from binary using Joern binary2cpg...${NC}"
echo "Architecture: $ARCHITECTURE"
echo "Memory: $MEMORY_SIZE"
echo ""

if [ $VERBOSE -eq 1 ]; then
    eval $CPG_BUILD_CMD 2>&1 | tee "$(dirname "$OUTPUT_CPG")/cpg-build.log"
else
    eval $CPG_BUILD_CMD > "$(dirname "$OUTPUT_CPG")/cpg-build.log" 2>&1
fi

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "${RED}Error: Joern binary2cpg failed (exit code: $BUILD_STATUS)${NC}"
    echo "Check log: $(dirname "$OUTPUT_CPG")/cpg-build.log"
    echo ""
    echo "This tool requires Joern. No fallback alternatives exist."
    exit 1
fi

# Validate CPG
echo -e "${GREEN}Validating CPG...${NC}"

VALIDATION_OUTPUT=$(~/bin/joern/joern "$OUTPUT_CPG" --script "
    try {
        val nodeCount = cpg.graph.nodeCount
        val edgeCount = cpg.graph.edgeCount
        val methodCount = cpg.method.name.toSet.size
        val fileCount = cpg.file.name.toSet.size

        println(nodeCount)
        println(edgeCount)
        println(methodCount)
        println(fileCount)
    } catch {
        case e: Exception =>
            println(\"ERROR: \" + e.getMessage)
            sys.exit(1)
    }
" 2>&1)

if echo "$VALIDATION_OUTPUT" | grep -q "ERROR"; then
    echo -e "${RED}Error: CPG validation failed${NC}"
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

readarray -t STATS <<< "$VALIDATION_OUTPUT"
NODE_COUNT=${STATS[0]}
EDGE_COUNT=${STATS[1]}
METHOD_COUNT=${STATS[2]}
FILE_COUNT=${STATS[3]}

# Write validation report
cat > "$(dirname "$OUTPUT_CPG")/cpg-validation.txt" << EOF
CPG Validation Report (Joern Native Binary Frontend)
==================================================
Date: $(date)
Binary: $BINARY_PATH
Architecture: $ARCHITECTURE
Output CPG: $OUTPUT_CPG

Statistics:
-----------
Nodes: $NODE_COUNT
Edges: $EDGE_COUNT
Methods: $METHOD_COUNT
Files: $FILE_COUNT

File Size: $(du -h "$OUTPUT_CPG" | cut -f1)

Method: Joern binary2cpg (MANDATORY)
Status: Valid
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CPG Construction Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Output: $OUTPUT_CPG"
echo "File size: $(du -h "$OUTPUT_CPG" | cut -f1)"
echo "Nodes: $NODE_COUNT, Edges: $EDGE_COUNT"
echo "Methods: $METHOD_COUNT, Files: $FILE_COUNT"
echo "Validation: Passed"
echo ""
echo "Logs:"
echo "  Build log: $(dirname "$OUTPUT_CPG")/cpg-build.log"
echo "  Validation: $(dirname "$OUTPUT_CPG")/cpg-validation.txt"
echo ""
