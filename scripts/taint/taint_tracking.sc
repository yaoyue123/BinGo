import io.shiftleft.semanticcpg.language._
import io.shiftleft.codepropertygraph.Cpg
import io.shiftleft.semanticcpg.layers._

// Taint sources - functions that introduce untrusted data
val sources = cpg.call.name("scanf|gets|fgets|read|recv|recvfrom|getenv|fread|fgetc").argument(1)

// Taint sinks - dangerous functions
val sinks = cpg.call.name("strcpy|strcat|sprintf|memcpy|memset|printf|fprintf|snprintf|system|exec|popen|open|fopen").argument(1)

// Sanitizers - functions that validate data
val sanitizers = cpg.call.name("strnlen|strlen|size_check|validate_input|sanitize")

println("Starting taint analysis...")
println(s"Sources found: ${sources.size}")
println(s"Sinks found: ${sinks.size}")
println(s"Sanitizers found: ${sanitizers.size}")
println()

// Perform taint tracking
val flows = cpg.taintTracking(sources, sanitizers).flowsTo(sinks)

println(s"Found ${flows.size} taint flows")
println()

// Display flows
flows.take(20).foreach { flow =>
  println(s"Flow:")
  println(s"  Source: ${flow.source.methodFullName}")
  println(s"  Sink: ${flow.sink.methodFullName}")
  println(s"  Path length: ${flow.pathElements.size}")
  println(s"  Path:")
  flow.pathElements.foreach { elem =>
    println(s"    -> ${elem.methodFullName} at line ${elem.lineNumber}")
  }
  println()
}

if (flows.size > 20) {
  println(s"... and ${flows.size - 20} more flows")
}

// Save results
val outputFile = "taint_results.txt"
import java.io._
val writer = new PrintWriter(new FileWriter(outputFile))

writer.println("Taint Analysis Results")
writer.println("=" * 50)
writer.println(s"Total flows: ${flows.size}")
writer.println(s"Date: ${new java.util.Date()}")
writer.println()

flows.zipWithIndex.foreach { case (flow, idx) =>
  writer.println(s"Flow ${idx + 1}:")
  writer.println(s"  Source: ${flow.source.methodFullName}")
  writer.println(s"  Sink: ${flow.sink.methodFullName}")
  writer.println(s"  Path:")
  flow.pathElements.foreach { elem =>
    writer.println(s"    -> ${elem.methodFullName}:${elem.lineNumber}")
  }
  writer.println()
}

writer.close()
println(s"Results saved to: $outputFile")
