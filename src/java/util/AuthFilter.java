package util;

import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Filtre d'authentification étendu.
 * Protège les URLs /vues/*, /admin/*, /enseignant/*, /etudiant/*
 * avec vérification du rôle approprié.
 */
@WebFilter(urlPatterns = {"/vues/*", "/admin/*", "/enseignant/*", "/etudiant/*"})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);
        String path = request.getServletPath();

        Utilisateur user = (session != null) 
            ? (Utilisateur) session.getAttribute("utilisateur") 
            : null;

        if (user == null) {
            AppLogger.warn("AuthFilter", "Accès non authentifié à " + path);
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        if (!isAuthorized(user, path)) {
            AppLogger.warn("AuthFilter", "Accès non autorisé: " + user.getEmail() + " vers " + path);
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Accès non autorisé pour votre rôle.");
            return;
        }

        chain.doFilter(req, res);
    }

    /**
     * Vérifie si l'utilisateur a le rôle requis pour accéder au chemin.
     */
    private boolean isAuthorized(Utilisateur user, String path) {
        if (path == null) return true;
        
        Utilisateur.Role role = user.getRole();
        
        if (path.startsWith("/admin/") || path.contains("/admin/")) {
            return role == Utilisateur.Role.ADMIN;
        }
        if (path.startsWith("/enseignant/") || path.contains("/enseignant/")) {
            return role == Utilisateur.Role.ENSEIGNANT || role == Utilisateur.Role.ADMIN;
        }
        if (path.startsWith("/etudiant/") || path.contains("/etudiant/")) {
            return role == Utilisateur.Role.ETUDIANT || role == Utilisateur.Role.ADMIN;
        }
        
        return true;
    }

    @Override public void init(FilterConfig fc) {}
    @Override public void destroy() {}
}