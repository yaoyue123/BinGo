import io.shiftleft.codepropertygraph.Cpg
import io.shiftleft.semanticcpg.layers._
import io.shiftleft.semanticcpg.language._

@main def buildCpg(args: String*): Unit = {
  if (args.length < 1) {
    println("Usage: buildCpg <ghidra_project_path> [output_path]")
    sys.exit(1)
  }

  val ghidraPath = args(0)
  val outputPath = if (args.length > 1) args(1) else "cpg.bin"

  println(s"Building CPG from: $ghidraPath")
  println(s"Output to: $outputPath")

  // Load Ghidra project
  val cpg = io.shiftleft.semanticcpg.ghidra2cpg.Ghidra2Cpg.run(ghidraPath)

  // Add base layers
  new TypeEnhancement().run(cpg, new EmptyOverlay())
  new ControlFlow().run(cpg, new EmptyOverlay())

  // Write CPG
  cpg.save(outputPath)

  // Print statistics
  println(s"\nCPG Statistics:")
  println(s"  Nodes: ${cpg.graph.nodeCount}")
  println(s"  Edges: ${cpg.graph.edgeCount}")
  println(s"  Methods: ${cpg.method.name.toSet.size}")
  println(s"  Files: ${cpg.file.name.toSet.size}")

  println(s"\nCPG saved to: $outputPath")
}
