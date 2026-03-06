package model;

/**
 * DTO : un étudiant n'ayant pas rendu le TP pour un module (date limite dépassée).
 * Utilisé côté enseignant pour afficher la liste et "Signaler au système d'absences".
 */
public class NonRemisItem {

    private final Etudiant etudiant;
    private final Module module;
    private final Rapport rapport;

    public NonRemisItem(Etudiant etudiant, Module module, Rapport rapport) {
        this.etudiant = etudiant;
        this.module = module;
        this.rapport = rapport;
    }

    public Etudiant getEtudiant() { return etudiant; }
    public Module getModule() { return module; }
    public Rapport getRapport() { return rapport; }
}
