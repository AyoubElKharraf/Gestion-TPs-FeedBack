package servlet.enseignant;

import dao.NotificationDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import model.Notification;
import model.Utilisateur;

@WebServlet("/enseignant/CommentaireServlet")
public class CommentaireServlet extends HttpServlet {

    private final NotificationDAO notifDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        List<Notification> notifications = notifDAO.findByDestinataire(u.getId());
        req.setAttribute("notificationsRecues", notifications);
        req.setAttribute("nbNotifs", notifDAO.countNonLues(u.getId()));
        req.setAttribute("activeSection", "commentaires");
        req.getRequestDispatcher("/WEB-INF/vues/enseignant/commentaires.jsp").forward(req, resp);
    }
}

