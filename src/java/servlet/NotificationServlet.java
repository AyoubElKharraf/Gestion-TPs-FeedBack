package servlet;

import dao.NotificationDAO;
import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.util.List;
import model.Notification;

/**
 * Servlet de gestion des notifications (lecture, marquage)
 * Supporte aussi les appels AJAX pour le badge en temps réel
 */
@WebServlet("/NotificationServlet")
public class NotificationServlet extends HttpServlet {

    private NotificationDAO notifDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet"); return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {

            // AJAX : retourner le nombre de non-lues en JSON
            case "count": {
                long count = notifDAO.countNonLues(u.getId());
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                resp.getWriter().write("{\"count\":" + count + "}");
                break;
            }

            // AJAX : retourner les notifications récentes en JSON (avec replyUrl si on peut répondre)
            case "liste-json": {
                List<Notification> notifs = notifDAO.findByDestinataire(u.getId());
                String ctx = req.getContextPath();
                resp.setContentType("application/json;charset=UTF-8");
                PrintWriter out = resp.getWriter();
                out.print("[");
                for (int i = 0; i < notifs.size() && i < 10; i++) {
                    Notification n = notifs.get(i);
                    if (i > 0) out.print(",");
                    String replyUrl = null;
                    if (n.getExpediteur() != null) {
                        if (u.getRole() == Utilisateur.Role.ADMIN) {
                            replyUrl = ctx + "/admin/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                        } else if (u.getRole() == Utilisateur.Role.ETUDIANT && n.getExpediteur().getRole() == Utilisateur.Role.ENSEIGNANT) {
                            replyUrl = ctx + "/etudiant/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                        } else if (u.getRole() == Utilisateur.Role.ENSEIGNANT && (n.getExpediteur().getRole() == Utilisateur.Role.ETUDIANT || n.getExpediteur().getRole() == Utilisateur.Role.ADMIN)) {
                            replyUrl = ctx + "/enseignant/MessageServlet?destinataireId=" + n.getExpediteur().getId();
                        }
                    }
                    out.print("{");
                    out.print("\"id\":" + n.getId() + ",");
                    out.print("\"message\":\"" + escapeJson(n.getMessage()) + "\",");
                    out.print("\"lu\":" + n.isLu() + ",");
                    out.print("\"date\":\"" + n.getDateCreation() + "\"");
                    if (n.getExpediteur() != null) {
                        out.print(",\"expediteur\":\"" + escapeJson(n.getExpediteur().getNomComplet()) + "\"");
                    } else {
                        out.print(",\"expediteur\":null");
                    }
                    if (replyUrl != null) {
                        out.print(",\"replyUrl\":\"" + escapeJson(replyUrl) + "\"");
                    }
                    out.print("}");
                }
                out.print("]");
                break;
            }

            // Marquer une notification comme lue
            case "lire": {
                String idParam = req.getParameter("id");
                if (idParam != null) notifDAO.marquerLue(Long.parseLong(idParam));
                String redirect = req.getParameter("redirect");
                if (redirect != null) {
                    resp.sendRedirect(redirect);
                } else {
                    resp.sendRedirect(req.getContextPath() + "/NotificationServlet?action=list");
                }
                break;
            }

            // Marquer toutes comme lues
            case "tout-lire": {
                notifDAO.marquerToutesLues(u.getId());
                resp.sendRedirect(req.getContextPath() + "/NotificationServlet?action=list");
                break;
            }

            // Page complète des notifications
            default: {
                notifDAO.marquerToutesLues(u.getId()); // auto-lu à l'ouverture
                List<Notification> notifs = notifDAO.findByDestinataire(u.getId());
                req.setAttribute("notifications", notifs);
                req.getRequestDispatcher("/WEB-INF/vues/notifications.jsp").forward(req, resp);
            }
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "");
    }
}