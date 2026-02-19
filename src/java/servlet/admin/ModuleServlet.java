package servlet.admin;

import dao.ModuleDAO;
import dao.EnseignantDAO;
import dao.NotificationDAO;
import model.Module;
import model.Utilisateur;
import model.Enseignant;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Servlet CRUD des Modules (Admin)
 */
@WebServlet("/admin/ModuleServlet")
public class ModuleServlet extends HttpServlet {

    private ModuleDAO moduleDAO = new ModuleDAO();
    private EnseignantDAO enseignantDAO = new EnseignantDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();

    private boolean isAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
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
                Utilisateur u = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
                List<Module> modules = moduleDAO.findByFiliere("M2I");
                req.setAttribute("modules", modules);
                req.setAttribute("enseignants", enseignantDAO.findAll());
                req.setAttribute("nbNotifs", u != null ? notificationDAO.countNonLues(u.getId()) : 0L);
                req.setAttribute("activeSection", "modules");
                req.getRequestDispatcher("/WEB-INF/vues/admin/modules.jsp").forward(req, resp);
                break;
            }

            case "detail": {
                String idStr = req.getParameter("id");
                if (idStr == null || idStr.trim().isEmpty()) {
                    resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list");
                    return;
                }
                try {
                    Long id = Long.parseLong(idStr.trim());
                    Module m = moduleDAO.findById(id);
                    if (m == null) {
                        resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list&notfound=1");
                        return;
                    }
                    req.setAttribute("module", m);
                    req.setAttribute("enseignants", enseignantDAO.findAll());
                    req.setAttribute("activeSection", "modules");
                    req.getRequestDispatcher("/WEB-INF/vues/admin/module_detail.jsp").forward(req, resp);
                } catch (NumberFormatException e) {
                    resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list");
                }
                break;
            }

            case "form":
                req.setAttribute("enseignants", enseignantDAO.findAll());
                req.setAttribute("activeSection", "modules");
                String idParam = req.getParameter("id");
                if (idParam != null && !idParam.trim().isEmpty()) {
                    try {
                        Module existing = moduleDAO.findById(Long.parseLong(idParam.trim()));
                        req.setAttribute("module", existing);
                    } catch (NumberFormatException ignored) {
                        // id invalide : on reste en mode création
                    }
                }
                req.getRequestDispatcher("/WEB-INF/vues/admin/module_form.jsp").forward(req, resp);
                break;

            default:
                resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list");
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
            String idParam = req.getParameter("id");
            String nom = req.getParameter("nom");
            String description = req.getParameter("description");
            String filiere = req.getParameter("filiere");
            String enseignantIdParam = req.getParameter("enseignantId");

            // Validation
            if (nom == null || nom.trim().isEmpty()) {
                req.setAttribute("erreur", "Le nom du module est obligatoire.");
                req.setAttribute("enseignants", enseignantDAO.findAll());
                if (idParam != null && !idParam.trim().isEmpty()) {
                    try {
                        req.setAttribute("module", moduleDAO.findById(Long.parseLong(idParam.trim())));
                    } catch (NumberFormatException ignored) { }
                }
                req.getRequestDispatcher("/WEB-INF/vues/admin/module_form.jsp").forward(req, resp);
                return;
            }

            Module module;
            boolean isEdit = false;
            if (idParam != null && !idParam.trim().isEmpty()) {
                try {
                    Long id = Long.parseLong(idParam.trim());
                    module = moduleDAO.findById(id);
                    if (module != null) isEdit = true;
                    else module = new Module();
                } catch (NumberFormatException e) {
                    module = new Module();
                }
            } else {
                module = new Module();
            }

            module.setNom(nom.trim());
            // En édition : ne pas écraser la description si non fournie (ex. formulaire détail sans champ description)
            if (isEdit) {
                if (description != null && !description.trim().isEmpty())
                    module.setDescription(description.trim());
            } else {
                module.setDescription(description != null ? description.trim() : null);
            }
            module.setFiliere(filiere != null && !filiere.trim().isEmpty() ? filiere.trim() : "M2I");

            if (enseignantIdParam != null && !enseignantIdParam.trim().isEmpty()) {
                try {
                    Enseignant ens = enseignantDAO.findById(Long.parseLong(enseignantIdParam.trim()));
                    module.setEnseignant(ens);
                } catch (NumberFormatException ignored) {
                    module.setEnseignant(null);
                }
            } else {
                module.setEnseignant(null);
            }

            if (isEdit) {
                moduleDAO.update(module);
            } else {
                moduleDAO.save(module);
            }

            resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list&success=1");

        } else if ("delete".equals(action)) {
            String idStr = req.getParameter("id");
            boolean deleted = false;
            if (idStr != null && !idStr.trim().isEmpty()) {
                try {
                    Long id = Long.parseLong(idStr.trim());
                    moduleDAO.delete(id);
                    deleted = true;
                } catch (NumberFormatException ignored) {
                    // id invalide : on redirige sans supprimer
                }
            }
            resp.sendRedirect(ctx + "/admin/ModuleServlet?action=list" + (deleted ? "&deleted=1" : ""));
        }
    }
}