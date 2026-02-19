package model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "etudiants")
@PrimaryKeyJoinColumn(name = "utilisateur_id")
public class Etudiant extends Utilisateur {

    @Column
    private String filiere;

    @Column
    private String numeroEtudiant;

    @Column
    private Integer nbAbsences;

    @Column
    private Boolean aSupprimer;

    @OneToMany(mappedBy = "etudiant", fetch = FetchType.LAZY)
    private List<TravailPratique> travaux;

    public Etudiant() {}

    public String getFiliere() { return filiere; }
    public void setFiliere(String filiere) { this.filiere = filiere; }
    public String getNumeroEtudiant() { return numeroEtudiant; }
    public void setNumeroEtudiant(String n) { this.numeroEtudiant = n; }
    public List<TravailPratique> getTravaux() { return travaux; }
    public void setTravaux(List<TravailPratique> travaux) { this.travaux = travaux; }

    public int getNbAbsences() { return nbAbsences != null ? nbAbsences : 0; }
    public void setNbAbsences(Integer nbAbsences) { this.nbAbsences = nbAbsences; }
    public void incrementNbAbsences() { this.nbAbsences = getNbAbsences() + 1; }

    public boolean isASupprimer() { return Boolean.TRUE.equals(aSupprimer); }
    public void setASupprimer(Boolean aSupprimer) { this.aSupprimer = aSupprimer; }
}