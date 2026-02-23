package servlet.admin;

import dao.AbsenceReportDAO;
import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.TravailPratiqueDAO;
import dao.UtilisateurDAO;
import model.Enseignant;
import model.Etudiant;
import model.Notification;
import model.Utilisateur;
import util.AbsenceIntegrationService;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * Servlet CRUD complet des Étudiants (Admin)
 * Actions : list | detail | form | save | delete | search
 */
@WebServlet("/admin/EtudiantServlet")
public class EtudiantServlet extends HttpServlet {

    private EtudiantDAO etudiantDAO = new EtudiantDAO();
    private TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();
    private NotificationDAO notificationDAO = new NotificationDAO();
    private UtilisateurDAO utilisateurDAO = new UtilisateurDAO();

    // ---- Sécurité : vérification rôle Admin ----
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

            // ---- LISTE ----
            case "list": {
                String search = req.getParameter("search");
                List<Etudiant> etudiants;
                if (search != null && !search.trim().isEmpty()) {
                    etudiants = etudiantDAO.search(search.trim());
                    req.setAttribute("search", search.trim());
                } else {
                    etudiants = etudiantDAO.findAll();
                }
                Utilisateur u = (Utilisateur) req.getSession(false).getAttribute("utilisateur");
                req.setAttribute("etudiants", etudiants);
                req.setAttribute("total", etudiantDAO.count());
                req.setAttribute("etudiantsASupprimer", etudiantDAO.findFlaggedForDeletion());
                req.setAttribute("nbNotifs", u != null ? notificationDAO.countNonLues(u.getId()) : 0L);
                req.setAttribute("activeSection", "etudiants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/etudiants.jsp").forward(req, resp);
                break;
            }

            // ---- Signaler au système d'absences (étudiant avec 3+ déclarations) ----
            case "signaler-absence": {
                String idStr = req.getParameter("id");
                if (idStr == null || idStr.isEmpty()) {
                    resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
                    return;
                }
                Long id = Long.parseLong(idStr);
                Etudiant e = etudiantDAO.findById(id);
                if (e == null || !e.isASupprimer()) {
                    resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
                    return;
                }
                AbsenceIntegrationService.notifyDepassementAbsences(id);
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list&signale-absence=1");
                return;
            }

            // ---- DÉTAIL ----
            case "detail": {
                Long id = Long.parseLong(req.getParameter("id"));
                Etudiant e = etudiantDAO.findById(id);
                if (e == null) {
                    resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list&notfound=1");
                    return;
                }
                req.setAttribute("etudiant", e);
                req.setAttribute("activeSection", "etudiants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/etudiant_detail.jsp").forward(req, resp);
                break;
            }

            // ---- FORMULAIRE (ajout / édition) ----
            case "form": {
                String idParam = req.getParameter("id");
                if (idParam != null && !idParam.isEmpty()) {
                    Etudiant e = etudiantDAO.findById(Long.parseLong(idParam));
                    req.setAttribute("etudiant", e);
                }
                req.setAttribute("activeSection", "etudiants");
                req.getRequestDispatcher("/WEB-INF/vues/admin/etudiant_form.jsp").forward(req, resp);
                break;
            }

