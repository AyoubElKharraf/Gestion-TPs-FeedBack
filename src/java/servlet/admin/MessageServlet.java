package servlet.admin;

import dao.EnseignantDAO;
import dao.EtudiantDAO;
import dao.UtilisateurDAO;
import model.Utilisateur;
import util.NotificationService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

/**
 * Admin : envoyer un message (commentaire) à un Enseignant ou un Etudiant.
 */
@WebServlet("/admin/MessageServlet")
public class MessageServlet extends HttpServlet {

    private final EnseignantDAO enseignantDAO = new EnseignantDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Utilisateur admin = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
        if (admin == null || admin.getRole() != Utilisateur.Role.ADMIN) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        req.setAttribute("enseignants", enseignantDAO.findAll());
        req.setAttribute("etudiants", etudiantDAO.findAll());
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                req.setAttribute("preselectedDestinataireId", Long.parseLong(destParam.trim()));
            } catch (NumberFormatException ignored) {}
        }
        req.setAttribute("activeSection", "messages");
        req.getRequestDispatcher("/WEB-INF/vues/admin/messages.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Utilisateur admin = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
        if (admin == null || admin.getRole() != Utilisateur.Role.ADMIN) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String type = req.getParameter("type");
        String idParam = req.getParameter("destinataireId");
        String message = req.getParameter("message");
        if (type == null || idParam == null || message == null || message.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/admin/MessageServlet?error=1");
            return;
        }
        Long id = Long.parseLong(idParam.trim());
        Utilisateur destinataire = utilisateurDAO.findById(id);
        if (destinataire == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/MessageServlet?error=2");
            return;
        }
        NotificationService.envoyerMessage(admin, destinataire, message);
        resp.sendRedirect(req.getContextPath() + "/admin/MessageServlet?sent=1");
    }
}
