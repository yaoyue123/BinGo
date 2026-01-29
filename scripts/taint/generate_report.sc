import io.shiftleft.semanticcpg.language._
import java.io._

@main def generateReport(args: String*): Unit = {
  val cpgFile = if (args.length > 0) args(0) else "cpg.bin"
  val outputFile = if (args.length > 1) args(1) else "taint_analysis_report.md"

  println(s"Generating report for: $cpgFile")
  println(s"Output to: $outputFile")

  // Define vulnerability patterns
  val patterns = Seq(
    "Buffer Overflow" -> (
      cpg.call.name("recv|read|scanf|gets|fgets").argument(1),
      cpg.call.name("strcpy|strcat|sprintf|memcpy|bcopy").argument(1)
    ),
    "Format String" -> (
      cpg.call.name("recv|read|scanf|fgets|getenv").argument(1),
      cpg.call.name("printf|fprintf|sprintf|snprintf|syslog").argument(0)
    ),
    "Command Injection" -> (
      cpg.call.name("getenv|recv|read|scanf|fgets").argument(1),
      cpg.call.name("system|exec|popen|WinExec|ShellExecute").argument(0)
    )
  )

  val writer = new PrintWriter(new FileWriter(outputFile))

  writer.println("# Taint Analysis Report")
  writer.println()
  writer.println(s"- **CPG File:** `$cpgFile`")
  writer.println(s"- **Analysis Date:** `${new java.util.Date()}`")
  writer.println()

  writer.println("## Summary")
  writer.println()
  writer.println("| Vulnerability Type | Flows Found |")
  writer.println("|-------------------|-------------|")

  var totalFlows = 0

  patterns.foreach { case (vulnType, (sources, sinks)) =>
    val flows = cpg.taintTracking(sources).flowsTo(sinks)
    val count = flows.size
    totalFlows += count

    writer.println(s"| $vulnType | $count |")
  }

  writer.println(s"| **Total** | **$totalFlows** |")
  writer.println()

  writer.println("## Detailed Findings")
  writer.println()

  patterns.foreach { case (vulnType, (sources, sinks)) =>
    val flows = cpg.taintTracking(sources).flowsTo(sinks)

    if (flows.size > 0) {
      writer.println(s"### $vulnType")
      writer.println()
      writer.println(s"Found ${flows.size} taint flows that could lead to $vulnType vulnerabilities.")
      writer.println()

      flows.zipWithIndex.foreach { case (flow, idx) =>
        writer.println(s"#### ${idx + 1}. Flow #${flow.hashCode()}")
        writer.println()
        writer.println(s"- **Source:** ${flow.source.methodFullName}")
        writer.println(s"- **Sink:** ${flow.sink.methodFullName}")
        writer.println(s"- **Path Length:** ${flow.pathElements.size} hops")
        writer.println()
        writer.println("**Data Flow Path:**")
        flow.pathElements.foreach { elem =>
          writer.println(s"1. `${elem.methodFullName}` (line ${elem.lineNumber})")
        }
        writer.println()
      }
    }
  }

  writer.close()

  println(s"Report generated successfully!")
  println(s"Total flows: $totalFlows")
  println(s"Report saved to: $outputFile")
}
