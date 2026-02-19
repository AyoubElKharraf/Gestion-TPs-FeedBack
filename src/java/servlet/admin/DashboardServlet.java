package servlet.admin;

import dao.ModuleDAO;
import dao.EnseignantDAO;
import dao.NotificationDAO;
import model.Module;
import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Servlet du tableau de bord Admin
 */
@WebServlet("/admin/DashboardServlet")
public class DashboardServlet extends HttpServlet {

    private ModuleDAO moduleDAO = new ModuleDAO();
    private EnseignantDAO enseignantDAO = new EnseignantDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Vérification du rôle Admin
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u.getRole() != Utilisateur.Role.ADMIN) {
            switch (u.getRole()) {
                case ENSEIGNANT:
                    resp.sendRedirect(req.getContextPath() + "/enseignant/DashboardServlet");
                    break;
                case ETUDIANT:
                    resp.sendRedirect(req.getContextPath() + "/etudiant/DashboardServlet");
                    break;
                default:
                    resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            }
            return;
        }

        // Charger les données
        List<Module> modules = moduleDAO.findByFiliere("M2I");
        long nbNotifs = new NotificationDAO().countNonLues(u.getId());
        req.setAttribute("modules", modules);
        req.setAttribute("enseignants", enseignantDAO.findAll());
        req.setAttribute("nbNotifs", nbNotifs);
        req.setAttribute("activeSection", "accueil");

        req.getRequestDispatcher("/WEB-INF/vues/admin/dashboard.jsp").forward(req, resp);
    }
}