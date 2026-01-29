import java.io.*;
import java.util.*;

import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.pcode.*;
import ghidra.program.model.symbol.*;
import ghidra.util.Msg;

public class DecompileAndExport extends GhidraScript {
    @Override
    public void run() throws Exception {
    DecompInterface decompiler = new DecompInterface();
    decompiler.openProgram(currentProgram);

    File projectDir = currentProgram.getProject().getProjectLocator().getLocation();
    File outputDir = new File(projectDir, "decompiled");
    outputDir.mkdirs();

    File metadataFile = new File(projectDir, "decompile_metadata.txt");

    Listing listing = currentProgram.getListing();
    FunctionIterator functions = listing.getFunctions(true);

    Map<String, List<String>> dangerousCalls = new HashMap<>();
    String[] dangerousFuncs = {"strcpy", "gets", "scanf", "sprintf", "strcat",
                               "system", "exec", "memcpy", "malloc", "free"};

    int totalFuncs = 0;
    int decompiledFuncs = 0;
    int skippedFuncs = 0;

    try (PrintWriter metaWriter = new PrintWriter(metadataFile)) {
        metaWriter.println("DECOMPILATION METADATA");
        metaWriter.println("=====================");
        metaWriter.println("Binary: " + currentProgram.getName());
        metaWriter.println("Format: " + currentProgram.getExecutableFormat());
        metaWriter.println("Language: " + currentProgram.getLanguageID());
        metaWriter.println("Image Base: 0x" + currentProgram.getImageBase().toString());
        metaWriter.println("Analysis Date: " + new Date());
        metaWriter.println();

        metaWriter.println("FUNCTION STATISTICS");
        metaWriter.println("===================");

        while (functions.hasNext()) {
            Function function = functions.next();
            String funcName = function.getName();
            totalFuncs++;

            // Skip auto-generated names
            if (funcName.startsWith("FUN_") || funcName.startsWith("sub_")) {
                skippedFuncs++;
                continue;
            }

            try {
                DecompilerResults results = decompiler.decompileFunction(function, 30, null);

                if (results.decompileCompleted()) {
                    String code = results.getDecompiledFunction().getC();
                    String safeName = funcName.replaceAll("[^a-zA-Z0-9_]", "_");
                    String fileName = outputDir.getAbsolutePath() + "/" + safeName + ".c";

                    try (PrintWriter writer = new PrintWriter(fileName)) {
                        writer.println("/*");
                        writer.println(" * Function: " + funcName);
                        writer.println(" * Address: 0x" + function.getEntryPoint().toString());
                        writer.println(" * Size: " + function.getBody().getNumAddresses() + " bytes");
                        writer.println(" * Parameters: " + function.getParameters().length);
                        writer.println(" * Calling Convention: " + function.getCallingConventionName());
                        writer.println(" */");
                        writer.println();

                        // Write decompiled code
                        writer.println(code);
                    }

                    decompiledFuncs++;

                    // Check for dangerous function calls
                    for (String dangerous : dangerousFuncs) {
                        if (code.contains(dangerous + "(")) {
                            if (!dangerousCalls.containsKey(funcName)) {
                                dangerousCalls.put(funcName, new ArrayList<>());
                            }
                            dangerousCalls.get(funcName).add(dangerous);
                        }
                    }
                }
            } catch (Exception e) {
                Msg.warn(this, "Failed to decompile " + funcName + ": " + e.getMessage());
            }
        }

        metaWriter.println("Total Functions: " + totalFuncs);
        metaWriter.println("Decompiled: " + decompiledFuncs);
        metaWriter.println("Skipped (auto-named): " + skippedFuncs);
        metaWriter.println();

        metaWriter.println("DANGEROUS FUNCTION USAGE");
        metaWriter.println("========================");
        for (Map.Entry<String, List<String>> entry : dangerousCalls.entrySet()) {
            metaWriter.println(entry.getKey() + " calls: " + String.join(", ", entry.getValue()));
        }

        if (dangerousCalls.isEmpty()) {
            metaWriter.println("None found");
        }
    }

    decompiler.dispose();

    Msg.info(this, "Decompilation complete!");
    Msg.info(this, "  Total functions: " + totalFuncs);
    Msg.info(this, "  Decompiled: " + decompiledFuncs);
    Msg.info(this, "  Skipped: " + skippedFuncs);
    Msg.info(this, "  Output directory: " + outputDir.getAbsolutePath());
    Msg.info(this, "  Metadata: " + metadataFile.getAbsolutePath());
}
