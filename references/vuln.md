# Vulnerability Detection Scripts

## Scripts

### scan_all.sc
Comprehensive vulnerability scan for all vulnerability classes.

**Usage:**
```bash
joern cpg.bin --script vuln-detection/scripts/scan_all.sc [cpg_file] [output_dir]
```

**Output:**
- `vuln-results/buffer_overflow.txt`
- `vuln-results/format_string.txt`
- `vuln-results/command_injection.txt`
- `vuln-results/use_after_free.txt`
- `vuln-results/integer_overflow.txt`
- `vuln-results/null_pointer.txt`
- `vuln-results/summary.txt`

### detect_buffer_overflow.sc
Detailed buffer overflow detection with recommendations.

**Usage:**
```bash
joern cpg.bin --script vuln-detection/scripts/detect_buffer_overflow.sc [output_file]
```

### generate_vuln_report.sc
Generate comprehensive vulnerability report in Markdown format.

**Usage:**
```bash
joern cpg.bin --script vuln-detection/scripts/generate_vuln_report.sc [output_dir]
```

## Custom Patterns

### buffer_overflow_custom.sc
Additional buffer overflow patterns:
- Array access without bounds check
- Large stack allocations
- Unsafe type casts

To use:
```scala
// Load in Joern REPL
exec(vuln-detection/assets/patterns/buffer_overflow_custom.sc)
```

## Detection Categories

| Script | Vulnerability Types |
|--------|-------------------|
| scan_all.sc | All vulnerability classes |
| detect_buffer_overflow.sc | Buffer overflows only |
| (custom) | Add your own patterns |

## Output Formats

- `.txt` - Text reports with details
- `.md` - Markdown reports for documentation
- Summary files - Quick overview

## Adding New Patterns

1. Create new `.sc` file in `scripts/`
2. Define detection query using Joern DSL
3. Add vulnerability classification
4. Generate report with findings
