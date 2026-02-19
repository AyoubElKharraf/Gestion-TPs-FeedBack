package model;

import jakarta.persistence.*;
import java.util.Date;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String message;

    @Column
    private boolean lu = false;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateCreation;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "destinataire_id")
    private Utilisateur destinataire;

    /** Expéditeur du message (null = notification système) */
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "expediteur_id")
    private Utilisateur expediteur;

    public Notification() { this.dateCreation = new Date(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getMessage() { return message; }
    public void setMessage(String m) { this.message = m; }
    public boolean isLu() { return lu; }
    public void setLu(boolean l) { this.lu = l; }
    public Date getDateCreation() { return dateCreation; }
    public void setDateCreation(Date d) { this.dateCreation = d; }
    public Utilisateur getDestinataire() { return destinataire; }
    public void setDestinataire(Utilisateur d) { this.destinataire = d; }
    public Utilisateur getExpediteur() { return expediteur; }
    public void setExpediteur(Utilisateur e) { this.expediteur = e; }
}