package servlet.enseignant;

import dao.EnseignantDAO;
import dao.NotificationDAO;
import dao.RapportDAO;
import dao.TravailPratiqueDAO;
import model.Enseignant;
import model.FeedItem;
import model.Rapport;
import model.TravailPratique;
import model.Utilisateur;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Tableau de bord Enseignant (accueil après connexion).
 */
@WebServlet("/enseignant/DashboardServlet")
public class DashboardServlet extends HttpServlet {

    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();
    private final RapportDAO rapportDAO = new RapportDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        Enseignant ens = new EnseignantDAO().findById(u.getId());
        if (ens == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return;
        }
        List<TravailPratique> travaux = tpDAO.findByEnseignant(ens.getId());
        long nbSoumis = travaux.stream().filter(t -> t.getStatut() == TravailPratique.Statut.SOUMIS).count();
        long nbNotifs = notifDAO.countNonLues(ens.getId());

        List<FeedItem> feedItems = new ArrayList<>();
        String ctx = req.getContextPath();
        for (Rapport r : rapportDAO.findByEnseignantWithModule(ens.getId())) {
            String moduleNom = r.getModule() != null ? r.getModule().getNom() : "";
            feedItems.add(new FeedItem(FeedItem.Type.RAPPORT, r.getDateCreation(), r.getTitre(),
                "Support de cours • " + moduleNom, "Vous",
                ctx + "/enseignant/RapportServlet", "Voir", r.getId()));
        }
        for (TravailPratique t : travaux) {
            String etu = t.getEtudiant() != null ? t.getEtudiant().getNomComplet() : "Étudiant";
            String mod = t.getModule() != null ? t.getModule().getNom() : "";
            feedItems.add(new FeedItem(FeedItem.Type.TP, t.getDateSoumission(), t.getTitre(),
                etu + " • " + mod, etu,
                ctx + "/enseignant/CorrectionTPServlet?action=detail&id=" + t.getId(), "Corriger", t.getId()));
        }
        feedItems.sort(Comparator.comparing(FeedItem::getDate).reversed());

        req.setAttribute("travaux", travaux);
        req.setAttribute("nbSoumis", nbSoumis);
        req.setAttribute("nbNotifs", nbNotifs);
        req.setAttribute("feedItems", feedItems);
        req.setAttribute("activeSection", "dashboard");
        req.getRequestDispatcher("/WEB-INF/vues/enseignant/dashboard.jsp").forward(req, resp);
    }
}
