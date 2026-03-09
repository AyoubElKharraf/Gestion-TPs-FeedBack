package servlet.etudiant;

import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.TravailPratiqueDAO;
import dao.UtilisateurDAO;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Étudiant : envoyer un message (commentaire) à un Enseignant (de ses modules / TPs).
 */
@WebServlet("/etudiant/MessageServlet")
public class MessageServlet extends HttpServlet {

    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Etudiant etu = getEtudiant(req, resp);
        if (etu == null) return;
        List<Enseignant> enseignants = tpDAO.findEnseignantsByEtudiant(etu.getId());
        req.setAttribute("enseignants", enseignants);
        Map<Long, java.util.Date> lastMessageDateMap = new HashMap<>();
        Map<Long, Long> unreadCountMap = new HashMap<>();
        for (Enseignant e : enseignants) {
            lastMessageDateMap.put(e.getId(), notifDAO.getLastMessageDate(etu.getId(), e.getId()));
            unreadCountMap.put(e.getId(), notifDAO.countUnreadFrom(etu.getId(), e.getId()));
        }
        req.setAttribute("lastMessageDateMap", lastMessageDateMap);
        req.setAttribute("unreadCountMap", unreadCountMap);
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                Long destId = Long.parseLong(destParam.trim());
                req.setAttribute("preselectedDestinataireId", destId);
                notifDAO.marquerLuesFromExpediteur(etu.getId(), destId);
                Utilisateur otherUser = enseignants.stream().filter(e -> e.getId().equals(destId)).findFirst().orElse(null);
                if (otherUser == null) otherUser = utilisateurDAO.findById(destId);
                if (otherUser != null) {
                    req.setAttribute("otherUser", otherUser);
                    req.setAttribute("conversation", notifDAO.findConversation(etu.getId(), destId));
                }
            } catch (NumberFormatException ignored) {}
        }
        req.setAttribute("nbNotifs", notifDAO.countNonLues(etu.getId()));
        req.getRequestDispatcher("/WEB-INF/vues/etudiant/message.jsp").forward(req, resp);
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
        resp.sendRedirect(req.getContextPath() + "/etudiant/MessageServlet?destinataireId=" + id + "&sent=1");
    }

    private Etudiant getEtudiant(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ETUDIANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        return new EtudiantDAO().findById(u.getId());
    }
}
