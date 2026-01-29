// Joern script: Build Code Property Graph from Ghidra project
// Usage: ghidra2cpg --ghidra-path <path> --output cpg.bin --language c
//
// This is a reference for the Joern CPG construction process.
// Actual execution is done via the ghidra2cpg front-end.

// After CPG is loaded, validate it:
println("=== CPG Validation ===")
println(s"Nodes: ${cpg.graph.nodeCount}")
println(s"Edges: ${cpg.graph.edgeCount}")
println(s"Methods: ${cpg.method.l.size}")
println(s"Files: ${cpg.file.l.size}")

// Sample queries to verify CPG quality
println("\n=== Sample Methods ===")
cpg.method.name(".*main.*").l.take(5).foreach(m => println(m.name))

println("\n=== Sample Calls ===")
cpg.call.name("strcpy|gets|scanf").l.take(10).foreach(c => println(s"${c.methodFullName}:${c.lineNumber}"))

// For interactive use, save this CPG reference
val cpgFile = new java.io.File("cpg.bin")
if (cpgFile.exists()) {
  println(s"\nCPG loaded successfully from ${cpgFile.getAbsolutePath}")
}
