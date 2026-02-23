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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
        Map<Long, java.util.Date> lastMessageDateMap = new HashMap<>();
        Map<Long, Long> unreadCountMap = new HashMap<>();
        for (Etudiant e : etudiants) {
            lastMessageDateMap.put(e.getId(), notifDAO.getLastMessageDate(ens.getId(), e.getId()));
            unreadCountMap.put(e.getId(), notifDAO.countUnreadFrom(ens.getId(), e.getId()));
        }
        req.setAttribute("lastMessageDateMap", lastMessageDateMap);
        req.setAttribute("unreadCountMap", unreadCountMap);
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                Long destId = Long.parseLong(destParam.trim());
                req.setAttribute("preselectedDestinataireId", destId);
                notifDAO.marquerLuesFromExpediteur(ens.getId(), destId);
                Utilisateur otherUser = etudiants.stream().filter(e -> e.getId().equals(destId)).findFirst().orElse(null);
                if (otherUser == null) otherUser = utilisateurDAO.findById(destId);
                if (otherUser != null) {
                    req.setAttribute("replyToUser", otherUser);
                    req.setAttribute("conversation", notifDAO.findConversation(ens.getId(), destId));
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
            resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?destinataireId=" + id + "&sent=1");
            return;
        }
        Utilisateur destUser = utilisateurDAO.findById(id);
        if (destUser != null && destUser.getRole() == Utilisateur.Role.ADMIN) {
            NotificationService.envoyerMessage(ens, destUser, message);
            resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?destinataireId=" + id + "&sent=1");
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/enseignant/MessageServlet?error=2");
    }

    private Enseignant getEnseignant(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        return new EnseignantDAO().findById(u.getId());
    }
}
