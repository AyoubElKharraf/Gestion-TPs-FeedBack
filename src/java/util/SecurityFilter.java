package util;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Filtre de sécurité HTTP.
 * Ajoute des en-têtes de sécurité pour protéger contre les attaques courantes:
 * - XSS (X-XSS-Protection, Content-Security-Policy)
 * - Clickjacking (X-Frame-Options)
 * - MIME sniffing (X-Content-Type-Options)
 */
@WebFilter("/*")
public class SecurityFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        // Protection contre le clickjacking - empêche l'embedding dans des iframes
        httpResponse.setHeader("X-Frame-Options", "SAMEORIGIN");
        
        // Protection contre le MIME sniffing
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");
        
        // Protection XSS du navigateur (ancienne, mais toujours utile)
        httpResponse.setHeader("X-XSS-Protection", "1; mode=block");
        
        // Politique de sécurité du contenu (CSP) - permet scripts inline pour Tailwind CDN
        httpResponse.setHeader("Content-Security-Policy", 
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com; " +
            "style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; " +
            "img-src 'self' data:; " +
            "font-src 'self'; " +
            "connect-src 'self'; " +
            "frame-ancestors 'self';"
        );
        
        // Empêche la mise en cache des pages sensibles
        httpResponse.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        httpResponse.setHeader("Pragma", "no-cache");
        
        // Referrer policy
        httpResponse.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
