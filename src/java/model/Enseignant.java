package model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "enseignants")
@PrimaryKeyJoinColumn(name = "utilisateur_id")
public class Enseignant extends Utilisateur {

    @Column
    private String specialite;

    @OneToMany(mappedBy = "enseignant", fetch = FetchType.LAZY)
    private List<Module> modules;

    public Enseignant() {}

    public String getSpecialite() { return specialite; }
    public void setSpecialite(String specialite) { this.specialite = specialite; }
    public List<Module> getModules() { return modules; }
    public void setModules(List<Module> modules) { this.modules = modules; }
}