package model;

import jakarta.persistence.*;
import java.util.Date;

/**
 * Rapport / document déposé par l'enseignant pour un module.
 * Visible et téléchargeable par les étudiants du module ; ils peuvent ensuite déposer leur TP pour ce module.
 */
@Entity
@Table(name = "rapports")
public class Rapport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "module_id", nullable = false)
    private Module module;

    @Column(nullable = false)
    private String titre;

    @Column(name = "file_name")
    private String fileName;

    @Column(name = "content_type", length = 128)
    private String contentType;

    @Lob
    @Column(name = "file_content", columnDefinition = "LONGBLOB")
    private byte[] fileContent;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "date_creation", nullable = false)
    private Date dateCreation = new Date();

    /** Date limite pour déposer ou modifier un TP (définie par l'enseignant). */
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "date_limite")
    private Date dateLimite;

    public Rapport() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Module getModule() { return module; }
    public void setModule(Module module) { this.module = module; }
    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }
    public byte[] getFileContent() { return fileContent; }
    public void setFileContent(byte[] fileContent) { this.fileContent = fileContent; }
    public Date getDateCreation() { return dateCreation; }
    public void setDateCreation(Date dateCreation) { this.dateCreation = dateCreation; }
    public Date getDateLimite() { return dateLimite; }
    public void setDateLimite(Date dateLimite) { this.dateLimite = dateLimite; }
}
