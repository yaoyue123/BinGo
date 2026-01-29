#!/bin/bash
# Build CPG directly from binary using Joern's native binary frontend
# This bypasses Ghidra decompilation for faster processing

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <binary_path> <output_cpg_path> [options]"
    echo ""
    echo "Arguments:"
    echo "  binary_path      Path to the binary file to analyze"
    echo "  output_cpg_path  Path for output CPG file"
    echo ""
    echo "Options:"
    echo "  --memory <size>      JVM memory allocation (default: 8G)"
    echo "  --architecture <arch> Binary architecture (default: auto-detect)"
    echo "                      Supported: x86, x86-64, arm, arm64, mips, mips64"
    echo "  --verbose            Enable verbose output"
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

echo "Binary: $BINARY_PATH"
echo "Output CPG: $OUTPUT_CPG"

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
            echo "Warning: Could not auto-detect architecture, defaulting to x86-64"
            ARCHITECTURE="x86-64"
            ;;
    esac
    echo "Auto-detected architecture: $ARCHITECTURE"
fi

# Set JVM options
export JOERN_OPTS="-Xmx$MEMORY_SIZE -Xms2G"

# Build CPG using Joern's native binary frontend
echo "Building CPG from binary using native frontend..."
echo "Architecture: $ARCHITECTURE"

# Create output directory
mkdir -p "$(dirname "$OUTPUT_CPG")"

# Joern binary2cpg invocation
# Note: This uses Joern's native binary parsing capabilities

# Detect Joern installation
BINARY2CPG_CMD=""

# Try multiple possible locations in order of preference
POSSIBLE_LOCATIONS=(
    "$HOME/joern/frontend/binary2cpg"           # Default Joern installation
    "$HOME/bin/joern-cli/binary2cpg"            # Legacy location
    "$JOERN_HOME/frontend/binary2cpg"           # JOERN_HOME env var
    "/opt/joern/frontend/binary2cpg"            # System-wide installation
    "$(which binary2cpg 2>/dev/null)"            # In PATH
)

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -n "$location" ] && [ -f "$location" ] && [ -x "$location" ]; then
        BINARY2CPG_CMD="$location"
        echo "Found binary2cpg at: $BINARY2CPG_CMD"
        break
    fi
done

if [ -z "$BINARY2CPG_CMD" ]; then
    echo "Error: binary2cpg not found"
    echo ""
    echo "Please install Joern with binary frontend support:"
    echo "  1. git clone https://github.com/joernio/joern ~/joern"
    echo "  2. cd ~/joern && ./build.sh"
    echo "  3. export PATH=\$PATH:~/joern"
    echo ""
    echo "Or set JOERN_HOME environment variable to your Joern installation."
    exit 1
fi

# Build the command with architecture parameter
CPG_BUILD_CMD="$BINARY2CPG_CMD \
    --binary \"$BINARY_PATH\" \
    --output \"$OUTPUT_CPG\" \
    --architecture \"$ARCHITECTURE\""

if [ $VERBOSE -eq 1 ]; then
    eval $CPG_BUILD_CMD 2>&1 | tee "$(dirname "$OUTPUT_CPG")/cpg-build-native.log"
else
    eval $CPG_BUILD_CMD > "$(dirname "$OUTPUT_CPG")/cpg-build-native.log" 2>&1
fi

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "Error: Native CPG construction failed (exit code: $BUILD_STATUS)"
    echo "Check log: $(dirname "$OUTPUT_CPG")/cpg-build-native.log"
    echo ""
    echo "Tip: This may happen for obscure binary formats."
    echo "     Set VULRE_CPG_METHOD=ghidra to force Ghidra-based CPG construction."
    exit 1
fi

# Validate CPG
echo "Validating CPG..."

# Detect joern command
JOERN_CMD=""

# Try multiple possible locations
JOERN_LOCATIONS=(
    "$(which joern 2>/dev/null)"                 # In PATH
    "$HOME/joern/joern"                          # Default Joern installation
    "$JOERN_HOME/joern"                          # JOERN_HOME env var
    "/opt/joern/joern"                           # System-wide installation
)

for location in "${JOERN_LOCATIONS[@]}"; do
    if [ -n "$location" ] && [ -f "$location" ] && [ -x "$location" ]; then
        JOERN_CMD="$location"
        break
    fi
done

if [ -z "$JOERN_CMD" ]; then
    echo "Error: joern command not found"
    echo "Please ensure Joern is installed and in your PATH"
    exit 1
fi

VALIDATION_OUTPUT=$("$JOERN_CMD" "$OUTPUT_CPG" --script "
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
    echo "Error: CPG validation failed"
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

readarray -t STATS <<< "$VALIDATION_OUTPUT"
NODE_COUNT=${STATS[0]}
EDGE_COUNT=${STATS[1]}
METHOD_COUNT=${STATS[2]}
FILE_COUNT=${STATS[3]}

# Write validation report
cat > "$(dirname "$OUTPUT_CPG")/cpg-validation-native.txt" << EOF
CPG Validation Report (Native Binary Frontend)
==============================================
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

Method: Native Joern binary2cpg
Status: ✓ Valid
EOF

echo ""
echo "CPG construction complete!"
echo "Output: $OUTPUT_CPG"
echo "File size: $(du -h "$OUTPUT_CPG" | cut -f1)"
echo "Nodes: $NODE_COUNT, Edges: $EDGE_COUNT"
echo "Methods: $METHOD_COUNT, Files: $FILE_COUNT"
echo "Validation: ✓ Passed"
echo "Method: Native binary frontend"
echo ""
echo "Logs:"
echo "  Build log: $(dirname "$OUTPUT_CPG")/cpg-build-native.log"
echo "  Validation: $(dirname "$OUTPUT_CPG")/cpg-validation-native.txt"
