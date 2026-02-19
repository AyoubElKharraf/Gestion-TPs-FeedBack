package servlet;

import dao.UtilisateurDAO;
import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Servlet de gestion du Login - vérifie les credentials et redirige selon le rôle
 */
@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Afficher la page de login
        req.getRequestDispatcher("/WEB-INF/vues/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String email = req.getParameter("email");
        String motDePasse = req.getParameter("motDePasse");

        // Validation côté serveur
        if (email == null || email.trim().isEmpty()
                || motDePasse == null || motDePasse.trim().isEmpty()) {
            req.setAttribute("erreur", "Veuillez remplir tous les champs.");
            req.getRequestDispatcher("/WEB-INF/vues/login.jsp").forward(req, resp);
            return;
        }

        Utilisateur utilisateur = utilisateurDAO.authenticate(email.trim(), motDePasse);

        if (utilisateur == null) {
            req.setAttribute("erreur", "Email ou mot de passe incorrect.");
            req.getRequestDispatcher("/WEB-INF/vues/login.jsp").forward(req, resp);
            return;
        }

        // Stocker l'utilisateur en session
        HttpSession session = req.getSession(true);
        session.setAttribute("utilisateur", utilisateur);
        session.setAttribute("role", utilisateur.getRole().name());

        // Redirection selon le rôle
        String ctx = req.getContextPath();
        switch (utilisateur.getRole()) {
            case ADMIN:
                resp.sendRedirect(ctx + "/admin/DashboardServlet");
                break;
            case ENSEIGNANT:
                resp.sendRedirect(ctx + "/enseignant/DashboardServlet");
                break;
            case ETUDIANT:
                resp.sendRedirect(ctx + "/etudiant/DashboardServlet");
                break;
            default:
                resp.sendRedirect(ctx + "/LoginServlet");
        }
    }
}