package servlet.api;

import dao.AbsenceReportDAO;
import dao.EtudiantDAO;
import dao.UtilisateurDAO;
import model.AbsenceReport;
import model.Etudiant;
import model.Enseignant;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * REST API pour l'application Absence (externe).
 * POST /api/absence : enregistre un signalement d'absence (étudiant + enseignant).
 * Corps : application/x-www-form-urlencoded (etudiantId, enseignantId)
 *     ou application/json : {"etudiantId": 1, "enseignantId": 2}
 * Réponse JSON : {"success": true, "etudiantId": 1, "nbAbsences": 3, "aSupprimer": true}
 * ou {"success": false, "error": "..."}
 */
@WebServlet("/api/absence")
public class AbsenceReportApiServlet extends HttpServlet {

    private static final Pattern JSON_ETUDIANT_ID = Pattern.compile("\"etudiantId\"\\s*:\\s*(\\d+)");
    private static final Pattern JSON_ENSEIGNANT_ID = Pattern.compile("\"enseignantId\"\\s*:\\s*(\\d+)");

    private final AbsenceReportDAO absenceReportDAO = new AbsenceReportDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        addCors(resp);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");

        Long etudiantId = null;
        Long enseignantId = null;

        String contentType = req.getContentType();
        if (contentType != null && contentType.toLowerCase().contains("application/json")) {
            String body = readBody(req);
            etudiantId = parseJsonLong(body, JSON_ETUDIANT_ID);
            enseignantId = parseJsonLong(body, JSON_ENSEIGNANT_ID);
        } else {
            String eId = req.getParameter("etudiantId");
            String ensId = req.getParameter("enseignantId");
            if (eId != null && !eId.isBlank()) etudiantId = parseLongSafe(eId);
            if (ensId != null && !ensId.isBlank()) enseignantId = parseLongSafe(ensId);
        }

        if (etudiantId == null || enseignantId == null) {
            sendJson(resp, false, "Paramètres requis : etudiantId et enseignantId (form ou JSON).", null, null, null);
            return;
        }

        Etudiant etudiant = etudiantDAO.findById(etudiantId);
        if (etudiant == null) {
            sendJson(resp, false, "Étudiant introuvable : " + etudiantId, null, null, null);
            return;
        }

        Enseignant enseignant = utilisateurDAO.findEnseignantById(enseignantId);
        if (enseignant == null) {
            sendJson(resp, false, "Enseignant introuvable : " + enseignantId, null, null, null);
            return;
        }

        AbsenceReport report = new AbsenceReport();
        report.setEtudiant(etudiant);
        report.setEnseignant(enseignant);
        absenceReportDAO.save(report);

        long nbAbsences = absenceReportDAO.countByEtudiant(etudiantId);
        long distinctEnseignants = absenceReportDAO.countDistinctEnseignantsByEtudiant(etudiantId);
        boolean aSupprimer = distinctEnseignants >= 3;

        etudiant.setNbAbsences((int) nbAbsences);
        etudiant.setASupprimer(aSupprimer);
        etudiantDAO.update(etudiant);

        sendJson(resp, true, null, etudiantId, (int) nbAbsences, aSupprimer);
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
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        out.print("{\"api\":\"absence\",\"method\":\"POST\",\"body\":\"etudiantId=<id>&enseignantId=<id> or JSON {\\\"etudiantId\\\":1,\\\"enseignantId\\\":2}\"}");
    }

    private void addCors(HttpServletResponse resp) {
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
    }

    private static String readBody(HttpServletRequest req) throws IOException {
        try (Scanner s = new Scanner(req.getInputStream(), StandardCharsets.UTF_8).useDelimiter("\\A")) {
            return s.hasNext() ? s.next() : "";
        }
    }

    private static Long parseJsonLong(String body, Pattern p) {
        Matcher m = p.matcher(body);
        return m.find() ? parseLongSafe(m.group(1)) : null;
    }

    private static Long parseLongSafe(String s) {
        try {
            return Long.valueOf(s.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private void sendJson(HttpServletResponse resp, boolean success, String error,
                          Long etudiantId, Integer nbAbsences, Boolean aSupprimer) throws IOException {
        PrintWriter out = resp.getWriter();
        out.print("{\"success\":");
        out.print(success);
        if (error != null) {
            out.print(",\"error\":\"");
            out.print(escapeJson(error));
            out.print("\"");
        }
        if (etudiantId != null) out.print(",\"etudiantId\":" + etudiantId);
        if (nbAbsences != null) out.print(",\"nbAbsences\":" + nbAbsences);
        if (aSupprimer != null) out.print(",\"aSupprimer\":" + aSupprimer);
        out.print("}");
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
