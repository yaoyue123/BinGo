// Ghidra script: Export all decompiled functions
// Usage: analyzeHeadless ... -postScript DecompileAll.java <output_dir>

import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.pcode.*;
import java.io.*;

public class DecompileAll extends GhidraScript {

    @Override
    public void run() throws Exception {
        String outputDir = null;
        if (getScriptArgs().length > 0) {
            outputDir = getScriptArgs()[0];
        } else {
            outputDir = "/tmp/decompiled";
        }

        File dir = new File(outputDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);

        FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
        int count = 0;
        int errorCount = 0;

        PrintWriter metadata = new PrintWriter(new FileWriter(new File(dir, "decompile_metadata.txt")));

        while (functions.hasNext()) {
            Function func = functions.next();
            String funcName = func.getName();

            try {
                DecompileResults result = decompiler.decompileFunction(func, 30, monitor);

                if (result.decompileCompleted()) {
                    String code = result.getDecompiledFunction().getC();

                    // Sanitize filename
                    String safeName = funcName.replaceAll("[^a-zA-Z0-9_-]", "_");
                    File outFile = new File(dir, safeName + ".c");

                    PrintWriter writer = new PrintWriter(new FileWriter(outFile));
                    writer.println("// Function: " + funcName);
                    writer.println("// Address: " + func.getEntryPoint());
                    writer.println();
                    writer.println(code);
                    writer.close();

                    metadata.println("Function: " + funcName + " @ " + func.getEntryPoint());
                    count++;
                } else {
                    errorCount++;
                }
            } catch (Exception e) {
                errorCount++;
                println("Error decompiling " + funcName + ": " + e.getMessage());
            }
        }

        decompiler.dispose();

        metadata.println();
        metadata.println("Total decompiled: " + count);
        metadata.println("Errors: " + errorCount);
        metadata.println("Date: " + new java.util.Date());
        metadata.close();

        println("Decompiled " + count + " functions to " + outputDir);
        println("Errors: " + errorCount);
    }
}
