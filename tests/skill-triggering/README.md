# BinGo Skill Triggering Tests

Tests that verify BinGo skills trigger from natural language prompts without explicit skill naming.

## Purpose

These tests ensure that BinGo skill descriptions are sufficiently descriptive that Claude can infer when to use them based on user intent.

## Test Prompts

Each prompt file contains a natural language request that should trigger the corresponding skill:

| Prompt File | Intended Skill | Trigger Phrase |
|-------------|----------------|----------------|
| `analyze-binary.txt` | `bingo:binary-vuln-assessment` | "Analyze this binary for security vulnerabilities" |
| `check-buffer-overflow.txt` | `bingo:binary-vuln-assessment` | "Check for buffer overflow vulnerabilities" |
| `data-flow-analysis.txt` | `bingo:taint-analysis` | "Track data flow from user input" |
| `build-cpg.txt` | `bingo:cpg-construction` | "Build a Code Property Graph" |
| `binary-info.txt` | `bingo:binary-analysis` | "What type of binary is this?" |

## Running Tests

```bash
cd tests/skill-triggering
./run-all.sh
```

Or test individual prompts:
```bash
./run-test.sh analyze-binary.txt
./run-test.sh check-buffer-overflow.txt
```

## Test Format

Each prompt file contains:
1. A natural language request (no explicit skill naming)
2. Expected context (binary file, vulnerability type, etc.)

## Verification

Tests verify:
1. Correct skill was invoked
2. Skill was invoked BEFORE any response to user
3. Skill executed successfully
4. Expected outputs were generated

## Example Test

**Input**: `analyze-binary.txt`
```
Analyze this ELF binary for security vulnerabilities.
The binary is located at: /path/to/test_binary.elf
```

**Expected behavior**:
1. Claude invokes `bingo:binary-vuln-assessment` skill
2. Skill runs the complete analysis pipeline
3. Vulnerability report is generated

## Troubleshooting

### Wrong Skill Invoked

If the wrong skill is invoked:
- Review skill description in `SKILL.md` frontmatter
- Check for conflicting descriptions across skills
- Ensure description is specific to binary analysis

### No Skill Invoked

If no skill is invoked:
- Verify skill description starts with "Use when..."
- Check description includes relevant trigger keywords
- Review skill frontmatter formatting

## References

- Main testing guide: `../../docs/testing.md`
- Skill writing guide: `../../docs/plans/` (see design documents)
