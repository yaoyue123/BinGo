#!/bin/bash
# BinGo - Main Analysis Script
# Orchestrates the complete vulnerability analysis pipeline using Joern

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <binary> [output_dir]"
    echo ""
    echo "MANDATORY: Joern CLI with binary2cpg must be installed"
    echo ""
    echo "Stages:"
    echo "  1. Binary Info Analysis"
    echo "  2. CPG Construction (Joern binary2cpg - MANDATORY)"
    echo "  3. Source/Sink Identification"
    echo "  4. Joern Taint Analysis"
    echo "  5. STRICT Vulnerability Audit + Report Generation"
    exit 1
}

BINARY="$1"
OUTPUT_DIR="${2:-./bingo_output}"

if [ -z "$BINARY" ] || [ ! -f "$BINARY" ]; then
    usage
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VULRE_BASE="$(dirname "$SCRIPT_DIR")"

mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}BinGo - Binary Vulnerability Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Binary: $BINARY"
echo "Output: $OUTPUT_DIR"
echo ""

# Stage 1: Binary Info
echo -e "${GREEN}[1/5] Binary Info Analysis${NC}"
"$SCRIPT_DIR/binary_info.sh" "$BINARY" "$OUTPUT_DIR"
echo ""

# Stage 2: CPG Construction (MANDATORY: Joern only)
echo -e "${GREEN}[2/5] CPG Construction (Joern binary2cpg)${NC}"
CPG_FILE="$OUTPUT_DIR/cpg.bin"

# MANDATORY: Use Joern native binary2cpg
echo -e "${GREEN}Building CPG using Joern binary2cpg (MANDATORY)${NC}"
if ! "$SCRIPT_DIR/cpg/build_cpg_native.sh" "$BINARY" "$CPG_FILE"; then
    echo -e "${RED}Error: Joern binary2cpg failed${NC}"
    echo -e "${RED}This tool REQUIRES Joern. No fallback alternatives exist.${NC}"
    echo -e "${RED}Please ensure Joern is installed: https://joern.io${NC}"
    exit 1
fi

echo -e "${GREEN}CPG construction complete${NC}"
echo ""

# Stage 3: Source/Sink Identification (Agent-driven)
echo -e "${GREEN}[3/5] Source/Sink Identification${NC}"
echo "This stage requires Agent analysis of CPG and binary structure."
echo "Built-in sources/sinks are pre-configured."
echo ""

# Create default sources.json
cat > "$OUTPUT_DIR/sources.json" <<'EOF'
["scanf", "gets", "fgets", "read", "recv", "recvfrom", "getenv", "fread", "fgetc"]
EOF

# Create default sinks.json
cat > "$OUTPUT_DIR/sinks.json" <<'EOF'
["strcpy", "strcat", "sprintf", "memcpy", "memset", "bcopy", "system", "exec", "popen", "execl", "execle", "execlp", "execv", "printf", "fprintf", "snprintf", "syslog"]
EOF

echo "Default sources.json and sinks.json created."
echo "Agent should review CPG to discover custom sources."
echo ""

# Stage 4: Joern Taint Analysis
echo -e "${GREEN}[4/5] Joern Taint Analysis${NC}"

# Check if CPG was built successfully
if [ ! -f "$CPG_FILE" ]; then
    echo -e "${RED}Error: CPG file not found at $CPG_FILE${NC}"
    exit 1
fi

echo "CPG file: $CPG_FILE"
echo "Method: Joern binary2cpg"
echo ""
echo "To run data flow analysis manually:"
echo "  joern $CPG_FILE --script $SCRIPT_DIR/joern/dataflow.sc \\"
echo "    $OUTPUT_DIR/sources.json $OUTPUT_DIR/sinks.json $OUTPUT_DIR/flows"
echo ""

# Check if we can run Joern
if command -v joern &> /dev/null; then
    echo "Joern found. Ready for data flow analysis."
    mkdir -p "$OUTPUT_DIR/flows"
    # Joern taint analysis would go here
    # For now, placeholder for Agent to execute
else
    echo -e "${YELLOW}Joern not found in PATH. Agent must install and run manually.${NC}"
fi
echo ""

# Stage 5: Strict Vulnerability Audit + Report Generation
echo -e "${GREEN}[5/5] STRICT Vulnerability Audit + Report Generation${NC}"
echo ""
echo -e "${RED}CRITICAL: All findings must pass strict audit criteria${NC}"
echo ""
echo "Audit Checklist for each finding:"
echo "  [ ] Complete data flow trace"
echo "  [ ] Source verified as untrusted"
echo "  [ ] Sink verified as dangerous"
echo "  [ ] Protections verified absent"
echo "  [ ] False positives ruled out"
echo ""
echo "Only report findings that pass ALL audit checks."
echo ""
echo "Agent should:"
echo "  1. Review each flow in $OUTPUT_DIR/flows/"
echo "  2. Run STRICT audit on each flow (see SKILL.md for details)"
echo "  3. Confirm ONLY vulnerabilities that pass ALL audit checks"
echo "  4. Generate vulnerability_report.md using: $VULRE_BASE/templates/report.md"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Pipeline Setup Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Next steps (Agent):"
echo "  1. Run Joern data flow analysis: joern $CPG_FILE --script .../dataflow.sc"
echo "  2. Update sources.json with discovered custom sources"
echo "  3. Run STRICT audit on each flow"
echo "  4. Generate vulnerability_report.md (ONLY for audited vulnerabilities)"
echo ""
