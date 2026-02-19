package model;

import jakarta.persistence.*;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "travaux_pratiques")
public class TravailPratique {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titre;

    @Column
    private String description;

    @Column
    private String cheminFichier;

    @Column
    private String nomFichier;

    @Column
    private int version = 1;

    @Enumerated(EnumType.STRING)
    private Statut statut = Statut.SOUMIS;

    @Column
    private Double note;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateSoumission;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateLimite;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "etudiant_id")
    private Etudiant etudiant;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "module_id")
    private Module module;

    @OneToMany(mappedBy = "travail", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Commentaire> commentaires;

    public enum Statut { SOUMIS, EN_CORRECTION, CORRIGE, RENDU }

    public TravailPratique() {
        this.dateSoumission = new Date();
    }

    // Getters & Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitre() { return titre; }
    public void setTitre(String t) { this.titre = t; }
    public String getDescription() { return description; }
    public void setDescription(String d) { this.description = d; }
    public String getCheminFichier() { return cheminFichier; }
    public void setCheminFichier(String c) { this.cheminFichier = c; }
    public String getNomFichier() { return nomFichier; }
    public void setNomFichier(String n) { this.nomFichier = n; }
    public int getVersion() { return version; }
    public void setVersion(int v) { this.version = v; }
    public Statut getStatut() { return statut; }
    public void setStatut(Statut s) { this.statut = s; }
    public Double getNote() { return note; }
    public void setNote(Double n) { this.note = n; }
    public Date getDateSoumission() { return dateSoumission; }
    public void setDateSoumission(Date d) { this.dateSoumission = d; }
    public Date getDateLimite() { return dateLimite; }
    public void setDateLimite(Date d) { this.dateLimite = d; }
    public Etudiant getEtudiant() { return etudiant; }
    public void setEtudiant(Etudiant e) { this.etudiant = e; }
    public Module getModule() { return module; }
    public void setModule(Module m) { this.module = m; }
    public List<Commentaire> getCommentaires() { return commentaires; }
    public void setCommentaires(List<Commentaire> c) { this.commentaires = c; }
}