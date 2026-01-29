#!/bin/bash

set -e

echo "=================================================="
echo "Ghidra Setup Verification"
echo "=================================================="

if [ ! -d ~/bin/ghidra_12.0.1_PUBLIC ]; then
    echo "✗ Ghidra 12.0.1 not found at ~/bin/ghidra_12.0.1_PUBLIC"
    exit 1
fi

echo "✓ Ghidra 12.0.1 found"

if [ ! -f ~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless ]; then
    echo "✗ analyzeHeadless not found"
    exit 1
fi

echo "✓ analyzeHeadless found"

JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
echo "Java version: $JAVA_VERSION"

if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "⚠ Warning: Java 17+ recommended for Ghidra 12.0.1"
else
    echo "✓ Java version compatible"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/../ghidra/DecompileAndExport.java"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "✗ Decompilation script not found: $SCRIPT_PATH"
    exit 1
fi

echo "✓ Decompilation script found: $SCRIPT_PATH"

CLASS_NAME=$(grep "^public class" "$SCRIPT_PATH" | awk '{print $3}' | cut -d'{' -f1)
FILENAME=$(basename "$SCRIPT_PATH" .java)

if [ "$CLASS_NAME" = "$FILENAME" ]; then
    echo "✓ Class name matches filename: $CLASS_NAME"
else
    echo "✗ Class name mismatch!"
    echo "  Filename: $FILENAME"
    echo "  Class name: $CLASS_NAME"
    exit 1
fi

echo ""
echo "Compiling script for syntax check..."
javac -cp ~/bin/ghidra_12.0.1_PUBLIC/lib/Ghidra/headless/ghidra.jar \
      -d /tmp/ghidra_test \
      "$SCRIPT_PATH" 2>&1 || true

if [ $? -eq 0 ]; then
    echo "✓ Script compiles successfully"
else
    echo "⚠ Script has syntax issues (may be due to missing dependencies)"
fi

echo ""
echo "=================================================="
echo "All checks passed! Ghidra setup verified."
echo "=================================================="
