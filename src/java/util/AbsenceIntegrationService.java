package util;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
     * Notifie le système d'absences (Gestion_AbsencesAlerts) qu'un étudiant n'a pas rendu son TP (date limite dépassée).
     * Utilise emailEtudiant et emailEnseignant pour que le système externe puisse identifier les entités.
     * @param baseUrlOverride URL de base (ex: depuis context-param). Si null, utilise getBaseUrl().
     * @return true si la requête a été envoyée et le serveur a répondu 2xx, false sinon (URL non configurée, erreur réseau, ou erreur côté serveur).
     */
    public static boolean notifyNonRemisTp(Long etudiantId, Long moduleId, String moduleNom, String rapportTitre,
                                          String emailEtudiant, String emailEnseignant, String baseUrlOverride) {
        String base = (baseUrlOverride != null && !baseUrlOverride.isEmpty())
            ? baseUrlOverride.replaceAll("/+$", "") : getBaseUrl();
        if (base == null) return false;
        String payload = String.format(
            "{\"type\":\"non_remis_tp\",\"emailEtudiant\":\"%s\",\"emailEnseignant\":\"%s\",\"moduleNom\":\"%s\",\"rapportTitre\":\"%s\"}",
            escapeJson(emailEtudiant != null ? emailEtudiant : ""),
            escapeJson(emailEnseignant != null ? emailEnseignant : ""),
            escapeJson(moduleNom), escapeJson(rapportTitre)
        );
        return post(base + "/api/alerte", payload);
    }

    /** Appel sans override : utilise propriété système ou variable d'environnement. */
    public static boolean notifyNonRemisTp(Long etudiantId, Long moduleId, String moduleNom, String rapportTitre,
                                            String emailEtudiant, String emailEnseignant) {
        return notifyNonRemisTp(etudiantId, moduleId, moduleNom, rapportTitre, emailEtudiant, emailEnseignant, null);
    }

    /**
     * Récupère la liste des absences par enseignant pour un étudiant (email @etudacadpro.com).
     * Appelle GET &lt;base&gt;/api/etudiant/absences-par-enseignant?email=...
     * @param baseUrlOverride URL de base (ex: depuis context-param). Si null, utilise getBaseUrl().
     * @return liste de [nom enseignant, nombre d'absences] ; liste vide si indisponible.
     */
    public static List<AbsenceParEnseignant> getAbsencesParEnseignant(String emailEtudiant, String baseUrlOverride) {
        String base = (baseUrlOverride != null && !baseUrlOverride.isEmpty())
            ? baseUrlOverride.replaceAll("/+$", "") : getBaseUrl();
        if (base == null || emailEtudiant == null || emailEtudiant.isBlank()) return new ArrayList<>();
        try {
            String urlString = base + "/api/etudiant/absences-par-enseignant?email="
                + URLEncoder.encode(emailEtudiant.trim(), StandardCharsets.UTF_8.name());
            String json = get(urlString);
            return parseAbsencesParEnseignant(json);
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private static String get(String urlString) throws Exception {
        URL url = new URL(urlString);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(4000);
        conn.setReadTimeout(4000);
        String body = readResponseBody(conn);
        conn.disconnect();
        return body;
    }

    /** Parse JSON array [ {"enseignantNom":"...", "nbAbsences": n }, ... ] */
    private static List<AbsenceParEnseignant> parseAbsencesParEnseignant(String json) {
        List<AbsenceParEnseignant> out = new ArrayList<>();
        if (json == null || json.trim().isEmpty()) return out;
        Pattern block = Pattern.compile("\\{\\s*\"enseignantNom\"\\s*:\\s*\"([^\"]*)\"\\s*,\\s*\"nbAbsences\"\\s*:\\s*(\\d+)\\s*\\}");
        Matcher m = block.matcher(json);
        while (m.find()) {
            String nom = m.group(1).replace("\\\"", "\"");
            int nb = Integer.parseInt(m.group(2));
            out.add(new AbsenceParEnseignant(nom, nb));
        }
        return out;
    }

    /** DTO pour affichage absences par enseignant sur la fiche étudiant. */
    public static class AbsenceParEnseignant {
        private final String enseignantNom;
        private final int nbAbsences;
        public AbsenceParEnseignant(String enseignantNom, int nbAbsences) {
            this.enseignantNom = enseignantNom;
            this.nbAbsences = nbAbsences;
        }
        public String getEnseignantNom() { return enseignantNom; }
        public int getNbAbsences() { return nbAbsences; }
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

    /** @return true seulement si réponse 2xx ET le corps JSON contient "success":true (évite faux positif si une autre URL renvoie 200) */
    private static boolean post(String urlString, String jsonBody) {
        HttpURLConnection conn = null;
        int code = -1;
        String responseBody = "";
        try {
            URL url = new URL(urlString);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setDoOutput(true);
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }
            code = conn.getResponseCode();
            responseBody = readResponseBody(conn);
            conn.disconnect();
            if (code < 200 || code >= 300) {
                conn.disconnect();
                AppLogger.warn("AbsenceIntegrationService",
                    "API alerte: HTTP " + code + " pour " + urlString + " | réponse: " + (responseBody != null ? responseBody.substring(0, Math.min(200, responseBody.length())) : ""));
                return false;
            }
            boolean ok = responseBody != null && responseBody.contains("\"success\":true");
            if (!ok) {
                AppLogger.warn("AbsenceIntegrationService",
                    "API alerte: réponse 2xx mais pas de \"success\":true pour " + urlString + " | corps: " + (responseBody != null ? responseBody.substring(0, Math.min(200, responseBody.length())) : ""));
            }
            return ok;
        } catch (Exception e) {
            if (conn != null) try { conn.disconnect(); } catch (Exception ignored) {}
            AppLogger.warn("AbsenceIntegrationService", "API alerte échec: " + urlString + " | " + e.getMessage(), e);
            return false;
        }
    }

    private static String readResponseBody(HttpURLConnection conn) {
        try {
            InputStream in = conn.getErrorStream() != null ? conn.getErrorStream() : conn.getInputStream();
            if (in == null) return "";
            try (Scanner s = new Scanner(in, StandardCharsets.UTF_8).useDelimiter("\\A")) {
                return s.hasNext() ? s.next() : "";
            }
        } catch (Exception e) {
            return "";
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
