package servlet.api;

import dao.EtudiantDAO;
import dao.ModuleDAO;
import dao.RapportDAO;
import dao.TravailPratiqueDAO;
import model.Etudiant;
import model.Module;
import model.Rapport;
import model.TravailPratique;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * API pour le système d'absences.
 * GET /api/non-rendus : liste des étudiants n'ayant pas rendu de TP pour un module dont la date limite est dépassée.
 * Réponse JSON : [ {"etudiantId":1,"etudiantNom":"...","moduleId":1,"moduleNom":"..."}, ... ]
 */
@WebServlet("/api/non-rendus")
public class NonRendusApiServlet extends HttpServlet {

    private final ModuleDAO moduleDAO = new ModuleDAO();
    private final RapportDAO rapportDAO = new RapportDAO();
    private final EtudiantDAO etudiantDAO = new EtudiantDAO();
    private final TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type, X-API-Key");

        Date now = new Date();
        List<Object[]> result = new ArrayList<>();

        List<Module> modules = moduleDAO.findAll();
        for (Module m : modules) {
            if (m.getFiliere() == null) continue;
            Date maxLimite = rapportDAO.getMaxDateLimiteForModule(m.getId());
            if (maxLimite == null || !now.after(maxLimite)) continue;

            List<Etudiant> etudiants = etudiantDAO.findByFiliere(m.getFiliere());
            for (Etudiant e : etudiants) {
                List<TravailPratique> tps = tpDAO.findByEtudiant(e.getId());
                boolean hasTpForModule = false;
                for (TravailPratique tp : tps) {
                    if (tp.getModule() != null && tp.getModule().getId().equals(m.getId())) {
                        hasTpForModule = true;
                        break;
                    }
                }
                if (!hasTpForModule) {
                    result.add(new Object[]{e.getId(), e.getNomComplet(), m.getId(), m.getNom()});
                }
            }
        }

        PrintWriter out = resp.getWriter();
        out.print("[");
        for (int i = 0; i < result.size(); i++) {
            Object[] row = result.get(i);
            if (i > 0) out.print(",");
            out.print("{\"etudiantId\":" + row[0] + ",\"etudiantNom\":\"" + escapeJson((String) row[1]) + "\",\"moduleId\":" + row[2] + ",\"moduleNom\":\"" + escapeJson((String) row[3]) + "\"}");
        }
        out.print("]");
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
