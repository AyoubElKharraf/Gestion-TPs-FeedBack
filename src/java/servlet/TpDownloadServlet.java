package servlet;

import dao.TravailPratiqueDAO;
import model.TravailPratique;
import model.Utilisateur;
import util.FileUploadUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * Téléchargement / affichage du fichier d'un TP.
 * GET ?id=&lt;tpId&gt; : envoie le fichier (inline pour affichage PDF dans le navigateur).
 * Accès : admin, enseignant du module, ou étudiant auteur du TP.
 */
@WebServlet("/TpDownloadServlet")
public class TpDownloadServlet extends HttpServlet {

    private static final Map<String, String> CONTENT_TYPES = new HashMap<>();
    static {
        CONTENT_TYPES.put(".pdf", "application/pdf");
        CONTENT_TYPES.put(".doc", "application/msword");
        CONTENT_TYPES.put(".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
        CONTENT_TYPES.put(".zip", "application/zip");
        CONTENT_TYPES.put(".rar", "application/x-rar-compressed");
        CONTENT_TYPES.put(".txt", "text/plain");
        CONTENT_TYPES.put(".png", "image/png");
        CONTENT_TYPES.put(".jpg", "image/jpeg");
        CONTENT_TYPES.put(".jpeg", "image/jpeg");
    }

    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Object userObj = (session != null) ? session.getAttribute("utilisateur") : null;
        Utilisateur u = (userObj instanceof Utilisateur) ? (Utilisateur) userObj : null;
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }

        String idParam = req.getParameter("id");
        if (idParam == null || idParam.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "id manquant");
            return;
        }
        Long tpId;
        try {
            tpId = Long.parseLong(idParam);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "id invalide");
            return;
        }

        TravailPratique tp = tpDAO.findById(tpId);
        if (tp == null || tp.getCheminFichier() == null || tp.getCheminFichier().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "TP ou fichier introuvable");
            return;
        }

        boolean allowed = false;
        switch (u.getRole()) {
            case ADMIN -> allowed = true;
            case ENSEIGNANT -> allowed = tp.getModule() != null && tp.getModule().getEnseignant() != null
                && tp.getModule().getEnseignant().getId().equals(u.getId());
            case ETUDIANT -> allowed = tp.getEtudiant() != null && tp.getEtudiant().getId().equals(u.getId());
            default -> {}
        }
        if (!allowed) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Accès refusé");
            return;
        }

        Path filePath = Paths.get(FileUploadUtil.UPLOAD_DIR, tp.getCheminFichier());
        if (!Files.exists(filePath) || !Files.isRegularFile(filePath)) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Fichier introuvable sur le serveur");
            return;
        }

        String nomFichier = tp.getNomFichier() != null ? tp.getNomFichier() : "tp";
        String ext = nomFichier.contains(".") ? nomFichier.substring(nomFichier.lastIndexOf('.')) : "";
        String contentType = CONTENT_TYPES.getOrDefault(ext.toLowerCase(), "application/octet-stream");
        resp.setContentType(contentType);
        // inline pour affichage dans le navigateur (ex. PDF), pas en téléchargement
        String safeName = nomFichier.replace("\"", "%22");
        resp.setHeader("Content-Disposition", "inline; filename=\"" + safeName + "\"");

        resp.setContentLengthLong(Files.size(filePath));
        try (OutputStream out = resp.getOutputStream()) {
            Files.copy(filePath, out);
        }
    }
}
