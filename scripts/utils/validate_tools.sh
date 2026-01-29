#!/bin/bash
# Validate all tools are available and working

echo "Tool Validation Check"
echo "===================="
echo ""

# Check Ghidra
echo -n "Ghidra: "
if [ -x ~/bin/ghidra ]; then
    echo "✓ Found"
    ~/bin/ghidra_12.0.1_PUBLIC/support/analyzeHeadless -help 2>&1 | head -1
else
    echo "✗ Not found"
    exit 1
fi

# Check Joern
echo -n "Joern: "
if [ -x ~/bin/joern ]; then
    echo "✓ Found"
else
    echo "✗ Not found"
    exit 1
fi

# Check Radare2
echo -n "Radare2: "
if [ -x ~/bin/r2 ]; then
    echo "✓ Found"
    r2 --version | head -1
else
    echo "✗ Not found"
    exit 1
fi

# Check Java
echo -n "Java: "
if [ -x ~/bin/java ]; then
    echo "✓ Found"
    ~/bin/java -version 2>&1 | head -1
else
    echo "✗ Not found"
    exit 1
fi

echo ""
echo "All tools validated successfully!"
