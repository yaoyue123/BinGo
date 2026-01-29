//###
//#
// Ghidra 12.0.1 compatible script for decompiling and exporting functions
//#
//###
import java.io.*;
import java.util.*;

import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.pcode.*;
import ghidra.program.model.symbol.*;
import ghidra.util.Msg;
import ghidra.framework.model.DomainFile;

// @author VulRe
// @category Utilities
// @description Decompile all functions and export to C files with dangerous function analysis

public class DecompileAndExport extends GhidraScript {

    private static final String[] DANGEROUS_FUNCTIONS = {
        "strcpy", "gets", "scanf", "sprintf", "strcat",
        "system", "exec", "popen", "WinExec", "ShellExecute",
        "memcpy", "memset", "bcopy", "malloc", "free",
        "printf", "fprintf", "snprintf", "syslog"
    };

    private static final String[] DANGEROUS_KEYWORDS = {
        "password", "admin", "root", "login", "auth",
        "cmd", "command", "exec", "system",
        "upload", "download", "flash", "upgrade"
    };

    private Map<String, List<String>> dangerousCalls = new HashMap<>();
    private Map<String, List<String>> suspiciousKeywords = new HashMap<>();

    @Override
    public void run() throws Exception {
        DecompInterface decompiler = new DecompInterface();

        try {
            decompiler.openProgram(currentProgram);
        } catch (Exception e) {
            Msg.error(this, "Decompiler Initialization Error: Failed to initialize decompiler: " + e.getMessage());
            return;
        }

        DomainFile projectFile = currentProgram.getDomainFile();
        File projectDir = projectFile.getParentFile();
        File outputDir = new File(projectDir, "decompiled");
        outputDir.mkdirs();

        File metadataFile = new File(projectDir, "decompile_metadata.txt");

        Listing listing = currentProgram.getListing();
        FunctionIterator functions = listing.getFunctions(true);

        int totalFuncs = 0;
        int decompiledFuncs = 0;
        int skippedFuncs = 0;

        try (PrintWriter metaWriter = new PrintWriter(new FileWriter(metadataFile))) {

            metaWriter.println("DECOMPILATION METADATA");
            metaWriter.println("====================================");
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

                Msg.info(this, "Decompiling: " + funcName + " (" + decompiledFuncs + "/" + totalFuncs + ")");

                if (funcName.startsWith("FUN_") || funcName.startsWith("sub_") ||
                    funcName.startsWith("thunk_") || funcName.startsWith("stub_")) {
                    skippedFuncs++;
                    continue;
                }

                try {
                    DecompilerResults results = decompiler.decompileFunction(function, 30, monitor);

                    if (results.decompileCompleted()) {
                        String code = results.getDecompiledFunction().getC();
                        String safeName = funcName.replaceAll("[^a-zA-Z0-9_]", "_");
                        String fileName = safeName + ".c";

                        try (PrintWriter writer = new PrintWriter(new File(outputDir, fileName))) {
                            writer.println("/*");
                            writer.println(" * Function: " + funcName);
                            writer.println(" * Address: 0x" + function.getEntryPoint().toString());
                            writer.println(" * Size: " + function.getBody().getNumAddresses() + " bytes");
                            writer.println(" * Parameters: " + function.getParameters().length);
                            writer.println(" * Calling Convention: " + function.getCallingConventionName());
                            writer.println(" */");
                            writer.println();

                            writer.println(code);
                        }

                        decompiledFuncs++;

                        analyzeCodeForDangerousPatterns(code, funcName, function.getEntryPoint().toString());
                    }
                } catch (Exception e) {
                    Msg.warn(this, "Decompilation Failed for " + funcName + ": " + e.getMessage());
                }
            }

            metaWriter.println("Total functions: " + totalFuncs);
            metaWriter.println("Decompiled: " + decompiledFuncs);
            metaWriter.println("Skipped (auto-named): " + skippedFuncs);
            metaWriter.println();

            metaWriter.println("DANGEROUS FUNCTION USAGE");
            metaWriter.println("=============================");

            for (Map.Entry<String, List<String>> entry : dangerousCalls.entrySet()) {
                if (!entry.getValue().isEmpty()) {
                    metaWriter.println(entry.getKey() + " calls: " + String.join(", ", entry.getValue()));
                }
            }

            metaWriter.println();
            metaWriter.println("SUSPICIOUS KEYWORDS");
            metaWriter.println("=====================");

            for (Map.Entry<String, List<String>> entry : suspiciousKeywords.entrySet()) {
                if (!entry.getValue().isEmpty()) {
                    metaWriter.println(entry.getKey() + ": " + String.join(", ", entry.getValue()));
                }
            }

        } catch (IOException e) {
            Msg.error(this, "File I/O Error: Failed to write metadata: " + e.getMessage());
        } finally {
            decompiler.dispose();
        }

        Msg.info(this, "Decompilation complete!");
        Msg.info(this, "  Total functions: " + totalFuncs);
        Msg.info(this, "  Decompiled: " + decompiledFuncs);
        Msg.info(this, "  Skipped: " + skippedFuncs);
        Msg.info(this, "  Output directory: " + outputDir.getAbsolutePath());
    }

    private void analyzeCodeForDangerousPatterns(String code, String funcName, String address) {
        String[] lines = code.split("\n");

        for (String dangerousFunc : DANGEROUS_FUNCTIONS) {
            if (code.contains(dangerousFunc + "(")) {
                dangerousCalls.computeIfAbsent(funcName, k -> new ArrayList<>()).add(dangerousFunc);
            }
        }

        for (String keyword : DANGEROUS_KEYWORDS) {
            if (code.contains(keyword)) {
                suspiciousKeywords.computeIfAbsent(funcName, k -> new ArrayList<>()).add(keyword);
            }
        }
    }
}
