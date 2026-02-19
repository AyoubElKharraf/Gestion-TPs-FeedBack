package servlet.enseignant;

import dao.EnseignantDAO;
import dao.NotificationDAO;
import dao.TravailPratiqueDAO;
import dao.UtilisateurDAO;
import model.Enseignant;
import model.Etudiant;
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
 * Enseignant : envoyer un message (commentaire) à un Étudiant (de ses modules).
 */
@WebServlet("/enseignant/MessageServlet")
public class MessageServlet extends HttpServlet {

    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Enseignant ens = getEnseignant(req, resp);
        if (ens == null) return;
        List<Etudiant> etudiants = tpDAO.findEtudiantsByEnseignant(ens.getId());
        req.setAttribute("etudiants", etudiants);
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                Long destId = Long.parseLong(destParam.trim());
                req.setAttribute("preselectedDestinataireId", destId);
                boolean inList = etudiants.stream().anyMatch(e -> e.getId().equals(destId));
                if (!inList) {
                    Utilisateur other = utilisateurDAO.findById(destId);
                    if (other != null && other.getRole() == Utilisateur.Role.ADMIN) {
                        req.setAttribute("replyToUser", other);
                    }
                }
            } catch (NumberFormatException ignored) {}
        }
        req.setAttribute("nbNotifs", notifDAO.countNonLues(ens.getId()));
        req.setAttribute("activeSection", "messages");
        req.getRequestDispatcher("/WEB-INF/vues/enseignant/message.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Enseignant ens = getEnseignant(req, resp);
        if (ens == null) return;
        req.setCharacterEncoding("UTF-8");
        String idParam = req.getParameter("destinataireId");
        String message = req.getParameter("message");
        if (idParam == null || message == null || message.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?error=1");
            return;
        }
        Long id = Long.parseLong(idParam.trim());
        List<Etudiant> etudiants = tpDAO.findEtudiantsByEnseignant(ens.getId());
        Etudiant destEtudiant = etudiants.stream().filter(e -> e.getId().equals(id)).findFirst().orElse(null);
        if (destEtudiant != null) {
            NotificationService.envoyerMessage(ens, destEtudiant, message);
            resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?sent=1");
            return;
        }
        Utilisateur destUser = utilisateurDAO.findById(id);
        if (destUser != null && destUser.getRole() == Utilisateur.Role.ADMIN) {
            NotificationService.envoyerMessage(ens, destUser, message);
            resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?sent=1");
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?error=2");
    }

    private Enseignant getEnseignant(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Utilisateur u = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        return new EnseignantDAO().findById(u.getId());
    }
}
