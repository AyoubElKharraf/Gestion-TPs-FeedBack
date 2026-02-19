package model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "modules")
public class Module {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    @Column
    private String description;

    @Column
    private String filiere; // ex: M2I

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "enseignant_id")
    private Enseignant enseignant;

    @OneToMany(mappedBy = "module", fetch = FetchType.LAZY)
    private List<TravailPratique> travaux;

    public Module() {}

    // Getters & Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getDescription() { return description; }
    public void setDescription(String d) { this.description = d; }
    public String getFiliere() { return filiere; }
    public void setFiliere(String f) { this.filiere = f; }
    public Enseignant getEnseignant() { return enseignant; }
    public void setEnseignant(Enseignant e) { this.enseignant = e; }
    public List<TravailPratique> getTravaux() { return travaux; }
    public void setTravaux(List<TravailPratique> t) { this.travaux = t; }
}