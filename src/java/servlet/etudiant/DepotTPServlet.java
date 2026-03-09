package servlet.etudiant;

import dao.*;
import model.*;
import util.FileUploadUtil;
import util.NotificationService;
import jakarta.servlet.*;
import jakarta.servlet.annotation.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import model.Module;          // ← IMPORT EXPLICITE – résout le conflit avec java.lang.Module


/**
 * Servlet de dépôt de TPs pour les Étudiants
 * Actions : list | form | save | detail | supprimer
 */
@WebServlet("/etudiant/DepotTPServlet")
@MultipartConfig(
    maxFileSize    = 10 * 1024 * 1024,  // 10 Mo par fichier
    maxRequestSize = 15 * 1024 * 1024   // 15 Mo par requête
)
public class DepotTPServlet extends HttpServlet {

    private TravailPratiqueDAO tpDAO      = new TravailPratiqueDAO();
    private ModuleDAO          moduleDAO  = new ModuleDAO();
    private RapportDAO         rapportDAO = new RapportDAO();
    private EtudiantDAO        etudiantDAO = new EtudiantDAO();
    private NotificationDAO    notifDAO   = new NotificationDAO();

    private Etudiant getEtudiantSession(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("utilisateur") == null) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet"); return null;
        }
        Utilisateur u = (Utilisateur) session.getAttribute("utilisateur");
        if (u.getRole() != Utilisateur.Role.ETUDIANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet"); return null;
        }
        // Charger l'entité Etudiant complète
        return etudiantDAO.findById(u.getId());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Etudiant etudiant = getEtudiantSession(req, resp);
        if (etudiant == null) return;

        String action = req.getParameter("action");
        if (action == null) action = "list";
        String ctx = req.getContextPath();

        switch (action) {

            case "list": {
                String sectionParam = req.getParameter("section");
                if (sectionParam == null || sectionParam.isEmpty()) sectionParam = "modules";
                if (!sectionParam.equals("modules") && !sectionParam.equals("devoirs") && !sectionParam.equals("feedback")) {
                    sectionParam = "modules";
                }
                List<TravailPratique> travaux = tpDAO.findByEtudiant(etudiant.getId());
                String moduleIdParam = req.getParameter("moduleId");
                Long moduleFiltreId = null;
                if (moduleIdParam != null && !moduleIdParam.isEmpty()) {
                    try {
                        moduleFiltreId = Long.parseLong(moduleIdParam);
                        Long finalModuleId = moduleFiltreId;
                        travaux.removeIf(t -> t.getModule() == null || !t.getModule().getId().equals(finalModuleId));
                    } catch (NumberFormatException ignored) {}
                }
                String statutParam = req.getParameter("statut");
                if (statutParam != null && !statutParam.isEmpty()) {
                    try {
                        TravailPratique.Statut s = TravailPratique.Statut.valueOf(statutParam);
                        TravailPratique.Statut finalS = s;
                        travaux.removeIf(t -> t.getStatut() != finalS);
                    } catch (IllegalArgumentException ignored) {}
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
                List<Module> modules = moduleDAO.findByFiliere(
                    etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I"
                );
                java.util.List<Long> moduleIds = new java.util.ArrayList<>();
                for (Module m : modules) moduleIds.add(m.getId());
                List<model.Rapport> rapports = rapportDAO.findByModuleIds(moduleIds);
                req.setAttribute("travaux", travaux);
                req.setAttribute("modules", modules);
                req.setAttribute("rapports", rapports);
                req.setAttribute("moduleFiltreId", moduleFiltreId);
                req.setAttribute("filtreStatut", statutParam);
                req.setAttribute("filtreDateMin", dateMinParam);
                req.setAttribute("filtreDateMax", dateMaxParam);
                req.setAttribute("section", sectionParam);
                req.setAttribute("nbNotifs", notifDAO.countNonLues(etudiant.getId()));
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/mes_tps.jsp").forward(req, resp);
                break;
            }

            case "form": {
                List<Module> modules = moduleDAO.findByFiliere(
                    etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I"
                );
                java.util.List<Long> moduleIds = new java.util.ArrayList<>();
                for (Module m : modules) moduleIds.add(m.getId());
                java.util.List<model.Rapport> rapports = rapportDAO.findByModuleIds(moduleIds);
                req.setAttribute("modules", modules);
                req.setAttribute("rapports", rapports);
                String moduleIdParam = req.getParameter("moduleId");
                if (moduleIdParam != null && !moduleIdParam.isEmpty()) {
                    try { req.setAttribute("preselectedModuleId", Long.parseLong(moduleIdParam)); } catch (NumberFormatException ignored) {}
                }
                String rapportIdParam = req.getParameter("rapportId");
                Long moduleIdPourLimite = null;
                if (rapportIdParam != null && !rapportIdParam.isEmpty()) {
                    try {
                        Long rid = Long.parseLong(rapportIdParam);
                        model.Rapport r = rapportDAO.findByIdWithModule(rid);
                        if (r != null && r.getModule() != null) {
                            java.util.List<Long> mids = new java.util.ArrayList<>();
                            for (Module m : modules) mids.add(m.getId());
                            if (mids.contains(r.getModule().getId())) {
                                if (r.getDateLimite() != null && r.getDateLimite().before(new Date())) {
                                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=devoirs&deadlineDepasse=1");
                                    return;
                                }
                                req.setAttribute("preselectedModuleId", r.getModule().getId());
                                req.setAttribute("preselectedRapportTitre", r.getTitre());
                                req.setAttribute("preselectedRapportId", r.getId());
                                moduleIdPourLimite = r.getModule().getId();
                            }
                        }
                    } catch (NumberFormatException ignored) {}
                }
                if (moduleIdPourLimite == null && moduleIdParam != null && !moduleIdParam.isEmpty()) {
                    try {
                        Long mid = Long.parseLong(moduleIdParam);
                        java.util.Date dateLimiteModule = rapportDAO.getMaxDateLimiteForModule(mid);
                        if (dateLimiteModule != null && new Date().after(dateLimiteModule)) {
                            resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=devoirs&deadlineDepasse=1");
                            return;
                        }
                    } catch (NumberFormatException ignored) {}
                }
                // Si id présent = nouvelle version d'un TP existant (autorisée seulement avant date limite)
                String idParam = req.getParameter("id");
                if (idParam != null && !idParam.isEmpty()) {
                    Long tpId = null;
                    try { tpId = Long.parseLong(idParam); } catch (NumberFormatException ignored) {}
                    if (tpId != null) {
                        TravailPratique tp = tpDAO.findById(tpId);
                        if (tp == null || tp.getEtudiant() == null || !tp.getEtudiant().getId().equals(etudiant.getId())) {
                            resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&forbidden=1");
                            return;
                        }
                        java.util.Date dateLimiteModule = tp.getModule() != null ? rapportDAO.getMaxDateLimiteForModule(tp.getModule().getId()) : null;
                        if (dateLimiteModule != null && new Date().after(dateLimiteModule)) {
                            resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&deadlineDepasse=1");
                            return;
                        }
                        req.setAttribute("tpParent", tp);
                    }
                }
                req.setAttribute("nbNotifs", notifDAO.countNonLues(etudiant.getId()));
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/depot_form.jsp").forward(req, resp);
                break;
            }

            case "voir-devoir": {
                String rapportIdParam = req.getParameter("rapportId");
                if (rapportIdParam == null) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list");
                    return;
                }
                model.Rapport rapport = rapportDAO.findByIdWithModule(Long.parseLong(rapportIdParam));
                if (rapport == null || rapport.getModule() == null) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&notfound=1");
                    return;
                }
                model.Module module = rapport.getModule();
                String filiereEtudiant = etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I";
                if (module.getFiliere() != null && !module.getFiliere().equals(filiereEtudiant)) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&forbidden=1");
                    return;
                }
                java.util.List<TravailPratique> mesTps = tpDAO.findByEtudiant(etudiant.getId());
                TravailPratique tpPourModule = null;
                String rapportTitre = rapport.getTitre() != null ? rapport.getTitre().trim() : null;
                for (TravailPratique t : mesTps) {
                    if (t.getModule() == null || !t.getModule().getId().equals(module.getId()))
                        continue;
                    String tpTitre = t.getTitre() != null ? t.getTitre().trim() : null;
                    if (rapportTitre != null && tpTitre != null) {
                        if (rapportTitre.equalsIgnoreCase(tpTitre)) {
                            tpPourModule = t;
                            break;
                        }
                        String normR = rapportTitre.toLowerCase().replace(" ", "_");
                        String normT = tpTitre.toLowerCase().replace(" ", "_");
                        if (normR.equals(normT)) {
                            tpPourModule = t;
                            break;
                        }
                    }
                }
                req.setAttribute("rapport", rapport);
                req.setAttribute("module", module);
                req.setAttribute("tpPourModule", tpPourModule);
                req.setAttribute("nbNotifs", notifDAO.countNonLues(etudiant.getId()));
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/devoir_detail.jsp").forward(req, resp);
                break;
            }

            case "detail": {
                Long id = null;
                try { id = Long.parseLong(req.getParameter("id")); } catch (NumberFormatException e) { id = null; }
                if (id == null) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&notfound=1");
                    return;
                }
                TravailPratique tp = tpDAO.findById(id);
                if (tp == null || tp.getEtudiant() == null || !tp.getEtudiant().getId().equals(etudiant.getId())) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&notfound=1");
                    return;
                }
                boolean canUpdate = true;
                if (tp.getModule() != null) {
                    java.util.Date dateLimiteModule = rapportDAO.getMaxDateLimiteForModule(tp.getModule().getId());
                    if (dateLimiteModule != null && new Date().after(dateLimiteModule))
                        canUpdate = false;
                }
                CommentaireDAO commDAO = new CommentaireDAO();
                List<TravailPratique> versionHistory = tpDAO.findVersionHistory(id);
                req.setAttribute("tp", tp);
                req.setAttribute("versionHistory", versionHistory);
                req.setAttribute("commentaires", commDAO.findByTravail(id));
                req.setAttribute("canUpdate", canUpdate);
                req.setAttribute("nbNotifs", notifDAO.countNonLues(etudiant.getId()));
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/tp_detail.jsp").forward(req, resp);
                break;
            }

            case "supprimer": {
                Long id = null;
                try { id = Long.parseLong(req.getParameter("id")); } catch (NumberFormatException e) { id = null; }
                if (id == null) {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&notfound=1");
                    return;
                }
                TravailPratique tp = tpDAO.findById(id);
                if (tp != null && tp.getEtudiant() != null && tp.getEtudiant().getId().equals(etudiant.getId())
                        && tp.getStatut() == TravailPratique.Statut.SOUMIS) {
                    FileUploadUtil.supprimer(tp.getCheminFichier());
                    tpDAO.delete(id);
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&deleted=1");
                } else {
                    resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&section=feedback&erreur=suppression");
                }
                return;
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Etudiant etudiant = getEtudiantSession(req, resp);
        if (etudiant == null) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        String ctx = req.getContextPath();

        // ---- DÉPOSER UN TP ----
        if ("save".equals(action)) {
            String titre       = req.getParameter("titre");
            String description = req.getParameter("description");
            String moduleIdStr = req.getParameter("moduleId");
            String dateLimStr  = req.getParameter("dateLimite");
            String tpParentStr = req.getParameter("tpParentId");
            Part   fichierPart = req.getPart("fichier");

            // Validation
            StringBuilder erreur = new StringBuilder();
            if (titre == null || titre.trim().isEmpty()) erreur.append("Le titre est obligatoire. ");
            if (moduleIdStr == null || moduleIdStr.isEmpty()) erreur.append("Choisissez un module. ");
            if (fichierPart == null || fichierPart.getSize() == 0) erreur.append("Veuillez joindre un fichier. ");
            if (fichierPart != null && fichierPart.getSize() > FileUploadUtil.getTailleMax())
                erreur.append("Fichier trop volumineux (max 10 Mo). ");

            if (erreur.length() > 0) {
                req.setAttribute("erreur", erreur.toString().trim());
                List<Module> modules = moduleDAO.findByFiliere(
                    etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I"
                );
                req.setAttribute("modules", modules);
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/depot_form.jsp").forward(req, resp);
                return;
            }

            // Sauvegarder le fichier
            String cheminFichier;
            String nomFichier;
            try {
                nomFichier   = FileUploadUtil.extraireNomFichier(fichierPart);
                cheminFichier = FileUploadUtil.sauvegarder(fichierPart, etudiant.getId());
            } catch (IOException e) {
                req.setAttribute("erreur", "Fichier refusé : " + e.getMessage());
                List<Module> modules = moduleDAO.findByFiliere(
                    etudiant.getFiliere() != null ? etudiant.getFiliere() : "M2I"
                );
                req.setAttribute("modules", modules);
                req.getRequestDispatcher("/WEB-INF/vues/etudiant/depot_form.jsp").forward(req, resp);
                return;
            }

            Module module = moduleDAO.findById(Long.parseLong(moduleIdStr));

            // Vérifier la date limite (max des rapports du module) pour ce module
            java.util.Date dateLimiteModule = rapportDAO.getMaxDateLimiteForModule(module.getId());
            if (dateLimiteModule != null && new Date().after(dateLimiteModule)) {
                resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&deadlineDepasse=1");
                return;
            }

            // Calculer la version (si resoumission)
            int version = 1;
            TravailPratique parentTp = null;
            if (tpParentStr != null && !tpParentStr.isEmpty()) {
                parentTp = tpDAO.findById(Long.parseLong(tpParentStr));
                if (parentTp != null) version = parentTp.getVersion() + 1;
            }

            // Construire l'entité
            TravailPratique tp = new TravailPratique();
            tp.setTitre(titre.trim());
            tp.setDescription(description);
            tp.setNomFichier(nomFichier);
            tp.setCheminFichier(cheminFichier);
            tp.setModule(module);
            tp.setEtudiant(etudiant);
            tp.setVersion(version);
            tp.setParent(parentTp);
            tp.setStatut(TravailPratique.Statut.SOUMIS);

            // Date limite optionnelle
            if (dateLimStr != null && !dateLimStr.isEmpty()) {
                try {
                    Date dl = new SimpleDateFormat("yyyy-MM-dd").parse(dateLimStr);
                    tp.setDateLimite(dl);
                } catch (Exception ignored) {}
            }

            tpDAO.save(tp);

            // Notifier l'enseignant du module
            if (module.getEnseignant() != null) {
                NotificationService.tpDepose(
                    module.getEnseignant(),
                    etudiant.getNomComplet(),
                    module.getNom()
                );
            }

            resp.sendRedirect(ctx + "/etudiant/DepotTPServlet?action=list&success=1");

        // ---- AJOUTER UN COMMENTAIRE ----
        } else if ("commenter".equals(action)) {
            Long travailId = Long.parseLong(req.getParameter("travailId"));
            String contenu = req.getParameter("contenu");

            if (contenu != null && !contenu.trim().isEmpty()) {
                TravailPratique tp = tpDAO.findById(travailId);
                if (tp != null && tp.getEtudiant().getId().equals(etudiant.getId())) {
                Commentaire comm = new Commentaire();
                    comm.setContenu(contenu.trim());
                    comm.setAuteur(etudiant);
                    comm.setTravail(tp);
                    comm.setDateCreation(new java.util.Date());
                    new CommentaireDAO().save(comm);

                    // Notifier l'enseignant
                    if (tp.getModule() != null && tp.getModule().getEnseignant() != null) {
                        NotificationService.nouveauCommentaire(
                            tp.getModule().getEnseignant(),
                            etudiant.getNomComplet(),
                            tp.getModule().getNom()
                        );
                    }
                }
            }
            resp.sendRedirect(req.getContextPath() +
                "/etudiant/DepotTPServlet?action=detail&id=" + travailId + "&commented=1");
        }
    }
}