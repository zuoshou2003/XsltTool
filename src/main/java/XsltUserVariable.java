
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Model describing a user-configurable variable discovered in an XSLT file.
 */
public final class XsltUserVariable {

    public enum Type {
        DOUBLE,
        INTEGER,
        STRING,
        STRING_MENU
    }

    private final String variableName;
    private final String prompt;
    private final Type type;
    private final String minValue;
    private final String maxValue;
    private final List<String> options;
    private final String defaultValue;

    private XsltUserVariable(Builder builder) {
        this.variableName = builder.variableName;
        this.prompt = builder.prompt;
        this.type = builder.type;
        this.minValue = builder.minValue;
        this.maxValue = builder.maxValue;
        this.options = Collections.unmodifiableList(new ArrayList<>(builder.options));
        this.defaultValue = builder.defaultValue;
    }

    public String getVariableName() {
        return variableName;
    }

    public String getPrompt() {
        return prompt;
    }

    public Type getType() {
        return type;
    }

    public String getMinValue() {
        return minValue;
    }

    public String getMaxValue() {
        return maxValue;
    }

    public List<String> getOptions() {
        return options;
    }

    public String getDefaultValue() {
        return defaultValue;
    }

    public static final class Builder {
        private String variableName = "";
        private String prompt = "";
        private Type type = Type.STRING;
        private String minValue = "";
        private String maxValue = "";
        private List<String> options = new ArrayList<>();
        private String defaultValue = "";


        public Builder setVariableName(String variableName) {
            this.variableName = variableName;
            return this;
        }

        public Builder setPrompt( String prompt) {
            this.prompt = prompt;
            return this;
        }

        public Builder setType(Type type) {
            this.type = type;
            return this;
        }

        public Builder setMinValue(String minValue) {
            this.minValue = minValue;
            return this;
        }

        public Builder setMaxValue(String maxValue) {
            this.maxValue = maxValue;
            return this;
        }

        public Builder setOptions(List<String> options) {
            this.options = options;
            return this;
        }

        public Builder setDefaultValue(String defaultValue) {
            this.defaultValue = defaultValue;
            return this;
        }

        public XsltUserVariable build() {
            return new XsltUserVariable(this);
        }
    }
}


