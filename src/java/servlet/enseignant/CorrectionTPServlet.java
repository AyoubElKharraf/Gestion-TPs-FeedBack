package servlet.enseignant;

import dao.*;
import model.*;
import util.NotificationService;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.List;
import model.Module;

/**
 * Servlet de correction des TPs pour les Enseignants
 * Actions : list | detail | corriger | commenter
 */
@WebServlet("/enseignant/CorrectionTPServlet")
public class CorrectionTPServlet extends HttpServlet {

    private TravailPratiqueDAO tpDAO     = new TravailPratiqueDAO();
    private EnseignantDAO      ensDAO    = new EnseignantDAO();
    private CommentaireDAO     commDAO   = new CommentaireDAO();
    private NotificationDAO    notifDAO  = new NotificationDAO();
    private ModuleDAO          moduleDAO = new ModuleDAO();

    private Enseignant getEnseignantSession(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet"); return null;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet"); return null;
        }
        return ensDAO.findById(u.getId());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Enseignant enseignant = getEnseignantSession(req, resp);
        if (enseignant == null) return;

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {

            case "list": {
                List<TravailPratique> travaux = tpDAO.findByEnseignant(enseignant.getId());
                String filtreStatut = req.getParameter("statut");
                if (filtreStatut != null && !filtreStatut.isEmpty()) {
                    try {
                        TravailPratique.Statut s = TravailPratique.Statut.valueOf(filtreStatut);
                        TravailPratique.Statut finalS = s;
                        travaux.removeIf(t -> t.getStatut() != finalS);
                    } catch (IllegalArgumentException ignored) {}
                }
                String moduleIdParam = req.getParameter("moduleId");
                if (moduleIdParam != null && !moduleIdParam.isEmpty()) {
                    try {
                        Long mid = Long.parseLong(moduleIdParam);
                        Long finalMid = mid;
                        travaux.removeIf(t -> t.getModule() == null || !t.getModule().getId().equals(finalMid));
                    } catch (NumberFormatException ignored) {}
                }
                String dateMinParam = req.getParameter("dateMin");
                String dateMaxParam = req.getParameter("dateMax");
                if (dateMinParam != null && !dateMinParam.isEmpty()) {
                    try {
                        java.util.Date dateMin = new SimpleDateFormat("yyyy-MM-dd").parse(dateMinParam);
                        java.util.Date finalDateMin = dateMin;
                        travaux.removeIf(t -> t.getDateSoumission() == null || t.getDateSoumission().before(finalDateMin));
                    } catch (Exception ignored) {}
                }
                if (dateMaxParam != null && !dateMaxParam.isEmpty()) {
                    try {
                        java.util.Date dateMax = new SimpleDateFormat("yyyy-MM-dd").parse(dateMaxParam);
                        java.util.Calendar cal = java.util.Calendar.getInstance();
                        cal.setTime(dateMax);
                        cal.add(java.util.Calendar.DAY_OF_MONTH, 1);
                        java.util.Date endOfDay = cal.getTime();
                        travaux.removeIf(t -> t.getDateSoumission() == null || !t.getDateSoumission().before(endOfDay));
                    } catch (Exception ignored) {}
                }
                List<Module> modules = moduleDAO.findByEnseignant(enseignant.getId());
                req.setAttribute("travaux", travaux);
                req.setAttribute("modules", modules);
                req.setAttribute("filtreStatut", filtreStatut);
                req.setAttribute("filtreModuleId", moduleIdParam);
                req.setAttribute("filtreDateMin", dateMinParam);
                req.setAttribute("filtreDateMax", dateMaxParam);
                req.setAttribute("nbNotifs", notifDAO.countNonLues(enseignant.getId()));
                req.setAttribute("nbSoumis",
                    travaux.stream().filter(t -> t.getStatut() == TravailPratique.Statut.SOUMIS).count());
                req.setAttribute("activeSection", "tps");
                req.getRequestDispatcher("/WEB-INF/vues/enseignant/liste_tps.jsp").forward(req, resp);
                break;
            }

            case "detail": {
                Long id = Long.parseLong(req.getParameter("id"));
                TravailPratique tp = tpDAO.findById(id);
                if (tp == null || tp.getModule() == null || tp.getModule().getEnseignant() == null
                        || !tp.getModule().getEnseignant().getId().equals(enseignant.getId())) {
                    resp.sendRedirect(req.getContextPath() + "/enseignant/CorrectionTPServlet");
                    return;
                }
                req.setAttribute("tp", tp);
                req.setAttribute("commentaires", commDAO.findByTravail(id));
                req.setAttribute("nbNotifs", notifDAO.countNonLues(enseignant.getId()));
                req.getRequestDispatcher("/WEB-INF/vues/enseignant/tp_correction.jsp").forward(req, resp);
                break;
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Enseignant enseignant = getEnseignantSession(req, resp);
        if (enseignant == null) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String ctx = req.getContextPath();

        // ---- SOUMETTRE UNE CORRECTION (note + statut) ----
        if ("corriger".equals(action)) {
            Long travailId  = Long.parseLong(req.getParameter("travailId"));
            String noteStr  = req.getParameter("note");
            String feedback = req.getParameter("feedback");
            String statutStr = req.getParameter("statut");

            TravailPratique tp = tpDAO.findById(travailId);
            if (tp == null || tp.getModule() == null || tp.getModule().getEnseignant() == null
                    || !tp.getModule().getEnseignant().getId().equals(enseignant.getId())) {
                resp.sendRedirect(ctx + "/enseignant/CorrectionTPServlet"); return;
            }

            // Mettre à jour la note
            if (noteStr != null && !noteStr.trim().isEmpty()) {
                try {
                    double note = Double.parseDouble(noteStr.replace(",", "."));
                    if (note < 0) note = 0;
                    if (note > 20) note = 20;
                    tp.setNote(note);
                } catch (NumberFormatException ignored) {}
            }

            // Mettre à jour le statut
            if (statutStr != null && !statutStr.isEmpty()) {
                try {
                    tp.setStatut(TravailPratique.Statut.valueOf(statutStr));
                } catch (IllegalArgumentException ignored) {}
            } else {
                tp.setStatut(TravailPratique.Statut.CORRIGE);
            }

            tpDAO.update(tp);

            // Ajouter le feedback comme commentaire si fourni
            if (feedback != null && !feedback.trim().isEmpty()) {
                Commentaire comm = new Commentaire();
                comm.setContenu("📝 Feedback enseignant : " + feedback.trim());
                comm.setAuteur(enseignant);
                comm.setTravail(tp);
                commDAO.save(comm);
            }

            // Notifier l'étudiant
            NotificationService.tpCorrige(
                tp.getEtudiant(),
                tp.getModule() != null ? tp.getModule().getNom() : "TP",
                tp.getNote()
            );

            resp.sendRedirect(ctx + "/enseignant/CorrectionTPServlet?action=detail&id=" +
                travailId + "&corrected=1");

        // ---- AJOUTER UN COMMENTAIRE ----
        } else if ("commenter".equals(action)) {
            Long travailId = Long.parseLong(req.getParameter("travailId"));
            String contenu = req.getParameter("contenu");

            if (contenu != null && !contenu.trim().isEmpty()) {
                TravailPratique tp = tpDAO.findById(travailId);
                if (tp != null && tp.getModule() != null && tp.getModule().getEnseignant() != null
                        && tp.getModule().getEnseignant().getId().equals(enseignant.getId())) {
                    Commentaire comm = new Commentaire();
                    comm.setContenu(contenu.trim());
                    comm.setAuteur(enseignant);
                    comm.setTravail(tp);
                    commDAO.save(comm);

                    // Notifier l'étudiant
                    NotificationService.nouveauCommentaire(
                        tp.getEtudiant(),
                        enseignant.getNomComplet(),
                        tp.getModule() != null ? tp.getModule().getNom() : "TP"
                    );
                }
            }
            resp.sendRedirect(ctx + "/enseignant/CorrectionTPServlet?action=detail&id=" +
                travailId + "&commented=1");
        }
    }
}