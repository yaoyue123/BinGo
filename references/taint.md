# Data Flow Analysis Scripts

## Scripts

### taint_tracking.sc
Basic taint tracking from common sources to sinks.

**Usage:**
```bash
joern cpg.bin --script dataflow-analysis/scripts/taint_tracking.sc
```

**Output:** `taint_results.txt` with all flow details

### find_flows.sc
Find flows for specific vulnerability patterns (buffer overflow, format string, command injection).

**Usage:**
```bash
joern cpg.bin --script dataflow-analysis/scripts/find_flows.sc
```

### generate_report.sc
Generate Markdown report of all taint findings.

**Usage:**
```bash
joern cpg.bin --script dataflow-analysis/scripts/generate_report.sc [cpg_file] [output_file]
```

**Example:**
```bash
joern cpg.bin --script dataflow-analysis/scripts/generate_report.sc cpg.bin report.md
```

## Customization

Edit source/sink definitions in scripts to match your specific analysis needs:

```scala
// Modify source definitions
val sources = cpg.call.name("your_function|another_function").argument(index)

// Modify sink definitions
val sinks = cpg.call.name("dangerous_func").argument(index)
```

## Output Files

- `taint_results.txt` - Detailed flow information
- `taint_analysis_report.md` - Formatted Markdown report
