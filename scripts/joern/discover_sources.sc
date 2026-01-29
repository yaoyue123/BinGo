// Joern script: LLM-driven custom source discovery
// Usage: joern cpg.bin --script discover_sources.sc > discovered_sources.md

import scala.collection.mutable.ListBuffer

println("# Custom Source Functions Discovery")
println("")
println("Discovered by analyzing CPG function names, signatures, and patterns")
println("")
println("## Discovery Criteria")
println("")
println("Functions identified as potential sources if they match patterns:")
println("- Function name contains: input/get/read/receive/parse/fetch")
println("- Parameters include: buffer/size/input/data")
println("- Returns pointer or buffer")
println("- Calls standard input functions internally")
println("")

// Discover potential custom source functions
val discoveredSources = ListBuffer[(String, String, String)]()

// Pattern 1: Function names with input-related keywords
val inputPatterns = List("input", "get", "read", "receive", "parse", "fetch", "extract", "handle")

inputPatterns.foreach { pattern =>
  val methods = cpg.method.name(s".*$pattern.*").l

  methods.foreach { method =>
    val name = method.name
    val signature = method.signature.headOption.getOrElse("N/A")
    val file = method.file.name.headOption.getOrElse("unknown")

    // Check if it calls standard input functions
    val callsInput = cpg.call
      .methodFullName(s".*recv.*|.*read.*|.*scanf.*|.*fgets.*")
      .where(_.method.name(name))
      .l
      .nonEmpty

    if (callsInput || name.contains("input") || name.contains("data")) {
      discoveredSources += ((name, signature, file))
    }
  }
}

// Pattern 2: Functions with buffer parameters
val bufferParamMethods = cpg.method
  .where(_.parameter.typeFullName(".*char.*|.*void.*"))
  .where(_.parameter.name(".*buffer.*|.*input.*|.*data.*|.*size.*"))
  .l

bufferParamMethods.take(10).foreach { method =>
  val name = method.name
  val signature = method.signature.headOption.getOrElse("N/A")
  val file = method.file.name.headOption.getOrElse("unknown")

  // Check if calls recv or read
  val callsRecv = cpg.call
    .methodFullName(s".*recv.*")
    .where(_.method(name))
    .l
    .nonEmpty

  if (callsRecv && !discoveredSources.exists(_._1 == name)) {
    discoveredSources += ((name, signature, file))
  }
}

// Pattern 3: Functions that return pointers to buffers
val returnBufferMethods = cpg.method
  .where(_.returnType.typeFullName(".*char.*\\*|.*void.*\\*"))
  .where(_.methodFullName(".*"))
  .l

returnBufferMethods.take(10).foreach { method =>
  val name = method.name
  val signature = method.signature.headOption.getOrElse("N/A")
  val file = method.file.name.headOption.getOrElse("unknown")

  // Check naming pattern
  val isCandidate = inputPatterns.exists(pattern =>
    name.toLowerCase.contains(pattern)
  )

  if (isCandidate && !discoveredSources.exists(_._1 == name)) {
    discoveredSources += ((name, signature, file))
  }
}

// Output results
if (discoveredSources.isEmpty) {
  println("## No Custom Sources Found")
  println("")
  println("No additional source functions discovered beyond built-in sources.")
  println("This is normal for binaries that only use standard input functions.")
} else {
  println(s"## Discovered ${discoveredSources.size} Custom Source Functions")
  println("")
  println("| Function | Signature | File | Reasoning |")
  println("|----------|-----------|------|-----------|")

  discoveredSources.foreach { case (name, signature, file) =>
    val reasoning = if (name.contains("input")) {
      "Function name contains 'input'"
    } else if (name.contains("get") || name.contains("read")) {
      "Function name suggests data retrieval"
    } else if (name.contains("receive")) {
      "Function name suggests receiving data"
    } else {
      "Matches input function patterns"
    }

    val sigShort = if (signature.length > 60) signature.take(60) + "..." else signature
    println(s"| `$name` | $sigShort | $file | $reasoning |")
  }
}

println("")
println("## Recommendation")
println("")
if (discoveredSources.size > 0) {
  println("Review the discovered functions above and add relevant ones to your")
  println("custom sources.json file for taint analysis.")
  println("")
  println("Example sources.json entry:")
  println("```json")
  println("{")
  println("  \"sources\": [")
  discoveredSources.take(3).foreach { case (name, _, _) =>
    println(s"    {\"name\": \"$name\", \"type\": \"discovered\", \"category\": \"custom\"},")
  }
  println("    ...")
  println("  ]")
  println("}")
  println("```")
} else {
  println("No custom source functions needed. Built-in sources should be sufficient.")
  println("")
  println("Built-in sources being used:")
  println("- recv, read, scanf, gets, fgets, fread, fgetc, getenv")
}

println("")
println("## Analysis Statistics")
println("")
println(s"- Total methods in CPG: ${cpg.method.name.toSet.size}")
println(s"- Methods matching input patterns: ${discoveredSources.size}")
println(s"- Custom sources discovered: ${discoveredSources.size}")
