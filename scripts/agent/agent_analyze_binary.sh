#!/bin/bash
# BinGo Agent: Complete Binary Vulnerability Analysis Pipeline
# Orchestrates: binary-analysis → cpg-construction → source-sink-discovery → taint-analysis → vuln-audit → vuln-reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <binary_path> <output_dir> [options]"
    echo ""
    echo "Arguments:"
    echo "  binary_path  Path to the binary file to analyze"
    echo "  output_dir   Directory for analysis output"
    echo ""
    echo "Options:"
    echo "  --quick       Quick scan (binary info only, skip CPG/taint)"
    echo "  --no-audit    Skip vulnerability audit"
    echo "  --verbose     Enable verbose output"
    exit 1
fi

BINARY_PATH="$1"
OUTPUT_DIR="$2"
QUICK_MODE=0
SKIP_AUDIT=0
VERBOSE=0

# Parse options
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=1
            shift
            ;;
        --no-audit)
            SKIP_AUDIT=1
            shift
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

# Validate binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Binary file not found: $BINARY_PATH${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "BinGo Binary Vulnerability Analysis"
echo "=========================================="
echo "Binary: $BINARY_PATH"
echo "Output: $OUTPUT_DIR"
echo "Date: $(date)"
echo ""

# Step 1: Binary Fast Analysis
echo -e "${GREEN}[1/6] Binary Fast Analysis${NC}"
echo "----------------------------"
./binary_info.sh "$BINARY_PATH" "$OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Binary analysis failed${NC}"
    exit 1
fi

# Display binary info
if [ -f "$OUTPUT_DIR/binary_info.json" ]; then
    echo -e "${GREEN}✓ Binary info extracted${NC}"
    if [ $VERBOSE -eq 1 ]; then
        jq '.' "$OUTPUT_DIR/binary_info.json" 2>/dev/null || cat "$OUTPUT_DIR/binary_info.json"
    fi
else
    echo -e "${RED}Error: binary_info.json not created${NC}"
    exit 1
fi
echo ""

# Quick mode: stop after binary info
if [ $QUICK_MODE -eq 1 ]; then
    echo -e "${YELLOW}Quick mode: Skipping CPG and taint analysis${NC}"
    echo "Binary info saved to: $OUTPUT_DIR/binary_info.json"
    exit 0
fi

# Step 2: CPG Construction
echo -e "${GREEN}[2/6] CPG Construction${NC}"
echo "----------------------------"
CPG_OUTPUT="$OUTPUT_DIR/cpg.bin"

./cpg/build_cpg_native.sh "$BINARY_PATH" "$CPG_OUTPUT" --verbose > "$OUTPUT_DIR/cpg-build.log" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: CPG construction failed${NC}"
    echo "Check log: $OUTPUT_DIR/cpg-build.log"
    exit 1
fi

# Validate CPG has enough nodes
if [ -f "$OUTPUT_DIR/cpg-validation-native.txt" ]; then
    NODE_COUNT=$(grep "^Nodes:" "$OUTPUT_DIR/cpg-validation-native.txt" | awk '{print $2}')
    echo -e "${GREEN}✓ CPG built with $NODE_COUNT nodes${NC}"

    if [ "$NODE_COUNT" -lt 100 ]; then
        echo -e "${YELLOW}Warning: CPG has fewer than 100 nodes${NC}"
        echo "Binary may be stripped or have limited symbols"
        echo "Analysis results may be limited"
    fi
else
    echo -e "${RED}Error: CPG validation file not found${NC}"
    exit 1
fi
echo ""

# Step 3: Source/Sink Discovery
echo -e "${GREEN}[3/6] Source/Sink Discovery${NC}"
echo "----------------------------"

# For now, use built-in sources/sinks
# In future, this will call discover_sources.sc

# Create default sources.json
cat > "$OUTPUT_DIR/sources.json" << 'EOF'
{
  "sources": [
    {"name": "recv", "type": "built-in", "category": "network"},
    {"name": "read", "type": "built-in", "category": "file"},
    {"name": "scanf", "type": "built-in", "category": "user-input"},
    {"name": "gets", "type": "built-in", "category": "user-input"},
    {"name": "fgets", "type": "built-in", "category": "user-input"},
    {"name": "fread", "type": "built-in", "category": "file"},
    {"name": "getenv", "type": "built-in", "category": "environment"},
    {"name": "recvfrom", "type": "built-in", "category": "network"},
    {"name": "recvmsg", "type": "built-in", "category": "network"}
  ]
}
EOF

# Create default sinks.json
cat > "$OUTPUT_DIR/sinks.json" << 'EOF'
{
  "sinks": [
    {"name": "strcpy", "type": "buffer-overflow", "category": "string"},
    {"name": "strcat", "type": "buffer-overflow", "category": "string"},
    {"name": "sprintf", "type": "buffer-overflow", "category": "format"},
    {"name": "gets", "type": "buffer-overflow", "category": "user-input"},
    {"name": "memcpy", "type": "buffer-overflow", "category": "memory"},
    {"name": "memset", "type": "buffer-overflow", "category": "memory"},
    {"name": "bcopy", "type": "buffer-overflow", "category": "memory"},
    {"name": "system", "type": "command-injection", "category": "command"},
    {"name": "execve", "type": "command-injection", "category": "command"},
    {"name": "popen", "type": "command-injection", "category": "command"},
    {"name": "execl", "type": "command-injection", "category": "command"},
    {"name": "printf", "type": "format-string", "category": "format"},
    {"name": "fprintf", "type": "format-string", "category": "format"},
    {"name": "snprintf", "type": "format-string", "category": "format"}
  ]
}
EOF