            default:
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAdmin(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String ctx = req.getContextPath();

        // ---- SAVE (ajout / modification) ----
        if ("save".equals(action)) {
            String idParam    = req.getParameter("id");
            String nom        = req.getParameter("nom");
            String prenom     = req.getParameter("prenom");
            String email      = req.getParameter("email");
            String motDePasse = req.getParameter("motDePasse");
            String filiere    = req.getParameter("filiere");
            String numero     = req.getParameter("numeroEtudiant");

            boolean isEdit = (idParam != null && !idParam.isEmpty());

            // --- Validation ---
            StringBuilder erreur = new StringBuilder();
            if (nom == null || nom.trim().isEmpty())    erreur.append("Le nom est obligatoire. ");
            if (prenom == null || prenom.trim().isEmpty()) erreur.append("Le prénom est obligatoire. ");
            if (email == null || email.trim().isEmpty()) erreur.append("L'email est obligatoire. ");
            if (!isEdit && (motDePasse == null || motDePasse.trim().isEmpty()))
                erreur.append("Le mot de passe est obligatoire. ");

            // Vérifier unicité email
            if (email != null && !email.trim().isEmpty()) {
                Long excludeId = isEdit ? Long.parseLong(idParam) : null;
                if (etudiantDAO.emailExists(email.trim(), excludeId)) {
                    erreur.append("Cet email est déjà utilisé. ");
                }
            }

            if (erreur.length() > 0) {
                req.setAttribute("erreur", erreur.toString().trim());
                req.setAttribute("activeSection", "etudiants");
                // Remettre les valeurs saisies
                req.setAttribute("formNom", nom);
                req.setAttribute("formPrenom", prenom);
                req.setAttribute("formEmail", email);
                req.setAttribute("formFiliere", filiere);
                req.setAttribute("formNumero", numero);
                if (isEdit) req.setAttribute("etudiant", etudiantDAO.findById(Long.parseLong(idParam)));
                req.getRequestDispatcher("/WEB-INF/vues/admin/etudiant_form.jsp").forward(req, resp);
                return;
            }

            Etudiant etudiant;
            if (isEdit) {
                etudiant = etudiantDAO.findById(Long.parseLong(idParam));
                if (etudiant == null) {
                    resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
                    return;
                }
            } else {
                etudiant = new Etudiant();
                etudiant.setRole(Utilisateur.Role.ETUDIANT);
            }

            etudiant.setNom(nom.trim());
            etudiant.setPrenom(prenom.trim());
            etudiant.setEmail(email.trim());
            if (motDePasse != null && !motDePasse.trim().isEmpty()) {
                etudiant.setMotDePasse(util.PasswordUtil.hash(motDePasse));
            }
            etudiant.setFiliere(filiere != null ? filiere.trim() : "M2I");
            etudiant.setNumeroEtudiant(numero != null ? numero.trim() : "");

            if (isEdit) {
                etudiantDAO.update(etudiant);
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=detail&id=" + idParam + "&updated=1");
            } else {
                etudiantDAO.save(etudiant);
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list&success=1");
            }

        // ---- DELETE ----
        } else if ("delete".equals(action)) {
            String idStr = req.getParameter("id");
            if (idStr == null || idStr.trim().isEmpty()) {
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
                return;
            }
            try {
                Long id = Long.parseLong(idStr.trim());
                Etudiant etudiant = etudiantDAO.findById(id);
                if (etudiant == null) {
                    resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list&notfound=1");
                    return;
                }
                String nomComplet = etudiant.getNomComplet();
                String email = etudiant.getEmail();

                // Notifier les enseignants qui ont eu des TPs de cet étudiant (avant toute suppression)
                List<Enseignant> enseignants = tpDAO.findEnseignantsByEtudiant(id);
                String message = "L'étudiant " + nomComplet + " (" + email + ") a été supprimé de la plateforme (dépassement d'absences). L'accès avec cet email est désactivé.";
                for (Enseignant ens : enseignants) {
                    if (ens != null) {
                        Notification notif = new Notification();
                        notif.setMessage(message);
                        notif.setDestinataire(ens);
                        notificationDAO.save(notif);
                    }
                }

                // Supprimer les TPs de l'étudiant (retire l'étudiant des données enseignant), puis l'étudiant puis l'utilisateur (bloque l'accès avec cet email)
                tpDAO.deleteByEtudiant(id);
                etudiantDAO.delete(id);
                utilisateurDAO.delete(id);

                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list&deleted=1");
            } catch (NumberFormatException e) {
                resp.sendRedirect(ctx + "/admin/EtudiantServlet?action=list");
            }
        }
    }
}