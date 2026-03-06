package servlet.enseignant;

import dao.EnseignantDAO;
import dao.EtudiantDAO;
import dao.ModuleDAO;
import dao.RapportDAO;
import model.Enseignant;
import model.Etudiant;
import model.Module;
import model.Rapport;
import model.Utilisateur;
import util.AbsenceIntegrationService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * Enseignant : signale au système externe Gestion_AbsencesAlerts qu'un étudiant
 * n'a pas rendu son TP avant la date limite (absence enregistrée côté Gestion_AbsencesAlerts).
 * Paramètres : etudiantId, moduleId
 */
@WebServlet("/enseignant/SignalerAbsenceTpServlet")
public class SignalerAbsenceTpServlet extends HttpServlet {

    private final EnseignantDAO enseignantDAO = new EnseignantDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final ModuleDAO moduleDAO = new ModuleDAO();
    private final RapportDAO rapportDAO = new RapportDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }

        String etudiantIdStr = req.getParameter("etudiantId");
        String moduleIdStr = req.getParameter("moduleId");
        String ctx = req.getContextPath();

        if (etudiantIdStr == null || moduleIdStr == null || etudiantIdStr.isBlank() || moduleIdStr.isBlank()) {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?erreur=param");
            return;
        }

        Long etudiantId;
        Long moduleId;
        try {
            etudiantId = Long.parseLong(etudiantIdStr);
            moduleId = Long.parseLong(moduleIdStr);
        } catch (NumberFormatException e) {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?erreur=param");
            return;
        }

        Enseignant enseignant = enseignantDAO.findById(u.getId());
        if (enseignant == null) {
            resp.sendRedirect(ctx + "/LoginServlet");
            return;
        }

        Module module = moduleDAO.findById(moduleId);
        if (module == null || module.getEnseignant() == null || !module.getEnseignant().getId().equals(enseignant.getId())) {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?erreur=module");
            return;
        }

        Etudiant etudiant = etudiantDAO.findById(etudiantId);
        if (etudiant == null) {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?erreur=etudiant");
            return;
        }

        Rapport rapport = rapportDAO.findByModule(moduleId);
        String rapportTitre = rapport != null ? rapport.getTitre() : null;
        String moduleNom = module.getNom();
        String baseUrl = getServletContext().getInitParameter("absence.system.url");
        boolean ok = AbsenceIntegrationService.notifyNonRemisTp(
            etudiantId,
            moduleId,
            moduleNom,
            rapportTitre,
            etudiant.getEmail(),
            enseignant.getEmail(),
            baseUrl
        );

        if (ok) {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?signale=1");
        } else {
            resp.sendRedirect(ctx + "/enseignant/AbsenceServlet?signale=0");
        }
    }
}
