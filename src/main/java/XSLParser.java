// removed unused javax.xml.transform imports
import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class XSLParser {

    public static void main(String[] args) {
        try {
            BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
            File xslt = new File("/Users/huace/Downloads/12dfldformatfile.xsl");
            if (!xslt.exists()) {
                System.out.println("File not found: " + xslt.getAbsolutePath());
                return;
            }

            List<XsltUserVariable> vars = XsltUserVariableParser.parse(xslt);
            if (vars.isEmpty()) {
                System.out.println("No user variables found.");
                return;
            }

            System.out.println("Found " + vars.size() + " variables.");
            System.out.println("Instructions: Enter to keep current; for menus input index (e.g. 1) or value (e.g. Yes). Type 's' to skip, 'q' to save & quit, '?' for help.");
            Map<String, String> updates = new LinkedHashMap<>();
            for (int i = 0; i < vars.size(); i++) {
                XsltUserVariable v = vars.get(i);
                System.out.println();
                System.out.println((i + 1) + ". " + v.getVariableName());
                System.out.println("   Prompt: " + v.getPrompt());
                System.out.println("   Type: " + v.getType());
                if (!v.getOptions().isEmpty()) {
                    System.out.println("   Options:");
                    for (int j = 0; j < v.getOptions().size(); j++) {
                        String opt = v.getOptions().get(j);
                        System.out.println("     [" + (j + 1) + "] " + opt);
                    }
                }
                System.out.println("   Current default: " + v.getDefaultValue());
                if (!v.getOptions().isEmpty()) {
                    System.out.print("   New value: enter index or value (Enter=keep, s=skip, q=save&quit): ");
                } else {
                    System.out.print("   New value: enter text (Enter=keep, s=skip, q=save&quit): ");
                }
                String input = in.readLine();
                if (input == null) input = "";
                input = input.trim();
                if (input.isEmpty()) continue; // keep current
                if ("?".equals(input)) {
                    System.out.println("   Help: Enter keeps current. For menus, type option index (e.g. 1) or value (e.g. Yes). 's' skips this variable. 'q' saves changes and quits.");
                    i--; // re-prompt same item
                    continue;
                }
                if ("s".equalsIgnoreCase(input)) {
                    continue; // skip this variable
                }
                if ("q".equalsIgnoreCase(input)) {
                    break; // stop editing and save below
                }

                String newValue = input;
                // Allow selecting option by index for STRING_MENU
                if (!v.getOptions().isEmpty()) {
                    try {
                        int idx = Integer.parseInt(input);
                        if (idx >= 1 && idx <= v.getOptions().size()) {
                            newValue = v.getOptions().get(idx - 1);
                        }
                    } catch (NumberFormatException ignore) {
                        // fall back to raw string
                    }
                    // Validate: if user typed a string, ensure it exists in options
                    if (!v.getOptions().contains(newValue)) {
                        System.out.println("   Invalid value. Skipped.");
                        continue;
                    }
                }

                // Only write if changed
                if (!newValue.equals(v.getDefaultValue())) {
                    updates.put(v.getVariableName(), newValue);
                }
            }

            if (updates.isEmpty()) {
                System.out.println("No changes to write.");
                return;
            }

            XsltUserVariableWriter.applyUpdates(xslt, updates);
            System.out.println("Saved updates to: " + xslt.getAbsolutePath());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void printVariables(List<XsltUserVariable> vars) {
        if (vars == null || vars.isEmpty()) {
            System.out.println("No variables found.");
            return;
        }

        for (XsltUserVariable var : vars) {
            System.out.println("Variable Name: " + var.getVariableName());
            System.out.println("Prompt: " + var.getPrompt());
            System.out.println("Type: " + var.getType());
            System.out.println("Min Value: " + var.getMinValue());
            System.out.println("Max Value: " + var.getMaxValue());
            System.out.println("Options: " + var.getOptions());
            System.out.println("Default Value: " + var.getDefaultValue());
            System.out.println("-------------------------------");
        }
    }
}