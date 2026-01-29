#!/bin/bash
# BinGo Test Suite: Compile Test Binaries
# Compiles vulnerable binaries for testing

set -e

TEST_DIR="$(dirname "$0")"
BINARIES_DIR="$TEST_DIR"

echo "=========================================="
echo "Compiling BinGo Test Binaries"
echo "=========================================="

# Check for compilers
if ! command -v gcc &> /dev/null; then
    echo "Error: gcc not found. Please install gcc."
    exit 1
fi

# Compile flags
CFLAGS="-O0 -fno-stack-protector -no-pie -z execstack"
WARNINGS="-Wall -Wextra"

echo ""
echo "Compiling test binaries..."
echo "Flags: $CFLAGS"
echo ""

# Test 1: Buffer Overflow
echo "[1/5] Buffer Overflow Test..."
cat > "$BINARIES_DIR/test_buffer_overflow.c" << 'EOF'
#include <stdio.h>
#include <string.h>
#include <unistd.h>

void vulnerable_function(char *input) {
    char buffer[64];
    // VULNERABILITY: No bounds checking
    strcpy(buffer, input);
    printf("Buffer: %s\n", buffer);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input>\n", argv[0]);
        return 1;
    }

    vulnerable_function(argv[1]);
    return 0;
}
EOF

gcc $CFLAGS $WARNINGS -o "$BINARIES_DIR/test_buffer_overflow.elf" "$BINARIES_DIR/test_buffer_overflow.c"
echo "  ✓ Compiled: test_buffer_overflow.elf"

# Test 2: Format String
echo "[2/5] Format String Test..."
cat > "$BINARIES_DIR/test_format_string.c" << 'EOF'
#include <stdio.h>
#include <string.h>

void vulnerable_print(char *user_input) {
    // VULNERABILITY: User input controls format parameter
    printf(user_input);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input>\n", argv[0]);
        return 1;
    }

    vulnerable_print(argv[1]);
    return 0;
}
EOF

gcc $CFLAGS $WARNINGS -o "$BINARIES_DIR/test_format_string.elf" "$BINARIES_DIR/test_format_string.c"
echo "  ✓ Compiled: test_format_string.elf"

# Test 3: Command Injection (simulation)
echo "[3/5] Command Injection Test..."
cat > "$BINARIES_DIR/test_cmd_injection.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void vulnerable_system_call(char *user_input) {
    char command[256];
    // VULNERABILITY: User input reaches system() without sanitization
    sprintf(command, "echo %s", user_input);
    system(command);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input>\n", argv[0]);
        return 1;
    }

    vulnerable_system_call(argv[1]);
    return 0;
}
EOF

gcc $CFLAGS $WARNINGS -o "$BINARIES_DIR/test_cmd_injection.elf" "$BINARIES_DIR/test_cmd_injection.c"
echo "  ✓ Compiled: test_cmd_injection.elf"

# Test 4: Integer Overflow
echo "[4/5] Integer Overflow Test..."
cat > "$BINARIES_DIR/test_integer_overflow.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void vulnerable_allocation(uint32_t size) {
    // VULNERABILITY: Integer overflow bypasses size check
    if (size > 1024) {
        printf("Size too large\n");
        return;
    }

    char *buffer = (char *)malloc(size);
    if (buffer == NULL) {
        printf("Allocation failed\n");
        return;
    }

    // If size overflowed, this writes beyond allocation
    memset(buffer, 'A', size);
    free(buffer);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <size>\n", argv[0]);
        return 1;
    }

    uint32_t size = atoi(argv[1]);
    vulnerable_allocation(size);
    return 0;
}
EOF

gcc $CFLAGS $WARNINGS -o "$BINARIES_DIR/test_integer_overflow.elf" "$BINARIES_DIR/test_integer_overflow.c"
echo "  ✓ Compiled: test_integer_overflow.elf"

# Test 5: Safe Binary (for negative testing)
echo "[5/5] Safe Binary Test..."
cat > "$BINARIES_DIR/test_safe.c" << 'EOF'
#include <stdio.h>
#include <string.h>

void safe_function(char *input) {
    char buffer[64];
    // SAFE: Uses strncpy with proper bounds checking
    strncpy(buffer, input, sizeof(buffer) - 1);
    buffer[sizeof(buffer) - 1] = '\0';
    printf("Buffer: %s\n", buffer);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input>\n", argv[0]);
        return 1;
    }

    safe_function(argv[1]);
    return 0;
}
EOF

# Compile with protections enabled for safe binary
SAFE_CFLAGS="-O2 -fstack-protector-strong -pie -fPIE"
gcc $SAFE_CFLAGS $WARNINGS -o "$BINARIES_DIR/test_safe.elf" "$BINARIES_DIR/test_safe.c"
echo "  ✓ Compiled: test_safe.elf (with protections)"

echo ""
echo "=========================================="
echo "Compilation Complete!"
echo "=========================================="
echo ""
echo "Test binaries created:"
ls -lh "$BINARIES_DIR"/*.elf
echo ""
echo "Use these binaries to test BinGo:"
echo "  ./tests/binaries/test_buffer_overflow.elf    # Buffer overflow vulnerability"
echo "  ./tests/binaries/test_format_string.elf      # Format string vulnerability"
echo "  ./tests/binaries/test_cmd_injection.elf      # Command injection vulnerability"
echo "  ./tests/binaries/test_integer_overflow.elf   # Integer overflow vulnerability"
echo "  ./tests/binaries/test_safe.elf               # Safe binary (no vulnerabilities)"
echo ""
echo "Example usage:"
echo "  ./bingo/scripts/agent/agent_analyze_binary.sh \\"
echo "    ./tests/binaries/test_buffer_overflow.elf \\"
echo "    ./test_output"
