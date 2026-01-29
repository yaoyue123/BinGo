import io.shiftleft.semanticcpg.language._
import java.io._

@main def scanAll(args: String*): Unit = {
  val cpgFile = if (args.length > 0) args(0) else "cpg.bin"
  val outputDir = if (args.length > 1) args(1) else "vuln-results"

  println(s"Vulnerability Scan for: $cpgFile")
  println(s"Output directory: $outputDir")

  // Create output directory
  new File(outputDir).mkdirs()

  var totalVulns = 0
  var critical = 0
  var high = 0
  var medium = 0

  // Buffer Overflow Detection
  println("\n[1/6] Scanning for buffer overflows...")
  val bufferOverflow = detectBufferOverflow()
  totalVulns += bufferOverflow.size
  critical += bufferOverflow.size
  writeVulnerabilities(bufferOverflow, s"$outputDir/buffer_overflow.txt", "Buffer Overflow", "Critical")

  // Format String Detection
  println("[2/6] Scanning for format strings...")
  val formatString = detectFormatString()
  totalVulns += formatString.size
  critical += formatString.size
  writeVulnerabilities(formatString, s"$outputDir/format_string.txt", "Format String", "Critical")

  // Command Injection Detection
  println("[3/6] Scanning for command injection...")
  val commandInjection = detectCommandInjection()
  totalVulns += commandInjection.size
  critical += commandInjection.size
  writeVulnerabilities(commandInjection, s"$outputDir/command_injection.txt", "Command Injection", "Critical")

  // Use After Free Detection
  println("[4/6] Scanning for use-after-free...")
  val useAfterFree = detectUseAfterFree()
  totalVulns += useAfterFree.size
  high += useAfterFree.size
  writeVulnerabilities(useAfterFree, s"$outputDir/use_after_free.txt", "Use After Free", "High")

  // Integer Overflow Detection
  println("[5/6] Scanning for integer overflow...")
  val intOverflow = detectIntegerOverflow()
  totalVulns += intOverflow.size
  high += intOverflow.size
  writeVulnerabilities(intOverflow, s"$outputDir/integer_overflow.txt", "Integer Overflow", "High")

  // NULL Pointer Dereference
  println("[6/6] Scanning for NULL pointer dereference...")
  val nullPtr = detectNullPointer()
  totalVulns += nullPtr.size
  medium += nullPtr.size
  writeVulnerabilities(nullPtr, s"$outputDir/null_pointer.txt", "NULL Pointer Dereference", "Medium")

  // Write summary
  val summary = new PrintWriter(new FileWriter(s"$outputDir/summary.txt"))
  summary.println("Vulnerability Scan Summary")
  summary.println("=" * 50)
  summary.println(s"CPG File: $cpgFile")
  summary.println(s"Scan Date: ${new java.util.Date()}")
  summary.println()
  summary.println("Results:")
  summary.println(s"  Total vulnerabilities: $totalVulns")
  summary.println(s"  Critical: $critical")
  summary.println(s"  High: $high")
  summary.println(s"  Medium: $medium")
  summary.println()
  summary.println("Files Generated:")
  summary.println(s"  - $outputDir/buffer_overflow.txt")
  summary.println(s"  - $outputDir/format_string.txt")
  summary.println(s"  - $outputDir/command_injection.txt")
  summary.println(s"  - $outputDir/use_after_free.txt")
  summary.println(s"  - $outputDir/integer_overflow.txt")
  summary.println(s"  - $outputDir/null_pointer.txt")
  summary.close()

  println("\n" + "=" * 50)
  println("Scan Complete!")
  println(s"Total vulnerabilities found: $totalVulns")
  println(s"  Critical: $critical")
  println(s"  High: $high")
  println(s"  Medium: $medium")
  println(s"\nResults saved to: $outputDir/")
}

def detectBufferOverflow() = {
  cpg.call.name("strcpy|strcat|sprintf|memcpy|bcopy").where { call =>
    call.argument(1).inCall.name("recv|read|scanf|gets|fgets|fread|fgetc") ||
    !call.argument(1).inAssignment.where(_.astNext.callsAny("strnlen", "strlen", "size_check")).astNext.hasNext
  }.l
}

def detectFormatString() = {
  cpg.call.name("printf|fprintf|sprintf|snprintf|syslog").where { call =>
    call.argument(0).inCall.name("recv|read|scanf|gets|fgets|getenv|fread")
  }.l
}

def detectCommandInjection() = {
  cpg.call.name("system|exec|popen|WinExec|ShellExecute").where { call =>
    call.argument(0).inCall.name("getenv|recv|read|scanf|gets|fgets|fread")
  }.l
}

def detectUseAfterFree() = {
  cpg.call.name("free").where { freeCall =>
    freeCall.next.astSiblings.where(_.code.matches(".*\\*.*")).exists
  }.l
}

def detectIntegerOverflow() = {
  cpg.call("malloc|calloc|realloc").where { call =>
    call.argument(0).inCall.name(".*").where(_.inCall.name("recv|read|scanf")).exists
  }.l
}

def detectNullPointer() = {
  cpg.call.where { call =>
    call.argument.exists(_.code.matches(".*\\*.*")) &&
    !call.inAst.isCall.name("NULL").where(_.argument.exists(_.code.matches(".*==.*NULL|!=.*NULL"))).exists
  }.l
}

def writeVulnerabilities(vulns: List[_], file: String, vulnType: String, severity: String): Unit = {
  val writer = new PrintWriter(new FileWriter(file))
  writer.println(s"$vulnType Vulnerabilities")
  writer.println("=" * 50)
  writer.println(s"Severity: $severity")
  writer.println(s"Count: ${vulns.size}")
  writer.println()

  vulns.zipWithIndex.foreach { case (vuln, idx) =>
    writer.println(s"${idx + 1}. $vulnType #${idx + 1}")
    writer.println(s"   Details: $vuln")
    writer.println()
  }

  writer.close()
  println(s"  Found ${vulns.size} $vulnType vulnerabilities")
}
