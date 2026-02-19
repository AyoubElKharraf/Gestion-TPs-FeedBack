package servlet;

import dao.RapportDAO;
import model.Rapport;
import model.Utilisateur;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.OutputStream;

/**
 * Téléchargement d'un rapport. Accès: admin, enseignant propriétaire du module, ou etudiant.
 */
@WebServlet("/RapportDownloadServlet")
public class RapportDownloadServlet extends HttpServlet {

    private final RapportDAO rapportDAO = new RapportDAO();

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
        if (idParam == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "id manquant");
            return;
        }
        Long id = Long.parseLong(idParam);
        Rapport r = rapportDAO.findByIdWithModule(id);
        if (r == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Rapport introuvable");
            return;
        }

        boolean allowed = false;
        switch (u.getRole()) {
            case ADMIN -> allowed = true;
            case ENSEIGNANT -> allowed = r.getModule() != null && r.getModule().getEnseignant() != null
                && r.getModule().getEnseignant().getId().equals(u.getId());
            case ETUDIANT -> allowed = true;
        }
        if (!allowed) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Accès refusé");
            return;
        }

        String contentType = r.getContentType();
        if (contentType == null || contentType.isEmpty()) contentType = "application/octet-stream";
        resp.setContentType(contentType);
        String fileName = r.getFileName() != null ? r.getFileName() : "rapport";
        resp.setHeader("Content-Disposition", "attachment; filename=\"" + fileName.replace("\"", "%22") + "\"");

        byte[] data = r.getFileContent();
        if (data != null && data.length > 0) {
            resp.setContentLength(data.length);
            try (OutputStream out = resp.getOutputStream()) {
                out.write(data);
            }
        }
    }
}
