package util;

import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Filtre d'authentification - protège toutes les pages /vues/*
 */
@WebFilter("/vues/*")
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);

        boolean loggedIn = (session != null && session.getAttribute("utilisateur") != null);

        if (!loggedIn) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
        } else {
            chain.doFilter(req, res);
        }
    }

    @Override public void init(FilterConfig fc) {}
    @Override public void destroy() {}
}