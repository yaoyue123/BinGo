# Taint Source Functions

Functions that can introduce untrusted data into a program.

## User Input Sources

| Function | Description | Tainted Argument |
|----------|-------------|------------------|
| `scanf` | Formatted input from stdin | All pointer arguments |
| `gets` | Reads line from stdin (unsafe) | Return buffer |
| `fgets` | Reads line from stream | Return buffer |
| `getchar` | Reads character from stdin | Return value |
| `getc` | Reads character from stream | Return value |
| `fgetc` | Reads character from stream | Return value |
| `read` | Reads from file descriptor | Buffer argument |
| `pread` | Reads from file at offset | Buffer argument |
| `fread` | Reads from file stream | Buffer argument |

## Network Sources

| Function | Description | Tainted Argument |
|----------|-------------|------------------|
| `recv` | Receive data from socket | Buffer argument |
| `recvfrom` | Receive data with source | Buffer argument |
| `recvmsg` | Receive message | msg_iov buffers |
| `recvmmsg` | Receive multiple messages | msg_iov buffers |
| `accept` | Accept new connection | Returns new socket fd |

## Environment Sources

| Function | Description | Tainted Argument |
|----------|-------------|------------------|
| `getenv` | Get environment variable | Return value |
| `secure_getenv` | Get env var (security-aware) | Return value |
| `__secure_getenv` | GNU variant of secure_getenv | Return value |

## File Sources

| Function | Description | Tainted Argument |
|----------|-------------|------------------|
| `fread` | Read from FILE stream | Buffer |
| `fgets` | Read line from stream | Buffer |
| `getline` | Read line from stream | *lineptr |
| `getdelim` | Read delimited string | *lineptr |

## Other Sources

| Function | Description | Tainted Argument |
|----------|-------------|------------------|
| `argv` | Command line arguments | argv[1+] |
| `pthread_create` arg | Thread argument | arg parameter |
| `mmap` of fd | Memory map of file content | Returned memory |

## LLM Discovery Patterns

When analyzing pseudo-code, the agent should also identify custom functions that act as sources by looking for:

### Naming Patterns
- `*input*` (user_input, read_input, get_input)
- `*get*` (get_data, get_var, get_param)
- `*read*` (read_user, read_data, read_config)
- `*receive*` (receive_msg, receive_data)
- `*fetch*` (fetch_input, fetch_data)
- `*parse*` (parse_input, parse_config)

### Code Patterns
- Functions that internally call standard sources
- Functions returning pointers/references to buffers
- Callback functions with user data parameters
- Network message handlers
- File parsers
- Configuration readers
