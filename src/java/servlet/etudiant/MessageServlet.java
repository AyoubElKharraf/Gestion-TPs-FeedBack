package servlet.etudiant;

import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.TravailPratiqueDAO;
import model.Etudiant;
import model.Enseignant;
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
 * Étudiant : envoyer un message (commentaire) à un Enseignant (de ses modules / TPs).
 */
@WebServlet("/etudiant/MessageServlet")
public class MessageServlet extends HttpServlet {

    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Etudiant etu = getEtudiant(req, resp);
        if (etu == null) return;
        List<Enseignant> enseignants = tpDAO.findEnseignantsByEtudiant(etu.getId());
        req.setAttribute("enseignants", enseignants);
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                req.setAttribute("preselectedDestinataireId", Long.parseLong(destParam.trim()));
            } catch (NumberFormatException ignored) {}
        }
        req.setAttribute("nbNotifs", notifDAO.countNonLues(etu.getId()));
        req.getRequestDispatcher("/WEB-INF/vues/etduaint/message.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Etudiant etu = getEtudiant(req, resp);
        if (etu == null) return;
        req.setCharacterEncoding("UTF-8");
        String idParam = req.getParameter("destinataireId");
        String message = req.getParameter("message");
        if (idParam == null || message == null || message.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/etudiant/MessageServlet?error=1");
            return;
        }
        Long id = Long.parseLong(idParam.trim());
        List<Enseignant> enseignants = tpDAO.findEnseignantsByEtudiant(etu.getId());
        Enseignant dest = enseignants.stream().filter(e -> e.getId().equals(id)).findFirst().orElse(null);
        if (dest == null) {
            resp.sendRedirect(req.getContextPath() + "/etudiant/MessageServlet?error=2");
            return;
        }
        NotificationService.envoyerMessage(etu, dest, message);
        resp.sendRedirect(req.getContextPath() + "/etudiant/MessageServlet?sent=1");
    }

    private Etudiant getEtudiant(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Utilisateur u = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ETUDIANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        return new EtudiantDAO().findById(u.getId());
    }
}
