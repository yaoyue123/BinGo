# Taint Sink Functions

Functions where tainted data can cause vulnerabilities.

## Buffer Overflow Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `strcpy` | Buffer Overflow | src (arg 2) | No length check |
| `strcat` | Buffer Overflow | src (arg 2) | No length check |
| `sprintf` | Buffer Overflow | format string (arg 2+) | No length check |
| `vsprintf` | Buffer Overflow | va_list args | No length check |
| `scanf` | Buffer Overflow | format arguments | Can overflow buffers |
| `gets` | Buffer Overflow | (buffer in stdin) | Always unsafe |
| `memcpy` | Buffer Overflow | src (arg 2), size (arg 3) | Size must be validated |
| `memmove` | Buffer Overflow | src (arg 2), size (arg 3) | Size must be validated |
| `memset` | Buffer Overflow | size (arg 3) | Size must be validated |
| `bcopy` | Buffer Overflow | src, size | Size must be validated |
| `strncpy` | Buffer Overflow (possible) | src (arg 2), size (arg 3) | May not null-terminate |
| `strncat` | Buffer Overflow (possible) | src (arg 2), size (arg 3) | Size calculation error |
| `snprintf` | Buffer Overflow (rare) | format arguments | Return value misuse |
| `sscanf` | Buffer Overflow | format arguments | Can overflow buffers |

## Format String Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `printf` | Format String | format (arg 1) | If user controls format |
| `fprintf` | Format String | format (arg 2) | If user controls format |
| `sprintf` | Format String | format (arg 2) | Buffer overflow + format |
| `snprintf` | Format String | format (arg 2) | If user controls format |
| `syslog` | Format String | format string | Can be exploited |
| `setproctitle` | Format String | format string | On some systems |
| `printf` variants | Format String | format argument | Including vprintf, etc |

## Command Injection Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `system` | Command Injection | command string | Executes in shell |
| `popen` | Command Injection | command string | Executes in shell |
| `execl`, `execle`, `execlp` | Command Injection (if shell) | arguments | If shell=1 |
| `execv`, `execve`, `execvp` | Command Injection (if shell) | arguments | If shell=1 |

## File Operation Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `fopen` | Path Traversal | pathname | Can access arbitrary files |
| `open` | Path Traversal | pathname | Can access arbitrary files |
| `openat` | Path Traversal | pathname | Can access arbitrary files |
| `access` | Path Traversal | pathname | TOCTOU possible |
| `unlink` | Path Traversal | pathname | Can delete arbitrary files |
| `rmdir` | Path Traversal | pathname | Can delete directories |
| `chmod`, `chown` | Path Traversal | pathname | Can change permissions |
| `link`, `symlink` | Path Traversal | pathname | Can create arbitrary links |

## Memory Corruption Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `malloc` size | Integer Overflow | size argument | Can cause heap overflow |
| `calloc` nmemb | Integer Overflow | count, size | Can cause heap overflow |
| `realloc` size | Integer Overflow | size argument | Can cause heap overflow |
| `alloca` size | Stack Overflow | size argument | Can cause stack overflow |
| `new[]` size | Integer Overflow | size | C++ heap overflow |
| `array new` | Integer Overflow | size | C++ heap overflow |

## Other Dangerous Sinks

| Function | Vulnerability | Tainted Argument | Notes |
|----------|--------------|------------------|-------|
| `free` | Use After Free | pointer | If double-freed or dangling |
| `realloc` ptr | Use After Free | pointer | If invalid pointer |
| `memcpy` size | Heap Overflow | size | If size larger than dest |
| `atol`, `atoi` | Integer Overflow | string | Can overflow conversions |
| `strtol` | Integer Overflow | string | With LONG_MAX etc. |
