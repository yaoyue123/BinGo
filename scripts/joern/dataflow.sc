// Joern script: Data flow analysis from sources to sinks
// Usage: joern cpg.bin --script dataflow.sc <sources.json> <sinks.json> <output_dir>

import io.circe.*, io.circe.syntax._

// Parse arguments
val outputDir = if (args.length > 2) args(2) else "flows"
new java.io.File(outputDir).mkdirs()

// Default sources if not provided
val defaultSources = List(
  "scanf", "gets", "fgets", "read", "recv", "recvfrom", "getenv", "fread", "fgetc"
)

// Default sinks if not provided
val defaultSinks = List(
  "strcpy", "strcat", "sprintf", "memcpy", "memset", "bcopy",
  "system", "exec", "popen", "execl", "execle", "execlp", "execv",
  "printf", "fprintf", "snprintf", "syslog"
)

// Load sources from file or use defaults
val sourcesJson = if (args.length > 0) {
  val source = scala.io.Source.fromFile(args(0))
  val content = try source.mkString finally source.close()
  parser.parse(content) match {
    case Right(json) => json
    case Left(err) => throw new Exception(s"Failed to parse sources: ${err}")
  }
} else {
  defaultSources.asJson
}

// Load sinks from file or use defaults
val sinksJson = if (args.length > 1) {
  val source = scala.io.Source.fromFile(args(1))
  val content = try source.mkString finally source.close()
  parser.parse(content) match {
    case Right(json) => json
    case Left(err) => throw new Exception(s"Failed to parse sinks: ${err}")
  }
} else {
  defaultSinks.asJson
}

println("=== Data Flow Analysis ===")
println(s"Sources: $sourcesJson")
println(s"Sinks: $sinksJson")

// Extract source names from JSON
val sourceNames = sourcesJson.asArray.get.flatMap(_.asString.map(List(_))).toList.flatten
val sinkNames = sinksJson.asArray.get.flatMap(_.asString.map(List(_))).toList.flatten

println(s"\nSource functions: ${sourceNames.mkString(", ")}")
println(s"Sink functions: ${sinkNames.mkString(", ")}")

// Define sources as call nodes
val sources = cpg.call.filter(call => sourceNames.exists(name => call.methodFullName.getOrElse("").contains(name)))
val sinks = cpg.call.filter(call => sinkNames.exists(name => call.methodFullName.getOrElse("").contains(name)))

println(s"\nFound ${sources.l.size} source calls")
println(s"Found ${sinks.l.size} sink calls")

// Run taint tracking
println("\n=== Running Taint Analysis ===")
val flows = sinks.flatMap(sink =>
  sources.flatMap(source =>
    source.dataFlowTo(sink).l
  )
)

println(s"Found ${flows.size} flows")

// Export each flow to separate JSON file
var flowCount = 0
flows.foreach { flow =>
  flowCount += 1
  val flowId = f"flow_$flowCount%03d"
  val flowFile = new java.io.File(outputDir, s"$flowId.json")

  val flowJson = io.circe.Json.obj(
    ("id", flowId.asJson),
    ("source", io.circe.Json.obj(
      ("method", flow.methodStart.methodFullName.asJson),
      ("line", flow.methodStart.lineNumber.asJson)
    )),
    ("sink", io.circe.Json.obj(
      ("method", flow.methodEnd.methodFullName.asJson),
      ("line", flow.methodEnd.lineNumber.asJson)
    )),
    ("pathElements", flow.elements.map(elem =>
      io.circe.Json.obj(
        ("method", elem.methodFullName.asJson),
        ("line", elem.lineNumber.asJson)
      )
    ).asJson)
  )

  val pw = new java.io.PrintWriter(flowFile)
  pw.write(flowJson.spaces2)
  pw.close()

  println(s"Exported: $flowFile")
}

// Summary
println(s"\n=== Analysis Complete ===")
println(s"Total flows found: $flowCount")
println(s"Output directory: $outputDir")
