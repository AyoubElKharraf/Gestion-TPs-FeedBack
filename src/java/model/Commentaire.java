package model;

import jakarta.persistence.*;
import java.util.Date;

@Entity
@Table(name = "commentaires")
public class Commentaire {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String contenu;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateCreation;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "auteur_id")
    private Utilisateur auteur;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "travail_id")
    private TravailPratique travail;

    public Commentaire() { this.dateCreation = new Date(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getContenu() { return contenu; }
    public void setContenu(String c) { this.contenu = c; }
    public Date getDateCreation() { return dateCreation; }
    public void setDateCreation(Date d) { this.dateCreation = d; }
    public Utilisateur getAuteur() { return auteur; }
    public void setAuteur(Utilisateur a) { this.auteur = a; }
    public TravailPratique getTravail() { return travail; }
    public void setTravail(TravailPratique t) { this.travail = t; }
}