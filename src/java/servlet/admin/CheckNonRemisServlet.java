package servlet.admin;

import model.Utilisateur;
import util.NonRemisCheckService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Admin : déclenche la vérification des TPs non rendus (date limite dépassée)
 * et envoie les alertes au système d'absences.
 */
@WebServlet("/admin/CheckNonRemisServlet")
public class CheckNonRemisServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ADMIN) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        NonRemisCheckService.checkAndNotifyNonRemis();
        resp.sendRedirect(req.getContextPath() + "/admin/ModuleServlet?action=list&nonRemisChecked=1");
    }
}
