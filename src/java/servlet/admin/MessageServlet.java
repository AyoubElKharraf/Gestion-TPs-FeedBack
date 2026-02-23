package servlet.admin;

import dao.EnseignantDAO;
import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.UtilisateurDAO;
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
import model.Etudiant;
import model.Enseignant;

/**
 * Admin : envoyer un message (commentaire) à un Enseignant ou un Etudiant.
 */
@WebServlet("/admin/MessageServlet")
public class MessageServlet extends HttpServlet {

    private final EnseignantDAO enseignantDAO = new EnseignantDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final UtilisateurDAO utilisateurDAO = new UtilisateurDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur admin = (Utilisateur) session.getAttribute("utilisateur");
        if (admin == null || admin.getRole() != Utilisateur.Role.ADMIN) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        List<Enseignant> enseignants = enseignantDAO.findAll();
        List<Etudiant> etudiants = etudiantDAO.findAll();
        req.setAttribute("enseignants", enseignants);
        req.setAttribute("etudiants", etudiants);
        Map<Long, java.util.Date> lastMessageDateMap = new HashMap<>();
        Map<Long, Long> unreadCountMap = new HashMap<>();
        for (Enseignant e : enseignants) {
            lastMessageDateMap.put(e.getId(), notifDAO.getLastMessageDate(admin.getId(), e.getId()));
            unreadCountMap.put(e.getId(), notifDAO.countUnreadFrom(admin.getId(), e.getId()));
        }
        for (Etudiant e : etudiants) {
            lastMessageDateMap.put(e.getId(), notifDAO.getLastMessageDate(admin.getId(), e.getId()));
            unreadCountMap.put(e.getId(), notifDAO.countUnreadFrom(admin.getId(), e.getId()));
        }
        req.setAttribute("lastMessageDateMap", lastMessageDateMap);
        req.setAttribute("unreadCountMap", unreadCountMap);
        String destParam = req.getParameter("destinataireId");
        if (destParam != null && !destParam.isEmpty()) {
            try {
                Long destId = Long.parseLong(destParam.trim());
                req.setAttribute("preselectedDestinataireId", destId);
                notifDAO.marquerLuesFromExpediteur(admin.getId(), destId);
                Utilisateur otherUser = utilisateurDAO.findById(destId);
                if (otherUser != null) {
                    req.setAttribute("otherUser", otherUser);
                    req.setAttribute("conversation", notifDAO.findConversation(admin.getId(), destId));
                }
            } catch (NumberFormatException ignored) {}
        }
        req.setAttribute("nbNotifs", notifDAO.countNonLues(admin.getId()));
        req.setAttribute("activeSection", "messages");
        req.getRequestDispatcher("/WEB-INF/vues/admin/messages.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur admin = (Utilisateur) session.getAttribute("utilisateur");
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
        resp.sendRedirect(req.getContextPath() + "/admin/MessageServlet?destinataireId=" + id + "&sent=1");
    }
}
