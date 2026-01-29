//###
//#
// Minimal working Ghidra 12.0.1 decompilation script
//#
//###
import java.io.*;
import java.util.*;

import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;

// @author VulRe
// @category Utilities
// @description Decompile all functions and export to C files

public class SimpleDecompile extends GhidraScript {

    @Override
    public void run() throws Exception {
        DecompInterface decompiler = new DecompInterface();

        if (!decompiler.openProgram(currentProgram)) {
            println("ERROR: Failed to open decompiler");
            return;
        }

        String outputPath = getScriptArgs().length > 0 ? getScriptArgs()[0] : "decompiled";
        File outputDir = new File(outputPath);
        outputDir.mkdirs();

        Listing listing = currentProgram.getListing();
        FunctionIterator functions = listing.getFunctions(true);

        int totalFuncs = 0;
        int decompiledFuncs = 0;

        while (functions.hasNext()) {
            Function func = functions.next();
            String funcName = func.getName();
            totalFuncs++;

            if (funcName.startsWith("FUN_") || funcName.startsWith("sub_") ||
                funcName.startsWith("thunk_")) {
                continue;
            }

            try {
                DecompilerResults results = decompiler.decompileFunction(func, 60, monitor);

                if (results.decompileCompleted()) {
                    String code = results.getDecompiledFunction().getC();
                    String safeName = funcName.replaceAll("[^a-zA-Z0-9_]", "_");
                    String fileName = safeName + ".c";
                    File outFile = new File(outputDir, fileName);

                    try (PrintWriter writer = new PrintWriter(new FileWriter(outFile))) {
                        writer.println("/* Function: " + funcName + " */");
                        writer.println("/* Address: 0x" + func.getEntryPoint().toString() + " */");
                        writer.println(code);
                    }

                    decompiledFuncs++;

                    if (decompiledFuncs % 50 == 0) {
                        println("Decompiled " + decompiledFuncs + " functions...");
                    }
                }
            } catch (Exception e) {
                println("ERROR: Failed to decompile " + funcName + ": " + e.getMessage());
            }
        }

        decompiler.dispose();

        println("========================================");
        println("Decompilation Complete!");
        println("Total functions: " + totalFuncs);
        println("Decompiled: " + decompiledFuncs);
        println("Output directory: " + outputDir.getAbsolutePath());
        println("========================================");
    }
}
