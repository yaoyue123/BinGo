#!/bin/bash
# BinGo - Joern Installation Validation
# Checks if Joern is properly installed and configured

set -e

echo "=========================================="
echo "Joern Installation Validation"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check 1: joern command
echo "Checking joern command..."
if command -v joern &> /dev/null; then
    JOERN_PATH=$(which joern)
    echo -e "${GREEN}✓ joern found${NC} at $JOERN_PATH"

    # Try to get version
    if joern --version &> /dev/null; then
        VERSION=$(joern --version 2>&1 | head -1)
        echo "  Version: $VERSION"
    else
        echo "  Version: Unable to determine"
    fi
else
    echo -e "${RED}✗ joern command not found${NC}"
    echo "  Please add Joern to your PATH"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: binary2cpg
echo "Checking binary2cpg..."
BINARY2CPG_FOUND=0

# Check multiple locations
BINARY2CPG_LOCATIONS=(
    "$HOME/joern/frontend/binary2cpg"
    "$HOME/bin/joern-cli/binary2cpg"
    "$JOERN_HOME/frontend/binary2cpg"
    "/opt/joern/frontend/binary2cpg"
)

for location in "${BINARY2CPG_LOCATIONS[@]}"; do
    if [ -f "$location" ] && [ -x "$location" ]; then
        echo -e "${GREEN}✓ binary2cpg found${NC} at $location"
        BINARY2CPG_FOUND=1
        break
    fi
done

if [ $BINARY2CPG_FOUND -eq 0 ]; then
    echo -e "${RED}✗ binary2cpg not found${NC}"
    echo "  Checked locations:"
    for location in "${BINARY2CPG_LOCATIONS[@]}"; do
        echo "    - $location"
    done
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Joern execution
echo "Checking Joern execution..."
if command -v joern &> /dev/null; then
    # Try simple Joern command
    TEST_OUTPUT=$(echo 'println("test")' | joern --script - 2>&1)

    if echo "$TEST_OUTPUT" | grep -q "test"; then
        echo -e "${GREEN}✓ Joern execution works${NC}"
    else
        echo -e "${YELLOW}⚠ Joern execution may have issues${NC}"
        echo "  Output: $TEST_OUTPUT"
    fi
else
    echo -e "${RED}✗ Cannot test Joern execution (joern not found)${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: JVM memory
echo "Checking JVM configuration..."
if [ -n "$JOERN_MAX_HEAP_SIZE" ]; then
    echo -e "${GREEN}✓ JOERN_MAX_HEAP_SIZE set${NC}: $JOERN_MAX_HEAP_SIZE"
else
    echo -e "${YELLOW}⚠ JOERN_MAX_HEAP_SIZE not set${NC}"
    echo "  Default will be used (may cause OutOfMemory for large binaries)"
    echo "  Recommended: export JOERN_MAX_HEAP_SIZE=8G"
fi
echo ""

# Summary
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Joern Installation Validated${NC}"
    echo ""
    echo "Joern is ready for BinGo analysis!"
else
    echo -e "${RED}✗ Validation Failed${NC}"
    echo ""
    echo "Please fix the errors above before running BinGo analysis"
fi
echo "=========================================="

exit $ERRORS
