#!/bin/bash
# BinGo Configuration
# Source this file to set environment variables for BinGo

# CPG Construction Method
# Options:
#   auto    - Try native binary2cpg first, fallback to ghidra2cpg (default)
#   native  - Use Joern's native binary frontend (binary2cpg) only
#   ghidra  - Use Ghidra-based CPG construction (ghidra2cpg) only
#
# Usage: export VULRE_CPG_METHOD=auto
export VULRE_CPG_METHOD=${VULRE_CPG_METHOD:-auto}

# JVM Memory Allocation for Joern
# Default: 8G
# Adjust based on available RAM and binary size
#
# Usage: export MEMORY_SIZE=16G
export MEMORY_SIZE=${MEMORY_SIZE:-8G}

# Binary Architecture (for native method)
# Options: auto, x86, x86-64, arm, arm64, mips, mips64
# Default: auto (auto-detect)
#
# Usage: export ARCHITECTURE=x86-64
export ARCHITECTURE=${ARCHITECTURE:-auto}

# Verbose Output
# Set to 1 for detailed logging
#
# Usage: export VULRE_VERBOSE=1
export VULRE_VERBOSE=${VULRE_VERBOSE:-0}

# Joern Installation Paths
# Adjust if Joern is installed in a custom location
export JOERN_BIN=${JOERN_BIN:-"$HOME/bin/joern-cli"}
export JOERN=${JOERN:-"$HOME/bin/joern"}

# Display current configuration if sourced with arguments
if [ $# -gt 0 ] && [ "$1" = "--show" ]; then
    echo "BinGo Configuration:"
    echo "===================="
    echo "CPG Method:        $VULRE_CPG_METHOD"
    echo "Memory Size:       $MEMORY_SIZE"
    echo "Architecture:      $ARCHITECTURE"
    echo "Verbose:           $VULRE_VERBOSE"
    echo "Joern CLI:         $JOERN_BIN"
    echo "Joern:             $JOERN"
    echo ""
fi
