package servlet.admin;

import dao.EnseignantDAO;
import dao.ModuleDAO;
import dao.NotificationDAO;
import model.Enseignant;
import model.Utilisateur;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Servlet CRUD complet des Enseignants (Admin)
 */
@WebServlet("/admin/EnseignantServlet")
public class EnseignantServlet extends HttpServlet {

    private EnseignantDAO enseignantDAO = new EnseignantDAO();
    private ModuleDAO     moduleDAO     = new ModuleDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return false;
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
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAdmin(req, resp)) return;

        String action = req.getParameter("action");
        if (action == null) action = "list";
        String ctx = req.getContextPath();

        switch (action) {

            case "list": {
                String search = req.getParameter("search");
                List<Enseignant> enseignants;
                if (search != null && !search.trim().isEmpty()) {
                    enseignants = enseignantDAO.search(search.trim());
                    req.setAttribute("search", search.trim());
                } else {
                    enseignants = enseignantDAO.findAll();
                }
                Utilisateur u = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
                req.setAttribute("enseignants", enseignants);
                req.setAttribute("total", enseignantDAO.count());
                req.setAttribute("nbNotifs", u != null ? notificationDAO.countNonLues(u.getId()) : 0L);
                req.setAttribute("activeSection", "enseignants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/enseignants.jsp").forward(req, resp);
                break;
            }

            case "detail": {
                Long id = Long.parseLong(req.getParameter("id"));
                Enseignant e = enseignantDAO.findById(id);
                if (e == null) {
                    resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=list&notfound=1");
                    return;
                }
                req.setAttribute("enseignant", e);
                req.setAttribute("modules", moduleDAO.findByEnseignant(id));
                req.setAttribute("activeSection", "enseignants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/enseignant_detail.jsp").forward(req, resp);
                break;
            }

            case "form": {
                String idParam = req.getParameter("id");
                if (idParam != null && !idParam.isEmpty()) {
                    req.setAttribute("enseignant", enseignantDAO.findById(Long.parseLong(idParam)));
                }
                req.setAttribute("activeSection", "enseignants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/enseignant_form.jsp").forward(req, resp);
                break;
            }

            default:
                resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAdmin(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String ctx = req.getContextPath();

        if ("save".equals(action)) {
            String idParam    = req.getParameter("id");
            String nom        = req.getParameter("nom");
            String prenom     = req.getParameter("prenom");
            String email      = req.getParameter("email");
            String motDePasse = req.getParameter("motDePasse");
            String specialite = req.getParameter("specialite");

            boolean isEdit = (idParam != null && !idParam.isEmpty());

            // Validation
            StringBuilder erreur = new StringBuilder();
            if (nom == null || nom.trim().isEmpty())    erreur.append("Le nom est obligatoire. ");
            if (prenom == null || prenom.trim().isEmpty()) erreur.append("Le prénom est obligatoire. ");
            if (email == null || email.trim().isEmpty()) erreur.append("L'email est obligatoire. ");
            if (!isEdit && (motDePasse == null || motDePasse.trim().isEmpty()))
                erreur.append("Le mot de passe est obligatoire. ");

            if (email != null && !email.trim().isEmpty()) {
                Long excludeId = isEdit ? Long.parseLong(idParam) : null;
                if (enseignantDAO.emailExists(email.trim(), excludeId)) {
                    erreur.append("Cet email est déjà utilisé. ");
                }
            }

            if (erreur.length() > 0) {
                req.setAttribute("erreur", erreur.toString().trim());
                req.setAttribute("activeSection", "enseignants");
                if (isEdit) req.setAttribute("enseignant", enseignantDAO.findById(Long.parseLong(idParam)));
                req.getRequestDispatcher("/WEB-INF/vues/admin/enseignant_form.jsp").forward(req, resp);
                return;
            }

            Enseignant enseignant;
            if (isEdit) {
                enseignant = enseignantDAO.findById(Long.parseLong(idParam));
                if (enseignant == null) {
                    resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=list");
                    return;
                }
            } else {
                enseignant = new Enseignant();
                enseignant.setRole(Utilisateur.Role.ENSEIGNANT);
            }

            enseignant.setNom(nom.trim());
            enseignant.setPrenom(prenom.trim());
            enseignant.setEmail(email.trim());
            if (motDePasse != null && !motDePasse.trim().isEmpty()) {
                enseignant.setMotDePasse(motDePasse);
            }
            enseignant.setSpecialite(specialite != null ? specialite.trim() : "");

            if (isEdit) {
                enseignantDAO.update(enseignant);
                resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=detail&id=" + idParam + "&updated=1");
            } else {
                enseignantDAO.save(enseignant);
                resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=list&success=1");
            }

        } else if ("delete".equals(action)) {
            Long id = Long.parseLong(req.getParameter("id"));
            enseignantDAO.delete(id);
            resp.sendRedirect(ctx + "/admin/EnseignantServlet?action=list&deleted=1");
        }
    }
}