import io.shiftleft.semanticcpg.language._
import io.joern.dataflowengineoss.language._

@main def findFlows(args: String*): Unit = {
  val cpgFile = if (args.length > 0) args(0) else "cpg.bin"

  println(s"Analyzing CPG: $cpgFile")

  // Define patterns for different vulnerability types
  val patterns = Map(
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
    ),
    "Path Traversal" -> (
      cpg.call.name("getenv|recv|read|scanf|fgets").argument(1),
      cpg.call.name("open|fopen|access|stat|chmod").argument(0)
    )
  )

  var totalFlows = 0

  patterns.foreach { case (vulnType, (sources, sinks)) =>
    println(s"\n=== $vulnType ===")

    val flows = cpg.taintTracking(sources).flowsTo(sinks)
    val count = flows.size
    totalFlows += count

    println(s"Found $count flows")

    flows.take(5).foreach { flow =>
      println(s"\n  Flow:")
      println(s"    Source: ${flow.source.methodFullName}")
      println(s"    Sink: ${flow.sink.methodFullName}")
    }

    if (count > 5) {
      println(s"    ... and ${count - 5} more")
    }
  }

  println(s"\n=== Summary ===")
  println(s"Total flows found: $totalFlows")
}
