# BinGo Explicit Skill Request Tests

Tests that verify Claude invokes BinGo skills when explicitly requested by name.

## Test Scenarios

Each test verifies that when a user explicitly requests a BinGo skill by name, Claude invokes it correctly.

### Skill List

| Skill | Test Prompt | Expected Behavior |
|-------|-------------|-------------------|
| `bingo:binary-analysis` | "Use bingo:binary-analysis to get info about this binary" | Extracts binary metadata |
| `bingo:cpg-construction` | "Use bingo:cpg-construction to build CPG" | Builds Code Property Graph |
| `bingo:source-sink-discovery` | "Use bingo:source-sink-discovery" | Identifies sources and sinks |
| `bingo:taint-analysis` | "Use bingo:taint-analysis to track data flows" | Runs taint tracking |
| `bingo:vuln-audit` | "Use bingo:vuln-audit to validate findings" | Runs STRICT 5-check audit |
| `bingo:vuln-reporting` | "Use bingo:vuln-reporting to generate report" | Creates vulnerability report |
| `bingo:binary-vuln-assessment` | "Use bingo:binary-vuln-assessment for full analysis" | Runs complete pipeline |
| `bingo:joern-automation` | "Use bingo:joern-automation to check installation" | Validates Joern install |
| `bingo:binary-poc-generator` | "Use bingo:binary-poc-generator" | Creates proof-of-concept exploits |

## Running Tests

```bash
cd tests/explicit-skill-requests
./run-all.sh
```

Or run individual tests:
```bash
./run-test.sh binary-analysis
./run-test.sh cpg-construction
# etc.
```

## Test Structure

```
explicit-skill-requests/
├── prompts/           # Test prompts for each skill
├── run-all.sh         # Run all tests
└── run-test.sh        # Run individual test
```

## Verification

Each test verifies:
1. Skill tool was invoked with correct skill name
2. Skill executed without errors
3. Expected output files were created
4. Output contains expected content

## Troubleshooting

### Skill Not Invoked

If a test shows the skill was not invoked:
- Check skill path is correct: `skills/skill-name/SKILL.md`
- Verify skill has valid frontmatter (name, description)
- Check Claude Code session logs for errors

### Output Files Missing

If output files are not created:
- Verify Joern is installed and accessible
- Check test binary exists: `../binaries/`
- Review skill execution logs

## References

- Main testing guide: `../../docs/testing.md`
- Skill documentation: `../../skills/*/SKILL.md`
