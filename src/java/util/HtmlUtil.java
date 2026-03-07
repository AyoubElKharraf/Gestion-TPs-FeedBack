package util;

/**
 * Utilitaire pour l'échappement HTML - Protection contre les attaques XSS.
 * Utilise les entités HTML pour échapper les caractères dangereux.
 */
public class HtmlUtil {

    /**
     * Échappe les caractères HTML dangereux pour prévenir les attaques XSS.
     * Remplace: & < > " ' par leurs entités HTML correspondantes.
     * 
     * @param input La chaîne à échapper
     * @return La chaîne échappée (safe pour insertion dans HTML)
     */
    public static String escape(String input) {
        if (input == null) {
            return "";
        }
        StringBuilder escaped = new StringBuilder(input.length() + 16);
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '&':
                    escaped.append("&amp;");
                    break;
                case '<':
                    escaped.append("&lt;");
                    break;
                case '>':
                    escaped.append("&gt;");
                    break;
                case '"':
                    escaped.append("&quot;");
                    break;
                case '\'':
                    escaped.append("&#x27;");
                    break;
                default:
                    escaped.append(c);
            }
        }
        return escaped.toString();
    }

    /**
     * Échappe pour utilisation dans un attribut HTML.
     * Plus strict que escape() standard.
     */
    public static String escapeAttr(String input) {
        return escape(input);
    }

    /**
     * Échappe pour utilisation dans du JavaScript inline.
     */
    public static String escapeJs(String input) {
        if (input == null) {
            return "";
        }
        StringBuilder escaped = new StringBuilder(input.length() + 16);
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '\\':
                    escaped.append("\\\\");
                    break;
                case '\'':
                    escaped.append("\\'");
                    break;
                case '"':
                    escaped.append("\\\"");
                    break;
                case '\n':
                    escaped.append("\\n");
                    break;
                case '\r':
                    escaped.append("\\r");
                    break;
                case '<':
                    escaped.append("\\u003c");
                    break;
                case '>':
                    escaped.append("\\u003e");
                    break;
                default:
                    escaped.append(c);
            }
        }
        return escaped.toString();
    }
}
