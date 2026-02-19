package model;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Signalement d'absence par un enseignant pour un étudiant.
 * Utilisé pour mettre à jour nbAbsences et aSupprimer (si ≥ 3 enseignants distincts ont signalé).
 */
@Entity
@Table(name = "absence_reports")
public class AbsenceReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "etudiant_id", nullable = false)
    private Etudiant etudiant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "enseignant_id", nullable = false)
    private Enseignant enseignant;

    @Column(name = "date_report", nullable = false)
    private Instant dateReport = Instant.now();

    public AbsenceReport() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Etudiant getEtudiant() { return etudiant; }
    public void setEtudiant(Etudiant etudiant) { this.etudiant = etudiant; }
    public Enseignant getEnseignant() { return enseignant; }
    public void setEnseignant(Enseignant enseignant) { this.enseignant = enseignant; }
    public Instant getDateReport() { return dateReport; }
    public void setDateReport(Instant dateReport) { this.dateReport = dateReport; }
}
