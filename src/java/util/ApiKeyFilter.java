package util;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Filtre de sécurité pour les API REST.
 * Vérifie la présence et la validité d'une clé API.
 * 
 * Authentification via :
 * - Header HTTP : X-API-Key: <clé>
 * - Paramètre URL : ?apiKey=<clé>
 * 
 * Configuration dans web.xml :
 * - api.key : clé(s) API valide(s), séparées par virgule
 * - api.key.enabled : true/false pour activer/désactiver
 * - api.allowed.ips : liste d'IPs autorisées (optionnel)
 */
@WebFilter("/api/*")
public class ApiKeyFilter implements Filter {

    private static final String HEADER_API_KEY = "X-API-Key";
    private static final String PARAM_API_KEY = "apiKey";
    
    private Set<String> validApiKeys = new HashSet<>();
    private Set<String> allowedIps = new HashSet<>();
    private boolean enabled = true;
    private boolean ipWhitelistEnabled = false;

    @Override
    public void init(FilterConfig config) throws ServletException {
        ServletContext ctx = config.getServletContext();
        
        String enabledParam = ctx.getInitParameter("api.key.enabled");
        if (enabledParam != null) {
            enabled = Boolean.parseBoolean(enabledParam);
        }
        
        String apiKeys = ctx.getInitParameter("api.key");
        if (apiKeys != null && !apiKeys.isBlank()) {
            for (String key : apiKeys.split(",")) {
                String trimmed = key.trim();
                if (!trimmed.isEmpty()) {
                    validApiKeys.add(trimmed);
                }
            }
        }
        
        String allowedIpsParam = ctx.getInitParameter("api.allowed.ips");
        if (allowedIpsParam != null && !allowedIpsParam.isBlank()) {
            ipWhitelistEnabled = true;
            for (String ip : allowedIpsParam.split(",")) {
                String trimmed = ip.trim();
                if (!trimmed.isEmpty()) {
                    allowedIps.add(trimmed);
                }
            }
        }
        
        if (validApiKeys.isEmpty() && enabled) {
            validApiKeys.add("EtudAcadPro-API-2025-SecretKey");
            AppLogger.warn("ApiKeyFilter", "Aucune clé API configurée, utilisation de la clé par défaut");
        }
        
        AppLogger.info("ApiKeyFilter", "Initialisé [enabled=" + enabled + 
            ", keys=" + validApiKeys.size() + 
            ", ipWhitelist=" + ipWhitelistEnabled + "]");
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            chain.doFilter(req, res);
            return;
        }
        
        if (!enabled) {
            chain.doFilter(req, res);
            return;
        }
        
        String clientIp = getClientIp(request);
        
        if (ipWhitelistEnabled && !allowedIps.isEmpty()) {
            if (isIpAllowed(clientIp)) {
                AppLogger.debug("ApiKeyFilter", "IP autorisée: " + clientIp);
                chain.doFilter(req, res);
                return;
            }
        }
        
        String apiKey = request.getHeader(HEADER_API_KEY);
        if (apiKey == null || apiKey.isBlank()) {
            apiKey = request.getParameter(PARAM_API_KEY);
        }
        
        if (apiKey == null || apiKey.isBlank()) {
            AppLogger.logSecurity("API_ACCESS_DENIED", "Clé API manquante [ip=" + clientIp + 
                ", path=" + request.getServletPath() + "]");
            sendUnauthorized(response, "Clé API requise (header X-API-Key ou paramètre apiKey)");
            return;
        }
        
        if (!validApiKeys.contains(apiKey)) {
            AppLogger.logSecurity("API_INVALID_KEY", "Clé API invalide [ip=" + clientIp + 
                ", path=" + request.getServletPath() + "]");
            sendUnauthorized(response, "Clé API invalide");
            return;
        }
        
        AppLogger.debug("ApiKeyFilter", "Accès API autorisé [ip=" + clientIp + 
            ", path=" + request.getServletPath() + "]");
        
        chain.doFilter(req, res);
    }

    private boolean isIpAllowed(String clientIp) {
        if (clientIp == null) return false;
        
        if (allowedIps.contains(clientIp)) return true;
        if (allowedIps.contains("127.0.0.1") && 
            (clientIp.equals("localhost") || clientIp.equals("0:0:0:0:0:0:0:1"))) {
            return true;
        }
        
        return false;
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }

    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        
        PrintWriter out = response.getWriter();
        out.print("{\"success\":false,\"error\":\"" + escapeJson(message) + "\",\"code\":401}");
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    @Override
    public void destroy() {
        AppLogger.info("ApiKeyFilter", "Filtre API détruit");
    }
}
