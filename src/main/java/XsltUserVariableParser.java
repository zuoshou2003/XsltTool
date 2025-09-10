
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

/**
 * Parser to discover user-editable variables from an XSLT file.
 * It scans xsl:variable nodes named as 'userField*' and parses the 'select' attribute,
 * then looks up the related default value variable by name.
 */
public final class XsltUserVariableParser {

    private static final String NS_XSL = "http://www.w3.org/1999/XSL/Transform";

    private XsltUserVariableParser() {}


    public static List<XsltUserVariable> parse(File xsltFile) {
        List<XsltUserVariable> result = new ArrayList<>();
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(xsltFile);

            // Index all top-level xsl:variable nodes: name -> select/text content
            Map<String, String> varNameToValue = new HashMap<>();
            NodeList variables = doc.getElementsByTagNameNS(NS_XSL, "variable");
            for (int i = 0; i < variables.getLength(); i++) {
                Node node = variables.item(i);
                Node nameAttr = node.getAttributes() != null ? node.getAttributes().getNamedItem("name") : null;
                if (nameAttr == null) continue;
                String varName = nameAttr.getNodeValue();
                String selectVal = null;
                Node selectAttr = node.getAttributes().getNamedItem("select");
                if (selectAttr != null) {
                    selectVal = trimQuotes(selectAttr.getNodeValue());
                } else if (node.getFirstChild() != null) {
                    selectVal = trimQuotes(node.getTextContent());
                }
                if (selectVal != null) {
                    varNameToValue.put(varName, selectVal);
                }
            }

            // Identify userField* variables; parse their metadata
            for (Map.Entry<String, String> entry : varNameToValue.entrySet()) {
                String var = entry.getKey();
                if (!var.startsWith("userField")) continue;
                String select = entry.getValue();
                List<String> tokens = splitByPipe(select);
                if (tokens.size() < 3) continue; // require at least variableName|prompt|type

                String variableName = tokens.get(0);
                String prompt = tokens.get(1);
                String typeStr = tokens.get(2).toUpperCase(Locale.US);

                XsltUserVariable.Type type = XsltUserVariable.Type.STRING;
                if ("DOUBLE".equals(typeStr)) type = XsltUserVariable.Type.DOUBLE;
                else if ("INTEGER".equals(typeStr)) type = XsltUserVariable.Type.INTEGER;
                else if ("STRING".equals(typeStr)) type = XsltUserVariable.Type.STRING;
                else if ("STRINGMENU".equals(typeStr)) type = XsltUserVariable.Type.STRING_MENU;

                String min = "";
                String max = "";
                List<String> options = new ArrayList<>();
                if (type == XsltUserVariable.Type.DOUBLE || type == XsltUserVariable.Type.INTEGER) {
                    if (tokens.size() >= 4) min = tokens.get(3);
                    if (tokens.size() >= 5) max = tokens.get(4);
                } else if (type == XsltUserVariable.Type.STRING_MENU) {
                    if (tokens.size() >= 4) {
                        int count = safeParseInt(tokens.get(3));
                        List<String> items = new ArrayList<>();
                        for (int idx = 0; idx < count && 4 + idx < tokens.size(); idx++) {
                            items.add(tokens.get(4 + idx));
                        }
                        options = items;
                    }
                }

                // default value comes from a variable whose name matches the variableName
                String defaultVal = varNameToValue.getOrDefault(variableName, "");

                XsltUserVariable model = new XsltUserVariable.Builder()
                        .setVariableName(variableName)
                        .setPrompt(prompt)
                        .setType(type)
                        .setMinValue(min)
                        .setMaxValue(max)
                        .setOptions(options)
                        .setDefaultValue(defaultVal)
                        .build();
                result.add(model);
            }
        } catch (Exception e) {

        }
        return result;
    }


    private static String trimQuotes( String s) {
        String t = s.trim();
        if ((t.startsWith("\"") && t.endsWith("\"")) || (t.startsWith("'") && t.endsWith("'"))) {
            return t.substring(1, t.length() - 1);
        }
        return t;
    }


    private static List<String> splitByPipe(String s) {
        if (s.length() == 0) return new ArrayList<>();
        return new ArrayList<>(Arrays.asList(s.split("\\|")));
    }

    private static int safeParseInt(String s) {
        try {
            return Integer.parseInt(s.trim());
        } catch (Exception e) {
            return 0;
        }
    }
}