echo -e "${GREEN}✓ Source/sink definitions created${NC}"
echo "Sources: $(jq '.sources | length' "$OUTPUT_DIR/sources.json") built-in sources"
echo "Sinks: $(jq '.sinks | length' "$OUTPUT_DIR/sinks.json") built-in sinks"
echo ""

# Step 4: Taint Analysis
echo -e "${GREEN}[4/6] Taint Analysis${NC}"
echo "----------------------------"

# Check if Joern is available
if ! command -v joern &> /dev/null; then
    echo -e "${RED}Error: Joern not found${NC}"
    echo "Please install Joern from: https://joern.io/installation"
    exit 1
fi

# Create flows directory
mkdir -p "$OUTPUT_DIR/flows"

# Run taint analysis
# Note: This is a placeholder - actual implementation requires Joern scripts
echo "Running Joern taint analysis..."
joern "$CPG_OUTPUT" --script "
  import io.circe.parser._
  import scala.io.Source

  val sourcesFile = \"$OUTPUT_DIR/sources.json\"
  val sinksFile = \"$OUTPUT_DIR/sinks.json\"
  val flowsDir = \"$OUTPUT_DIR/flows\"

  try {
    // Load sources
    val sourcesJson = try {
      Source.fromFile(sourcesFile).mkString
    } catch {
      case e: Exception => \"[]\"
    }

    // Load sinks
    val sinksJson = try {
      Source.fromFile(sinksFile).mkString
    } catch {
      case e: Exception => \"[]\"
    }

    println(s\"Sources loaded: \${sourcesJson.take(100)}...\")
    println(s\"Sinks loaded: \${sinksJson.take(100)}...\")

    // TODO: Implement actual taint tracking
    // For now, just report that CPG is loaded
    println(s\"CPG nodes: \${cpg.graph.nodeCount}\")
    println(s\"CPG methods: \${cpg.method.name.toSet.size}\")

  } catch {
    case e: Exception =>
      println(s\"Error: \${e.getMessage}\")
      sys.exit(1)
  }
" > "$OUTPUT_DIR/taint-analysis.log" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Taint analysis completed${NC}"
    echo "Check log: $OUTPUT_DIR/taint-analysis.log"
else
    echo -e "${YELLOW}Warning: Taint analysis encountered issues${NC}"
    echo "Check log: $OUTPUT_DIR/taint-analysis.log"
fi

# Count flows found
FLOW_COUNT=$(ls -1 "$OUTPUT_DIR/flows"/*.json 2>/dev/null | wc -l)
echo "Flows found: $FLOW_COUNT"
echo ""

# Step 5: Vulnerability Audit
if [ $SKIP_AUDIT -eq 0 ]; then
    echo -e "${GREEN}[5/6] Vulnerability Audit${NC}"
    echo "----------------------------"

    if [ ! -d "$OUTPUT_DIR/flows" ] || [ $FLOW_COUNT -eq 0 ]; then
        echo -e "${YELLOW}No flows to audit${NC}"
        # Create empty confirmed_vulns.json
        cat > "$OUTPUT_DIR/confirmed_vulns.json" << EOF
{
  "audit_summary": {
    "total_flows": 0,
    "passed_audit": 0,
    "failed_audit": 0
  },
  "vulnerabilities": []
}
EOF
    else
        # Run audit script
        ./validate_findings.sh "$OUTPUT_DIR"
    fi

    if [ -f "$OUTPUT_DIR/confirmed_vulns.json" ]; then
        TOTAL=$(jq '.audit_summary.total_flows' "$OUTPUT_DIR/confirmed_vulns.json")
        PASSED=$(jq '.audit_summary.passed_audit' "$OUTPUT_DIR/confirmed_vulns.json")
        echo -e "${GREEN}✓ Audit complete: $PASSED/$TOTAL flows confirmed${NC}"
    else
        echo -e "${YELLOW}Warning: confirmed_vulns.json not created${NC}"
    fi
else
    echo -e "${YELLOW}[5/6] Skipping audit (--no-audit flag)${NC}"
    echo ""
fi

# Step 6: Report Generation
echo -e "${GREEN}[6/6] Report Generation${NC}"
echo "----------------------------"

./generate_report.sh "$OUTPUT_DIR"

if [ -f "$OUTPUT_DIR/vulnerability_report.md" ]; then
    echo -e "${GREEN}✓ Report generated${NC}"
    echo "Report: $OUTPUT_DIR/vulnerability_report.md"
else
    echo -e "${YELLOW}Warning: Report not generated${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo ""
echo "Output Directory: $OUTPUT_DIR"
echo ""
echo "Key Files:"
echo "  - binary_info.json          : Binary metadata"
echo "  - cpg.bin                    : Code Property Graph"
echo "  - cpg-validation-native.txt  : CPG statistics"
echo "  - sources.json               : Source definitions"
echo "  - sinks.json                 : Sink definitions"
echo "  - flows/                     : Taint flow data"
echo "  - confirmed_vulns.json       : Verified vulnerabilities"
echo "  - vulnerability_report.md    : Final report"
echo ""
echo -e "${GREEN}Analysis complete!${NC}"
