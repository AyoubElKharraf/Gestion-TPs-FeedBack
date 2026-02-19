package servlet.enseignant;

import dao.ModuleDAO;
import dao.NotificationDAO;
import dao.RapportDAO;
import model.Enseignant;
import model.Module;
import model.Rapport;
import model.Utilisateur;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

/**
 * Enseignant: déposer plusieurs rapports par module (chaque dépôt ajoute un nouveau rapport).
 */
@WebServlet("/enseignant/RapportServlet")
@MultipartConfig(maxFileSize = 15 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class RapportServlet extends HttpServlet {

    private final ModuleDAO moduleDAO = new ModuleDAO();
    private final RapportDAO rapportDAO = new RapportDAO();
    private final NotificationDAO notifDAO = new NotificationDAO();

    private Enseignant getEnseignant(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Utilisateur u = (Utilisateur) req.getSession().getAttribute("utilisateur");
        if (u == null || u.getRole() != Utilisateur.Role.ENSEIGNANT) {
            resp.sendRedirect(req.getContextPath() + "/LoginServlet");
            return null;
        }
        return (Enseignant) u;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Enseignant ens = getEnseignant(req, resp);
        if (ens == null) return;

        String action = req.getParameter("action");
        if ("delete".equals(action)) {
            String idParam = req.getParameter("id");
            if (idParam != null) {
                Long id = Long.parseLong(idParam);
                Rapport r = rapportDAO.findById(id);
                if (r != null && r.getModule() != null && r.getModule().getEnseignant() != null
                        && r.getModule().getEnseignant().getId().equals(ens.getId())) {
                    rapportDAO.delete(id);
                }
            }
            resp.sendRedirect(req.getContextPath() + "/enseignant/RapportServlet?deleted=1");
            return;
        }

        List<Module> modules = moduleDAO.findByEnseignant(ens.getId());
        List<Rapport> rapports = rapportDAO.findByEnseignant(ens.getId());
        req.setAttribute("modules", modules);
        req.setAttribute("rapports", rapports);
        req.setAttribute("nbNotifs", notifDAO.countNonLues(ens.getId()));
        req.setAttribute("activeSection", "rapports");
        req.getRequestDispatcher("/WEB-INF/vues/enseignant/rapports.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Enseignant ens = getEnseignant(req, resp);
        if (ens == null) return;
        req.setCharacterEncoding("UTF-8");

        String moduleIdStr = req.getParameter("moduleId");
        String titre = req.getParameter("titre");
        Part filePart = req.getPart("fichier");

        if (moduleIdStr == null || titre == null || titre.trim().isEmpty() || filePart == null || filePart.getSize() == 0) {
            resp.sendRedirect(req.getContextPath() + "/enseignant/RapportServlet?error=1");
            return;
        }

        Long moduleId = Long.parseLong(moduleIdStr);
        Module module = moduleDAO.findById(moduleId);
        if (module == null || !module.getEnseignant().getId().equals(ens.getId())) {
            resp.sendRedirect(req.getContextPath() + "/enseignant/RapportServlet?error=2");
            return;
        }

        String fileName = getFileName(filePart);
        String contentType = filePart.getContentType();
        byte[] content = filePart.getInputStream().readAllBytes();

        Rapport r = new Rapport();
        r.setModule(module);
        r.setTitre(titre.trim());
        r.setFileName(fileName);
        r.setContentType(contentType != null ? contentType : "application/octet-stream");
        r.setFileContent(content);
        String dateLimiteStr = req.getParameter("dateLimite");
        if (dateLimiteStr != null && !dateLimiteStr.trim().isEmpty()) {
            try {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
                r.setDateLimite(sdf.parse(dateLimiteStr.trim()));
            } catch (Exception e) {
                try {
                    SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd");
                    r.setDateLimite(sdf2.parse(dateLimiteStr.trim()));
                } catch (Exception ignored) {}
            }
        }
        rapportDAO.save(r);

        resp.sendRedirect(req.getContextPath() + "/enseignant/RapportServlet?success=1");
    }

    private static String getFileName(Part part) {
        String cd = part.getHeader("Content-Disposition");
        if (cd == null) return "document";
        for (String s : cd.split(";")) {
            s = s.trim();
            if (s.toLowerCase().startsWith("filename=")) {
                String name = s.substring(9).trim();
                if (name.startsWith("\"") && name.endsWith("\"")) name = name.substring(1, name.length() - 1);
                int slash = Math.max(name.lastIndexOf('/'), name.lastIndexOf('\\'));
                if (slash >= 0) name = name.substring(slash + 1);
                return name.isEmpty() ? "document" : name;
            }
        }
        return "document";
    }
}
