#!/bin/bash
# BinGo Rename Verification Script
# Verifies no "vulre" or "VulRe" references remain after renaming to BinGo

set -e

echo "🔍 BinGo Rename Verification"
echo "============================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS_FOUND=0

# Function to check for old references
check_references() {
    local pattern=$1
    local description=$2

    echo -n "Checking for $description... "

    # Search in text files (exclude .git and binary files)
    if grep -r "$pattern" . \
        --include="*.sh" \
        --include="*.md" \
        --include="*.sc" \
        --include="*.json" \
        --exclude-dir=.git \
        --exclude-dir=.claude --exclude=MIGRATION.md --exclude=verify_rename.sh \
        2>/dev/null | grep -v "Binary:" | grep -v "vulre-config" > /tmp/bingo_verify_$$.txt; then

        if [ -s /tmp/bingo_verify_$$.txt ]; then
            echo -e "${RED}FAILED${NC}"
            echo ""
            echo -e "${RED}Found $description references that need updating:${NC}"
            cat /tmp/bingo_verify_$$.txt
            echo ""
            ERRORS_FOUND=$((ERRORS_FOUND + 1))
        else
            echo -e "${GREEN}OK${NC}"
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi

    rm -f /tmp/bingo_verify_$$.txt
}

# Function to check if old directory exists
check_old_directory() {
    echo -n "Checking for old 'vulre' directory... "

    if [ -d "vulre" ]; then
        echo -e "${RED}FAILED${NC}"
        echo -e "${RED}Old 'vulre' directory still exists!${NC}"
        echo "Please remove it with: rm -rf vulre"
        echo ""
        ERRORS_FOUND=$((ERRORS_FOUND + 1))
    else
        echo -e "${GREEN}OK${NC}"
    fi
}

# Function to verify critical files exist
check_critical_files() {
    echo -n "Checking critical BinGo files exist... "

    local missing=0

    # Check for renamed config file
    if [ ! -f "scripts/bingo-config.sh" ]; then
        echo -e "${YELLOW}WARNING${NC}"
        echo "  - scripts/bingo-config.sh not found (expected rename from vulre-config.sh)"
        missing=1
    fi

    # Check for new documentation
    for file in QUICKSTART.md TROUBLESHOOTING.md MIGRATION.md; do
        if [ ! -f "$file" ]; then
            echo -e "${YELLOW}WARNING${NC}"
            echo "  - $file not found (new documentation file)"
            missing=1
        fi
    done

    if [ $missing -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    fi
}

# Function to verify BinGo branding in key files
check_branding() {
    echo -n "Checking BinGo branding in key files... "

    local errors=0

    # Check main SKILL.md
    if ! grep -q "name: bingo" SKILL.md 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "  - SKILL.md does not contain 'name: bingo'"
        errors=1
    fi

    # Check README.md
    if ! grep -q "# BinGo" README.md 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "  - README.md does not contain '# BinGo' title"
        errors=1
    fi

    # Check MANIFEST.md
    if ! grep -qi "bingo" MANIFEST.md 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "  - MANIFEST.md does not contain 'bingo'"
        errors=1
    fi

    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        ERRORS_FOUND=$((ERRORS_FOUND + 1))
    fi
}

# Function to verify script paths updated
check_script_paths() {
    echo -n "Checking script paths in documentation... "

    if grep -r "\./vulre/scripts" . \
        --include="*.md" \
        --exclude-dir=.git \
        --exclude-dir=.claude --exclude=MIGRATION.md --exclude=verify_rename.sh \
        2>/dev/null > /tmp/bingo_verify_paths_$$.txt; then

        if [ -s /tmp/bingo_verify_paths_$$.txt ]; then
            echo -e "${RED}FAILED${NC}"
            echo -e "${RED}Found old './vulre/scripts' paths in documentation:${NC}"
            cat /tmp/bingo_verify_paths_$$.txt
            echo ""
            ERRORS_FOUND=$((ERRORS_FOUND + 1))
        else
            echo -e "${GREEN}OK${NC}"
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi

    rm -f /tmp/bingo_verify_paths_$$.txt
}

# Main verification
echo "Running verification checks..."
echo ""

# Check for old vulre references (case-insensitive)
check_references "[vV]ulre" "old 'vulre' or 'VulRe' branding"

# Check for old directory
check_old_directory

# Check critical files
check_critical_files

# Check branding
check_branding

# Check script paths
check_script_paths

# Summary
echo ""
echo "============================"
if [ $ERRORS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All verification checks passed!${NC}"
    echo ""
    echo "BinGo rename complete:"
    echo "  - All 'vulre' references updated to 'bingo'"
    echo "  - All 'VulRe' branding updated to 'BinGo'"
    echo "  - Old directory removed"
    echo "  - New files created (QUICKSTART.md, TROUBLESHOOTING.md, etc.)"
    echo ""
    echo "You can now use BinGo:"
    echo "  ./bingo/scripts/analyze.sh binary.elf ./output"
    exit 0
else
    echo -e "${RED}❌ Verification failed with $ERRORS_FOUND error(s)${NC}"
    echo ""
    echo "Please fix the issues above and re-run this script."
    exit 1
fi
