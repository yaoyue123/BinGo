# Vulnerability Patterns and CWEs

## Buffer Overflow (CWE-120, CWE-119, CWE-125)

### Classic Pattern
```c
void vulnerable(char* input) {
    char buffer[64];
    strcpy(buffer, input);  // No length check
}
```

### Off-by-one
```c
void vulnerable(char* input) {
    char buffer[64];
    memcpy(buffer, input, strlen(input) + 1);  // May write one past
}
```

### Integer Overflow leading to Buffer Overflow
```c
void vulnerable(char* input, int len) {
    char* buffer = malloc(len + 10);  // If len near INT_MAX
    memcpy(buffer, input, len);
}
```

### Detection Criteria
- Sink functions (strcpy, memcpy, sprintf) with tainted source
- No length validation before operation
- Buffer size < maximum input size

## Format String (CWE-134)

### Classic Pattern
```c
void vulnerable(char* user_input) {
    printf(user_input);  // User controls format string
}
```

### Indirect Pattern
```c
void vulnerable(char* user_input) {
    syslog(LOG_INFO, user_input);  // User controls format
}
```

### Detection Criteria
- printf/fprintf/sprintf/syslog with tainted first argument
- No %s format specifier used

## Command Injection (CWE-78)

### Classic Pattern
```c
void vulnerable(char* username) {
    char cmd[100];
    sprintf(cmd, "grep %s /etc/passwd", username);
    system(cmd);  // Command injection if username has shell metachars
}
```

### Detection Criteria
- system/popen with tainted argument
- Argument constructed from user input
- No sanitization of shell metachars (;, &, |, $, `, etc.)

## Use After Free (CWE-416)

### Classic Pattern
```c
void vulnerable() {
    char* ptr = malloc(100);
    free(ptr);
    // ... some code ...
    strcpy(ptr, "still using");  // Use after free
}
```

### Detection Criteria
- free() called on pointer
- Same pointer used again without reassignment
- Data flow after free to usage

## Integer Overflow (CWE-190)

### Classic Pattern
```c
void vulnerable(int len) {
    char* buffer = malloc(len + 10);  // If len = INT_MAX - 5
    memcpy(buffer, src, len);  // Heap overflow
}
```

### Detection Criteria
- Tainted value used in arithmetic
- Result used for allocation or size check
- No overflow checking before use

## NULL Pointer Dereference (CWE-476)

### Classic Pattern
```c
void vulnerable(char* input) {
    char* ptr = get_data(input);  // May return NULL
    strcpy(ptr, "data");  // Crashes if ptr is NULL
}
```

### Detection Criteria
- Function that may return NULL
- Return value used without NULL check

## Path Traversal (CWE-22)

### Classic Pattern
```c
void vulnerable(char* filename) {
    FILE* f = fopen(filename, "r");  // Can access ../../../etc/passwd
}
```

### Detection Criteria
- Tainted path used in file operations
- No validation of path components
- No chroot/sandbox restrictions

## Race Condition / TOCTOU (CWE-367)

### Classic Pattern
```c
void vulnerable(char* filename) {
    if (access(filename, R_OK) == 0) {  // Check
        FILE* f = fopen(filename, "r");  // Use - file may have changed
    }
}
```

### Detection Criteria
- access/check followed by open/use
- No atomic operations used

## Heap Overflow (CWE-122)

### Classic Pattern
```c
void vulnerable(char* input, int claimed_len) {
    char* buffer = malloc(100);
    memcpy(buffer, input, claimed_len);  // claimed_len may be > 100
}
```

### Detection Criteria
- Heap allocation followed by unchecked copy
- Tainted size value
- Size exceeds allocated buffer

## Stack Overflow (CWE-121)

### Classic Pattern
```c
void vulnerable(char* input) {
    char buffer[64];
    gets(buffer);  // Always overflow if input > 63 bytes
}
```

### Detection Criteria
- Stack-allocated buffer
- Unbounded write to buffer
- Tainted input length

## Agent Analysis Checklist

When analyzing a potential vulnerability, the agent should check:

1. **Source Validation**: Is the source actually tainted?
2. **Data Flow**: Is there an uninterrupted path from source to sink?
3. **Sanitization**: Are there any validation/sanitization functions on the path?
4. **Bounds Check**: Is the length/sizes validated before the dangerous operation?
5. **Context**: Can the validation be bypassed (e.g., integer overflow before check)?
6. **Exploitability**: Is the vulnerability actually exploitable?

### Confidence Levels

| Level | Criteria |
|-------|----------|
| **High** | Clear vulnerability, no mitigations, direct exploitation |
| **Medium** | Vulnerability exists, some mitigations that can be bypassed |
| **Low** | Possible vulnerability, requires specific conditions or further analysis |
| **False Positive** | Safe code pattern, proper validation, or not actually vulnerable |
