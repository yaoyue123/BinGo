#!/bin/bash
# Build CPG from Ghidra project with validation

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <ghidra_project_path> <output_cpg_path> [options]"
    echo ""
    echo "Arguments:"
    echo "  ghidra_project_path  Path to Ghidra project directory"
    echo "  output_cpg_path      Path for output CPG file"
    echo ""
    echo "Options:"
    echo "  --memory <size>      JVM memory allocation (default: 8G)"
    echo "  --verbose            Enable verbose output"
    exit 1
fi

GHIDRA_PROJECT="$1"
OUTPUT_CPG="$2"
MEMORY_SIZE="${MEMORY_SIZE:-8G}"
VERBOSE=0

# Parse options
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --memory)
            MEMORY_SIZE="$2"
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

# Check Ghidra project exists
if [ ! -d "$GHIDRA_PROJECT" ]; then
    echo "Error: Ghidra project directory not found: $GHIDRA_PROJECT"
    exit 1
fi

# Find .gpr file
GPR_FILE=$(find "$GHIDRA_PROJECT" -maxdepth 2 -name "*.gpr" | head -n 1)
if [ -z "$GPR_FILE" ]; then
    echo "Error: No .gpr file found in project directory"
    exit 1
fi

echo "Found Ghidra project: $GPR_FILE"

# Set JVM options
export JOERN_OPTS="-Xmx$MEMORY_SIZE -Xms2G"

# Build CPG
echo "Building CPG..."
if [ $VERBOSE -eq 1 ]; then
    ~/bin/joern-cli/ghidra2cpg \
        --ghidra-path "$GPR_FILE" \
        --output "$OUTPUT_CPG" \
        --language c 2>&1 | tee "$(dirname "$OUTPUT_CPG")/cpg-build.log"
else
    ~/bin/joern-cli/ghidra2cpg \
        --ghidra-path "$GPR_FILE" \
        --output "$OUTPUT_CPG" \
        --language c > "$(dirname "$OUTPUT_CPG")/cpg-build.log" 2>&1
fi

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "Error: CPG construction failed"
    echo "Check log: $(dirname "$OUTPUT_CPG")/cpg-build.log"
    exit 1
fi

# Validate CPG
echo "Validating CPG..."
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
cat > "$(dirname "$OUTPUT_CPG")/cpg-validation.txt" << EOF
CPG Validation Report
=====================
Date: $(date)
Ghidra Project: $GPR_FILE
Output CPG: $OUTPUT_CPG

Statistics:
-----------
Nodes: $NODE_COUNT
Edges: $EDGE_COUNT
Methods: $METHOD_COUNT
Files: $FILE_COUNT

File Size: $(du -h "$OUTPUT_CPG" | cut -f1)

Status: ✓ Valid
EOF

echo ""
echo "CPG construction complete!"
echo "Output: $OUTPUT_CPG"
echo "File size: $(du -h "$OUTPUT_CPG" | cut -f1)"
echo "Nodes: $NODE_COUNT, Edges: $EDGE_COUNT"
echo "Methods: $METHOD_COUNT, Files: $FILE_COUNT"
echo "Validation: ✓ Passed"
echo ""
echo "Logs:"
echo "  Build log: $(dirname "$OUTPUT_CPG")/cpg-build.log"
echo "  Validation: $(dirname "$OUTPUT_CPG")/cpg-validation.txt"
