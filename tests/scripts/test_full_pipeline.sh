#!/bin/bash
# BinGo Test Suite: Full Pipeline Test
# Tests the complete BinGo analysis pipeline

set -e

SCRIPT_DIR="$(dirname "$0")"
VULRE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
BINARIES_DIR="$TEST_DIR/binaries"
OUTPUT_BASE="$TEST_DIR/test_outputs"

echo "=========================================="
echo "BinGo Full Pipeline Test"
echo "=========================================="
echo "BinGo Directory: $VULRE_DIR"
echo "Test Directory: $TEST_DIR"
echo ""

# Check if test binaries exist
if [ ! -f "$BINARIES_DIR/test_buffer_overflow.elf" ]; then
    echo "Test binaries not found. Compiling..."
    "$BINARIES_DIR/compile_test_binaries.sh"
fi

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local binary="$2"
    local expected_vulns="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local output_dir="$OUTPUT_BASE/$test_name"

    echo "=========================================="
    echo "Test $TOTAL_TESTS: $test_name"
    echo "=========================================="
    echo "Binary: $binary"
    echo "Output: $output_dir"
    echo ""

    # Run analysis
    cd "$VULRE_DIR/scripts/agent"
    ./agent_analyze_binary.sh "$BINARIES_DIR/$binary" "$output_dir" --no-audit > /dev/null 2>&1

    # Check results
    if [ -f "$output_dir/binary_info.json" ]; then
        echo "✓ binary_info.json created"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ binary_info.json NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi

    if [ -f "$output_dir/cpg.bin" ]; then
        echo "✓ cpg.bin created"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ cpg.bin NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    if [ -f "$output_dir/cpg-validation-native.txt" ]; then
        NODE_COUNT=$(grep "^Nodes:" "$output_dir/cpg-validation-native.txt" | awk '{print $2}')
        echo "✓ CPG validation: $NODE_COUNT nodes"

        if [ "$NODE_COUNT" -gt 100 ]; then
            echo "  ✓ CPG has sufficient nodes"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "  ⚠ CPG has fewer than 100 nodes (may be stripped)"
        fi
    else
        echo "✗ CPG validation NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    if [ -f "$output_dir/sources.json" ] && [ -f "$output_dir/sinks.json" ]; then
        SOURCE_COUNT=$(jq '.sources | length' "$output_dir/sources.json")
        SINK_COUNT=$(jq '.sinks | length' "$output_dir/sinks.json")
        echo "✓ Source/sink discovery: $SOURCE_COUNT sources, $SINK_COUNT sinks"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ Source/sink files NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    if [ -f "$output_dir/confirmed_vulns.json" ]; then
        CONFIRMED=$(jq '.audit_summary.passed_audit' "$output_dir/confirmed_vulns.json")
        echo "✓ confirmed_vulns.json created: $CONFIRMED vulnerabilities"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ confirmed_vulns.json NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    if [ -f "$output_dir/vulnerability_report.md" ]; then
        echo "✓ vulnerability_report.md created"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ vulnerability_report.md NOT created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    echo ""
}

# Run tests
echo "Starting pipeline tests..."
echo ""

# Test 1: Buffer Overflow Binary
run_test "buffer_overflow" "test_buffer_overflow.elf" ">=1"

# Test 2: Format String Binary
run_test "format_string" "test_format_string.elf" ">=1"

# Test 3: Safe Binary
run_test "safe_binary" "test_safe.elf" "0"

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total checks: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
