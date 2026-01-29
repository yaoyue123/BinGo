import io.shiftleft.semanticcpg.language._
import java.io._

@main def generateVulnReport(args: String*): Unit = {
  val outputDir = if (args.length > 0) args(0) else "vuln-results"
  val outputFile = s"$outputDir/vulnerability_report.md"

  println(s"Generating vulnerability report...")

  new File(outputDir).mkdirs()

  val writer = new PrintWriter(new FileWriter(outputFile))

  writer.println("# Vulnerability Analysis Report")
  writer.println()
  writer.println(s"- **Analysis Date:** `${new java.util.Date()}`")
  writer.println(s"- **Binary:** Binary executable")
  writer.println(s"- **CPG:** cpg.bin")
  writer.println()

  // Executive Summary
  writer.println("## Executive Summary")
  writer.println()
  writer.println("This report summarizes security vulnerabilities detected through")
  writer.println("static analysis using Ghidra decompilation and Joern CPG analysis.")
  writer.println()

  // Summary Statistics
  val totalVulns = scanAllVulnerabilities()
  writer.println("### Summary Statistics")
  writer.println()
  writer.println("| Category | Count | Severity |")
  writer.println("|-----------|-------|----------|")
  writer.println("| Buffer Overflow | " + totalVulns._1 + " | Critical |")
  writer.println("| Format String | " + totalVulns._2 + " | Critical |")
  writer.println("| Command Injection | " + totalVulns._3 + " | Critical |")
  writer.println("| Use After Free | " + totalVulns._4 + " | High |")
  writer.println("| Integer Overflow | " + totalVulns._5 + " | High |")
  writer.println("| NULL Pointer | " + totalVulns._6 + " | Medium |")
  writer.println("| **Total** | **" + (totalVulns._1 + totalVulns._2 + totalVulns._3 + totalVulns._4 + totalVulns._5 + totalVulns._6) + "** | |")
  writer.println()

  // Detailed Findings
  writer.println("## Detailed Findings")
  writer.println()

  writer.println("### 1. Buffer Overflow Vulnerabilities")
  writer.println()
  val bufferOverflows = cpg.call.name("strcpy|strcat|sprintf|memcpy").where(_.argument(1).inCall.name("recv|read|scanf|gets")).l
  writer.println(s"**Count:** ${bufferOverflows.size}")
  writer.println()
  writer.println("#### Description")
  writer.println("Stack or heap buffer overflow vulnerabilities occur when data from")
  writer.println("untrusted sources (network input, user input, files) is copied to")
  writer.println("fixed-size buffers without proper bounds checking.")
  writer.println()

  writer.println("#### Affected Locations")
  writer.println()
  bufferOverflows.take(10).foreach { vuln =>
    writer.println(s"- `${vuln.file.name}:${vuln.lineNumber}` - `${vuln.code}`")
  }
  if (bufferOverflows.size > 10) {
    writer.println(s"- ... and ${bufferOverflows.size - 10} more")
  }
  writer.println()

  writer.println("#### Recommended Mitigations")
  writer.println()
  writer.println("1. Use bounded string functions (strncpy, strncat)")
  writer.println("2. Validate input sizes before copying")
  writer.println("3. Use safer alternatives (snprintf, fgets)")
  writer.println("4. Implement stack canaries and ASLR")
  writer.println("---")
  writer.println()

  writer.println("### 2. Format String Vulnerabilities")
  writer.println()
  val formatStrings = cpg.call.name("printf|fprintf|sprintf|snprintf").where(_.argument(0).inCall.name("recv|read|scanf|gets|fgets|getenv")).l
  writer.println(s"**Count:** ${formatStrings.size}")
  writer.println()
  writer.println("#### Description")
  writer.println("Format string vulnerabilities occur when untrusted user input is")
  writer.println("passed as the format string to functions like printf(), allowing")
  writer.println("attackers to read memory or execute arbitrary code.")
  writer.println()

  writer.println("#### Affected Locations")
  writer.println()
  formatStrings.take(10).foreach { vuln =>
    writer.println(s"- `${vuln.file.name}:${vuln.lineNumber}` - `${vuln.code}`")
  }
  if (formatStrings.size > 10) {
    writer.println(s"- ... and ${formatStrings.size - 10} more")
  }
  writer.println()

  writer.println("#### Recommended Mitigations")
  writer.println()
  writer.println("1. Always use literal format strings: printf(\"%s\", user_input)")
  writer.println("2. Never pass user input as format string")
  writer.println("3. Use format string validation")
  writer.println("---")
  writer.println()

  writer.println("### 3. Command Injection Vulnerabilities")
  writer.println()
  val cmdInjection = cpg.call.name("system|exec|popen|WinExec|ShellExecute").where(_.argument(0).inCall.name("getenv|recv|read|scanf|gets|fgets|fread")).l
  writer.println(s"**Count:** ${cmdInjection.size}")
  writer.println()
  writer.println("#### Description")
  writer.println("Command injection allows attackers to execute arbitrary commands by")
  writer.println("injecting malicious input into functions that spawn shell commands.")
  writer.println()

  writer.println("#### Affected Locations")
  writer.println()
  cmdInjection.take(10).foreach { vuln =>
    writer.println(s"- `${vuln.file.name}:${vuln.lineNumber}` - `${vuln.code}`")
  }
  if (cmdInjection.size > 10) {
    writer.println(s"- ... and ${cmdInjection.size - 10} more")
  }
  writer.println()

  writer.println("#### Recommended Mitigations")
  writer.println()
  writer.println("1. Avoid shell execution functions when possible")
  writer.println("2. Use direct API calls instead of shell commands")
  writer.println("3. Validate and sanitize all command input")
  writer.println("4. Use whitelisting for allowed commands")
  writer.println("---")
  writer.println()

  writer.println("## Remediation Priorities")
  writer.println()
  writer.println("### High Priority (Fix Immediately)")
  writer.println()
  writer.println("1. All buffer overflow vulnerabilities")
  writer.println("2. All format string vulnerabilities")
  writer.println("3. All command injection vulnerabilities")
  writer.println()
  writer.println("These vulnerabilities can lead to remote code execution and")
  writer.println("should be addressed immediately.")
  writer.println()

  writer.println("### Medium Priority")
  writer.println()
  writer.println("1. Use-after-free issues")
  writer.println("2. Integer overflow vulnerabilities")
  writer.println()

  writer.println("### Low Priority")
  writer.println()
  writer.println("1. NULL pointer dereferences")
  writer.println("2. Information disclosure issues")
  writer.println()

  writer.println("## Additional Resources")
  writer.println()
  writer.println("- [CWE Top 25 Most Dangerous Software Errors](https://cwe.mitre.org/top25/)")
  writer.println("- [OWASP Top 10](https://owasp.org/www-project-top-ten/)")
  writer.println("- [CERT C Coding Standards](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard)")
  writer.println()

  writer.close()

  println(s"Vulnerability report generated: $outputFile")
}

def scanAllVulnerabilities(): (Int, Int, Int, Int, Int, Int) = {
  val bufferOverflow = cpg.call.name("strcpy|strcat|sprintf|memcpy").where(_.argument(1).inCall.name("recv|read|scanf|gets")).l.size
  val formatString = cpg.call.name("printf|fprintf|sprintf|snprintf").where(_.argument(0).inCall.name("recv|read|scanf|gets|fgets|getenv")).l.size
  val cmdInjection = cpg.call.name("system|exec|popen|WinExec|ShellExecute").where(_.argument(0).inCall.name("getenv|recv|read|scanf|gets|fgets|fread")).l.size
  val useAfterFree = cpg.call.name("free").where(_.next.astSiblings.where(_.code.matches(".*\\*.*")).exists).l.size
  val intOverflow = cpg.call("malloc|calloc|realloc").where(_.argument(0).inCall.name("recv|read|scanf")).l.size
  val nullPtr = cpg.call.where(_.argument.exists(_.code.matches(".*\\*.*"))).l.size

  (bufferOverflow, formatString, cmdInjection, useAfterFree, intOverflow, nullPtr)
}
