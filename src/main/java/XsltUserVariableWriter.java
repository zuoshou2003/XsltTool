import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

/**
 * Utility to update default values of user variables in an XSLT file.
 * It finds <xsl:variable name="{variableName}"> nodes (NOT the userField* descriptors)
 * and updates their value in the select attribute (or text content if select missing).
 */
public final class XsltUserVariableWriter {

    private static final String NS_XSL = "http://www.w3.org/1999/XSL/Transform";

    private XsltUserVariableWriter() {}

    public static void applyUpdates(File xsltFile, Map<String, String> variableNameToNewValue) throws Exception {
        if (variableNameToNewValue == null || variableNameToNewValue.isEmpty()) return;

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.parse(xsltFile);

        NodeList variables = doc.getElementsByTagNameNS(NS_XSL, "variable");
        Map<String, Node> nameToNode = new HashMap<>();
        for (int i = 0; i < variables.getLength(); i++) {
            Node node = variables.item(i);
            Node nameAttr = node.getAttributes() != null ? node.getAttributes().getNamedItem("name") : null;
            if (nameAttr == null) continue;
            nameToNode.put(nameAttr.getNodeValue(), node);
        }

        boolean changed = false;
        for (Map.Entry<String, String> entry : variableNameToNewValue.entrySet()) {
            String varName = entry.getKey();
            String newVal = entry.getValue();
            if (varName == null || varName.startsWith("userField") || !nameToNode.containsKey(varName)) {
                continue;
            }
            Node node = nameToNode.get(varName);
            Node selectAttr = node.getAttributes().getNamedItem("select");
            String quoted = quoteForXsltSelect(newVal);
            if (selectAttr != null) {
                if (!quoted.equals(selectAttr.getNodeValue())) {
                    selectAttr.setNodeValue(quoted);
                    changed = true;
                }
            } else {
                // No select: replace text content
                if (!newVal.equals(node.getTextContent())) {
                    node.setTextContent(newVal);
                    changed = true;
                }
            }
        }

        if (changed) {
            TransformerFactory tf = TransformerFactory.newInstance();
            Transformer transformer = tf.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.transform(new DOMSource(doc), new StreamResult(xsltFile));
        }
    }

    private static String quoteForXsltSelect(String value) {
        if (value == null) value = "";
        // Prefer single quotes in XSLT select. Escape embedded single quotes using &apos;
        String escaped = value.replace("'", "&apos;");
        return "'" + escaped + "'";
    }
}


