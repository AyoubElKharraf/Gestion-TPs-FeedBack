package servlet.api;

import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.UtilisateurDAO;
import model.Etudiant;
import model.Notification;
import model.Utilisateur;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * API REST pour recevoir les alertes dépassement d'absences depuis Gestion_AbsencesAlerts.
 * POST /api/alerte-depassement
 * Body JSON: { "emailEtudiant": "...", "nbAbsences": n }
 * Marque l'étudiant aSupprimer=true, met à jour nbAbsences, et notifie les admins.
 */
@WebServlet("/api/alerte-depassement")
public class AlerteDepassementApiServlet extends HttpServlet {

    private static final Pattern P_EMAIL = Pattern.compile("\"emailEtudiant\"\\s*:\\s*\"([^\"]*)\"");
    private static final Pattern P_NB = Pattern.compile("\"nbAbsences\"\\s*:\\s*(\\d+)");

    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        addCors(resp);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");

        String body = readBody(req);
        String emailEtudiant = match(P_EMAIL, body, 1);
        Integer nbAbsences = null;
        Matcher mNb = P_NB.matcher(body != null ? body : "");
        if (mNb.find()) {
            try {
                nbAbsences = Integer.parseInt(mNb.group(1));
            } catch (NumberFormatException ignored) {}
        }

        if (emailEtudiant == null || emailEtudiant.isBlank()) {
            sendJson(resp, false, "emailEtudiant requis", null);
            return;
        }

        Etudiant etudiant = etudiantDAO.findByEmail(emailEtudiant);
        if (etudiant == null) {
            sendJson(resp, false, "Étudiant introuvable: " + emailEtudiant, null);
            return;
        }

        int n = nbAbsences != null ? nbAbsences : etudiant.getNbAbsences();
        etudiantDAO.updateAbsencesAndFlag(etudiant.getId(), n, true);

        String nomComplet = etudiant.getNomComplet();
        String message = String.format(
            "⚠️ Alerte (Gestion_AbsencesAlerts): L'étudiant %s (%s) a dépassé la limite d'absences (%d absences non justifiées chez 3 enseignants ou plus). Il ne peut pas continuer dans le master et doit être supprimé.",
            nomComplet, emailEtudiant, n
        );

        List<Utilisateur> admins = utilisateurDAO.findByRole(Utilisateur.Role.ADMIN);
        for (Utilisateur admin : admins) {
            Notification notif = new Notification();
            notif.setMessage(message);
            notif.setDestinataire(admin);
            notif.setExpediteur(null);
            notificationDAO.save(notif);
        }

        sendJson(resp, true, null, "Étudiant marqué à supprimer, admins notifiés.");
    }

    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        addCors(resp);
        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        addCors(resp);
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print("{\"api\":\"alerte-depassement\",\"method\":\"POST\",\"body\":\"emailEtudiant, nbAbsences\"}");
    }

    private static String readBody(HttpServletRequest req) throws IOException {
        try (Scanner s = new Scanner(req.getInputStream(), StandardCharsets.UTF_8).useDelimiter("\\A")) {
            return s.hasNext() ? s.next() : "";
        }
    }

    private static String match(Pattern p, String body, int group) {
        if (body == null) return null;
        Matcher m = p.matcher(body);
        return m.find() ? m.group(group).trim() : null;
    }

    private void addCors(HttpServletResponse resp) {
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type, X-API-Key");
    }

    private void sendJson(HttpServletResponse resp, boolean success, String error, String message) throws IOException {
        PrintWriter out = resp.getWriter();
        out.print("{\"success\":");
        out.print(success);
        if (error != null) {
            out.print(",\"error\":\"");
            out.print(escapeJson(error));
            out.print("\"");
        }
        if (message != null) {
            out.print(",\"message\":\"");
            out.print(escapeJson(message));
            out.print("\"");
        }
        out.print("}");
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
