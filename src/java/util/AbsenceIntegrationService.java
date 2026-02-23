package util;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

/**
 * Service d'intégration avec le système d'absences (externe).
 * Envoie des notifications lorsque :
 * - Un étudiant n'a pas rendu son TP à la date limite.
 * - Trois enseignants ont déclaré un même étudiant (dépassement limite d'absences).
 * L'URL cible est lue depuis la propriété système "absence.system.url" ou la variable d'environnement ABSENCE_SYSTEM_URL.
 */
public final class AbsenceIntegrationService {

    private static final String CONFIG_KEY = "absence.system.url";
    private static final String ENV_KEY = "ABSENCE_SYSTEM_URL";

    private static String getBaseUrl() {
        String url = System.getProperty(CONFIG_KEY);
        if (url == null || url.isEmpty()) {
            url = System.getenv(ENV_KEY);
        }
        return (url != null && !url.isEmpty()) ? url.replaceAll("/+$", "") : null;
    }

    /**
     * Notifie le système d'absences qu'un étudiant n'a pas rendu son TP (date limite dépassée).
     */
    public static void notifyNonRemisTp(Long etudiantId, Long moduleId, String moduleNom, String rapportTitre) {
        String base = getBaseUrl();
        if (base == null) return;
        String payload = String.format(
            "{\"type\":\"non_remis_tp\",\"etudiantId\":%d,\"moduleId\":%d,\"moduleNom\":\"%s\",\"rapportTitre\":\"%s\"}",
            etudiantId, moduleId != null ? moduleId : 0,
            escapeJson(moduleNom), escapeJson(rapportTitre)
        );
        post(base + "/api/alerte", payload);
    }

    /**
     * Notifie le système d'absences qu'un étudiant a dépassé la limite d'absences (3 enseignants ont déclaré).
     */
    public static void notifyDepassementAbsences(Long etudiantId) {
        String base = getBaseUrl();
        if (base == null) return;
        String payload = String.format(
            "{\"type\":\"depassement_absences\",\"etudiantId\":%d}",
            etudiantId
        );
        post(base + "/api/alerte", payload);
    }

    private static void post(String urlString, String jsonBody) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setDoOutput(true);
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }
            int code = conn.getResponseCode();
            conn.disconnect();
        } catch (Exception e) {
            // Ne pas faire échouer l'application si le système d'absences est indisponible
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
