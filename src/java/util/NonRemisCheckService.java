package util;

import dao.EtudiantDAO;
import dao.RapportDAO;
import dao.TravailPratiqueDAO;
import model.Etudiant;
import model.Rapport;
import model.TravailPratique;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Vérifie les TPs non rendus à la date limite et notifie le système d'absences.
 * À appeler périodiquement ou sur demande (ex: servlet admin).
 */
public final class NonRemisCheckService {

    /**
     * Pour chaque rapport dont la date limite est dépassée, identifie les étudiants
     * du même module (filière) qui n'ont pas déposé de TP pour ce module et envoie
     * une alerte au système d'absences (une fois par couple étudiant/module).
     */
    public static void checkAndNotifyNonRemis() {
        RapportDAO rapportDAO = new RapportDAO();
        EtudiantDAO etudiantDAO = new EtudiantDAO();
        TravailPratiqueDAO tpDAO = new TravailPratiqueDAO();

        List<Rapport> rapportsDepasses = rapportDAO.findRapportsWithDateLimitePassed();
        if (rapportsDepasses == null || rapportsDepasses.isEmpty()) return;

        Set<String> dejaNotifies = new HashSet<>();

        for (Rapport rapport : rapportsDepasses) {
            if (rapport.getModule() == null) continue;
            String filiere = rapport.getModule().getFiliere() != null ? rapport.getModule().getFiliere() : "M2I";
            List<Etudiant> etudiants = etudiantDAO.findByFiliere(filiere);
            if (etudiants == null) continue;

            for (Etudiant etu : etudiants) {
                String key = etu.getId() + "_" + rapport.getModule().getId();
                if (dejaNotifies.contains(key)) continue;

                List<TravailPratique> travaux = tpDAO.findByEtudiant(etu.getId());
                boolean aRendu = false;
                if (travaux != null) {
                    for (TravailPratique t : travaux) {
                        if (t.getModule() != null && t.getModule().getId().equals(rapport.getModule().getId())) {
                            aRendu = true;
                            break;
                        }
                    }
                }
                if (!aRendu) {
                    String emailEnseignant = rapport.getModule().getEnseignant() != null
                        ? rapport.getModule().getEnseignant().getEmail() : null;
                    AbsenceIntegrationService.notifyNonRemisTp(
                        etu.getId(),
                        rapport.getModule().getId(),
                        rapport.getModule().getNom(),
                        rapport.getTitre(),
                        etu.getEmail(),
                        emailEnseignant
                    );
                    dejaNotifies.add(key);
                }
            }
        }
    }
}
