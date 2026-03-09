package servlet.enseignant;

import dao.EtudiantDAO;
import dao.NotificationDAO;
import dao.RapportDAO;
import dao.TravailPratiqueDAO;
import model.Etudiant;
import model.Module;
import model.NonRemisItem;
import model.Rapport;
import model.Utilisateur;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/enseignant/AbsenceServlet")
public class AbsenceServlet extends HttpServlet {

    private final NotificationDAO notifDAO = new NotificationDAO();
    private final RapportDAO rapportDAO = new RapportDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
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

        Long enseignantId = u.getId();
        List<NonRemisItem> nonRemisList = new ArrayList<>();
        List<Rapport> rapportsDepasses = rapportDAO.findRapportsWithDateLimitePassed();
        for (Rapport rapport : rapportsDepasses) {
            if (rapport.getModule() == null || rapport.getModule().getEnseignant() == null
                || !rapport.getModule().getEnseignant().getId().equals(enseignantId)) {
                continue;
            }
            Module module = rapport.getModule();
            String filiere = module.getFiliere() != null ? module.getFiliere() : "M2I";
            List<Etudiant> etudiants = etudiantDAO.findByFiliere(filiere);
            if (etudiants == null) continue;
            for (Etudiant etu : etudiants) {
                boolean aRendu = tpDAO.findByEtudiant(etu.getId()).stream()
                    .anyMatch(t -> t.getModule() != null && t.getModule().getId().equals(module.getId()));
                if (!aRendu) {
                    nonRemisList.add(new NonRemisItem(etu, module, rapport));
                }
            }
        }

        req.setAttribute("nbNotifs", notifDAO.countNonLues(u.getId()));
        req.setAttribute("activeSection", "absences");
        req.setAttribute("nonRemisList", nonRemisList);
        boolean signaleOk = "1".equals(req.getParameter("signale"));
        boolean signaleKo = "0".equals(req.getParameter("signale"));
        req.setAttribute("signale", signaleOk ? Boolean.TRUE : (signaleKo ? Boolean.FALSE : null));
        req.setAttribute("erreur", req.getParameter("erreur"));
        if (signaleKo) {
            String absenceUrl = getServletContext().getInitParameter("absence.system.url");
            req.setAttribute("absenceSystemUrl", absenceUrl != null ? absenceUrl : "(non configurée)");
        }
        req.getRequestDispatcher("/WEB-INF/vues/enseignant/absences.jsp").forward(req, resp);
    }
}

