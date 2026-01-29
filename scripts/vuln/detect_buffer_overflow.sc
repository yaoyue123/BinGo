import io.shiftleft.semanticcpg.language._
import java.io._

@main def detectBufferOverflow(args: String*): Unit = {
  val outputFile = if (args.length > 0) args(0) else "buffer_overflow_report.txt"

  println("Detecting buffer overflow vulnerabilities...")

  // Pattern 1: strcpy with recv input
  val strcpyRecv = cpg.call.name("strcpy").where(_.argument(1).inCall.name("recv|read|scanf|gets"))

  // Pattern 2: sprintf with user input
  val sprintfUser = cpg.call.name("sprintf").where(_.argument(2).inCall.name("recv|read|scanf|gets|fgets"))

  // Pattern 3: strcat without size check
  val strcatUnsafe = cpg.call.name("strcat").whereNot(_.argument(0).inAssignment.where(_.astNext.callsAny("strnlen")).astNext.hasNext)

  // Pattern 4: memcpy with tainted data
  val memcpyUnsafe = cpg.call.name("memcpy").where(_.argument(1).inCall.name("recv|read|scanf|gets|fread"))

  val allVulns = strcpyRecv ++ sprintfUser ++ strcatUnsafe ++ memcpyUnsafe

  println(s"Found ${allVulns.size} potential buffer overflow vulnerabilities")

  val writer = new PrintWriter(new FileWriter(outputFile))

  writer.println("# Buffer Overflow Vulnerability Report")
  writer.println()
  writer.println(s"- **Analysis Date:** `${new java.util.Date()}`")
  writer.println(s"- **Total Findings:** ${allVulns.size}")
  writer.println()

  writer.println("## Summary")
  writer.println()
  writer.println("| Pattern | Count |")
  writer.println("|---------|-------|")
  writer.println(s"| strcpy with recv | ${strcpyRecv.size} |")
  writer.println(s"| sprintf with user input | ${sprintfUser.size} |")
  writer.println(s"| strcat without size check | ${strcatUnsafe.size} |")
  writer.println(s"| memcpy with tainted data | ${memcpyUnsafe.size} |")
  writer.println()

  writer.println("## Findings")
  writer.println()

  var idx = 1
  allVulns.foreach { vuln =>
    writer.println(s"### $idx. Vulnerability at ${vuln.methodFullName}")
    writer.println()
    writer.println(s"- **Location:** `${vuln.file.name}:${vuln.lineNumber}`")
    writer.println(s"- **Function:** `${vuln.method.fullName}`")
    writer.println(s"- **Code:** `${vuln.code}`")
    writer.println()

    writer.println("**Vulnerability Description:**")
    writer.println("  Data from untrusted source is copied to a fixed-size buffer")
    writer.println("  without proper bounds checking, leading to buffer overflow.")
    writer.println()

    writer.println("**Evidence:**")
    writer.println("  - Source: Untrusted input from network or user")
    writer.println("  - Sink: Unbounded copy operation")
    writer.println("  - Missing: Size validation before copy")
    writer.println()

    writer.println("**Recommended Fix:**")
    writer.println("  ```c")
    writer.println("  // Use bounded copy functions")
    writer.println("  strncpy(dest, src, sizeof(dest) - 1);")
    writer.println("  dest[sizeof(dest) - 1] = '\\0';")
    writer.println()
    writer.println("  // Or validate input size")
    writer.println("  if (len < sizeof(dest)) {")
    writer.println("      memcpy(dest, src, len);")
    writer.println("  }")
    writer.println("  ```")
    writer.println()

    writer.println("**CVSS Score:** 9.8 (Critical)")
    writer.println("**CVSS Vector:** CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H")
    writer.println()
    writer.println("---")
    writer.println()

    idx += 1
  }

  writer.close()

  println(s"Report saved to: $outputFile")
}
