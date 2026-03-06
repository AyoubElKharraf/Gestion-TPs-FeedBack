# EtudAcadPro — Application de gestion académique

**Mini-projet Jakarta EE** : gestion des étudiants, enseignants, modules, travaux pratiques (TP), rapports et absences, avec intégration API vers un système externe (AbsTrack / Gestion_AbsencesAlerts).

---

## Sommaire

1. [Technologies et Stack](#1-technologies-et-stack)
2. [Architecture MVC](#2-architecture-mvc)
3. [JPA et Hibernate — Configuration](#3-jpa-et-hibernate--configuration)
4. [Architecture de la base de données](#4-architecture-de-la-base-de-données)
5. [Entités JPA — Annotations et code](#5-entités-jpa--annotations-et-code)
6. [DAOs — Méthodes et requêtes JPQL](#6-daos--méthodes-et-requêtes-jpql)
7. [Servlets — Annotations et URLs](#7-servlets--annotations-et-urls)
8. [Classes utilitaires](#8-classes-utilitaires)
9. [Vues JSP — Structure et directives](#9-vues-jsp--structure-et-directives)
10. [Sécurité et hashage des mots de passe](#10-sécurité-et-hashage-des-mots-de-passe)
11. [Intégration API avec l'application des absences](#11-intégration-api-avec-lapplication-des-absences)
12. [Structure complète du projet](#12-structure-complète-du-projet)
13. [Installation et déploiement](#13-installation-et-déploiement)
14. [Auteurs](#14-auteurs)

---

## 1. Technologies et Stack

| Composant | Technologie | Version / Détail |
|-----------|-------------|------------------|
| Langage | **Java** | 17 |
| Plateforme | **Jakarta EE** | Servlets 6.0, JSP 3.1, JPA 3.1 |
| ORM | **Hibernate** | 5.6+ (provider JPA) |
| Base de données | **MySQL** | 8 (driver `com.mysql.cj.jdbc.Driver`) |
| Serveur d'application | **WildFly** | 27+ (Jakarta EE 10/11) |
| Build | **NetBeans / Ant** | WAR : `EtudAcadPro.war` |
| CSS | **TailwindCSS** | CDN (via `<script src="cdn.tailwindcss.com">`) |

---

## 2. Architecture MVC

```
┌────────────────────────────────────────────────────────────────────┐
│                           CLIENT (Navigateur)                      │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│                      CONTRÔLEUR (Servlets)                         │
│  servlet.LoginServlet, servlet.admin.*, servlet.enseignant.*,      │
│  servlet.etudiant.*, servlet.api.*                                 │
│  Annotations : @WebServlet, @WebFilter, @MultipartConfig           │
└────────────────────────────────────────────────────────────────────┘
          │ request.setAttribute()         │ forward() / sendRedirect()
          ▼                                ▼
┌─────────────────────────┐     ┌─────────────────────────────────────┐
│      MODÈLE (JPA)       │     │            VUE (JSP)                │
│  model.Utilisateur,     │     │  WEB-INF/vues/login.jsp,            │
│  model.Etudiant,        │     │  admin/*.jsp, enseignant/*.jsp,     │
│  model.Module, ...      │     │  etudiant/*.jsp, notifications.jsp  │
│  dao.*DAO               │     │  Directives : <%@ page %>, <%= %>   │
└─────────────────────────┘     └─────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────────────────────────┐
│                    BASE DE DONNÉES (MySQL)                         │
│  Tables : utilisateurs, enseignants, etudiants, modules, rapports, │
│           travaux_pratiques, commentaires, notifications,          │
│           absence_reports                                          │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. JPA et Hibernate — Configuration

### 3.1 Fichier `persistence.xml`

Emplacement : `WEB-INF/classes/META-INF/persistence.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="3.0"
             xmlns="https://jakarta.ee/xml/ns/persistence">

    <persistence-unit name="MiniProjetPU" transaction-type="RESOURCE_LOCAL">
        <provider>org.hibernate.jpa.HibernatePersistenceProvider</provider>

        <!-- Classes mappées -->
        <class>model.Utilisateur</class>
        <class>model.Module</class>
        <class>model.Enseignant</class>
        <class>model.Etudiant</class>
        <class>model.TravailPratique</class>
        <class>model.Commentaire</class>
        <class>model.Notification</class>
        <class>model.AbsenceReport</class>
        <class>model.Rapport</class>

        <exclude-unlisted-classes>false</exclude-unlisted-classes>

        <properties>
            <!-- Connexion JDBC -->
            <property name="jakarta.persistence.jdbc.driver"
                      value="com.mysql.cj.jdbc.Driver"/>
            <property name="jakarta.persistence.jdbc.url"
                      value="jdbc:mysql://localhost:3306/miniprojet_be4?useSSL=false&amp;serverTimezone=UTC&amp;allowPublicKeyRetrieval=true"/>
            <property name="jakarta.persistence.jdbc.user" value="root"/>
            <property name="jakarta.persistence.jdbc.password" value="..."/>

            <!-- Hibernate -->
            <property name="hibernate.dialect" value="org.hibernate.dialect.MySQLDialect"/>
            <property name="hibernate.hbm2ddl.auto" value="update"/>
            <property name="hibernate.show_sql" value="false"/>
            <property name="hibernate.transaction.coordinator_class" value="jdbc"/>
        </properties>
    </persistence-unit>
</persistence>
```

### 3.2 Classe `JPAUtil` (Singleton EntityManagerFactory)

```java
package dao;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Persistence;

public class JPAUtil {
    private static final EntityManagerFactory emf;

    static {
        emf = Persistence.createEntityManagerFactory("MiniProjetPU");
    }

    public static EntityManager getEntityManager() {
        return emf.createEntityManager();
    }

    public static void close() {
        if (emf != null && emf.isOpen()) {
            emf.close();
        }
    }
}
```

---

## 4. Architecture de la base de données

### 4.1 Schéma relationnel

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              UTILISATEURS (utilisateurs)                        │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ email          │ VARCHAR(255)  │ UNIQUE, NOT NULL                               │
│ mot_de_passe   │ VARCHAR(255)  │ NOT NULL (haché SHA-256)                       │
│ role           │ ENUM          │ 'ADMIN', 'ENSEIGNANT', 'ETUDIANT'              │
│ nom            │ VARCHAR(255)  │ NOT NULL                                       │
│ prenom         │ VARCHAR(255)  │ NOT NULL                                       │
└────────────────┴───────────────┴────────────────────────────────────────────────┘
         ▲ (héritage JOINED)
         │
    ┌────┴────┐
    │         │
┌───▼────┐ ┌──▼─────────┐
│ENSEIGNANTS│ │ ETUDIANTS  │
├─────────┤ ├────────────┤
│utilisateur_id (PK,FK) │ utilisateur_id (PK,FK) │
│specialite (VARCHAR)   │ filiere (VARCHAR)      │
│                       │ numero_etudiant        │
│                       │ nb_absences (INT)      │
│                       │ a_supprimer (BOOLEAN)  │
└─────────┘ └────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                MODULES (modules)                                │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ nom            │ VARCHAR(255)  │ NOT NULL                                       │
│ description    │ VARCHAR(255)  │                                                │
│ filiere        │ VARCHAR(255)  │ ex: 'M2I'                                      │
│ enseignant_id  │ BIGINT (FK)   │ → enseignants(utilisateur_id)                  │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                RAPPORTS (rapports)                              │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ module_id      │ BIGINT (FK)   │ → modules(id), NOT NULL                        │
│ titre          │ VARCHAR(255)  │ NOT NULL                                       │
│ file_name      │ VARCHAR(255)  │ Nom du fichier uploadé                         │
│ content_type   │ VARCHAR(128)  │ ex: 'application/pdf'                          │
│ file_content   │ LONGBLOB      │ Contenu binaire du fichier                     │
│ date_creation  │ DATETIME      │ NOT NULL, default NOW                          │
│ date_limite    │ DATETIME      │ Date limite pour déposer le TP                 │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                        TRAVAUX_PRATIQUES (travaux_pratiques)                    │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ titre          │ VARCHAR(255)  │ NOT NULL                                       │
│ description    │ TEXT          │                                                │
│ chemin_fichier │ VARCHAR(255)  │ Chemin relatif (ex: etudiant_1/file.zip)       │
│ nom_fichier    │ VARCHAR(255)  │ Nom original                                   │
│ version        │ INT           │ default 1                                      │
│ statut         │ ENUM          │ 'SOUMIS', 'EN_CORRECTION', 'CORRIGE', 'RENDU'  │
│ note           │ DOUBLE        │ Note sur 20                                    │
│ date_soumission│ DATETIME      │                                                │
│ date_limite    │ DATETIME      │                                                │
│ etudiant_id    │ BIGINT (FK)   │ → etudiants(utilisateur_id)                    │
│ module_id      │ BIGINT (FK)   │ → modules(id)                                  │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            COMMENTAIRES (commentaires)                          │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ contenu        │ TEXT          │ NOT NULL                                       │
│ date_creation  │ DATETIME      │                                                │
│ auteur_id      │ BIGINT (FK)   │ → utilisateurs(id)                             │
│ travail_id     │ BIGINT (FK)   │ → travaux_pratiques(id)                        │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                           NOTIFICATIONS (notifications)                         │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ message        │ TEXT          │ NOT NULL                                       │
│ lu             │ BOOLEAN       │ default FALSE                                  │
│ date_creation  │ DATETIME      │                                                │
│ destinataire_id│ BIGINT (FK)   │ → utilisateurs(id)                             │
│ expediteur_id  │ BIGINT (FK)   │ → utilisateurs(id) (NULL = système)            │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                        ABSENCE_REPORTS (absence_reports)                        │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ etudiant_id    │ BIGINT (FK)   │ → etudiants(utilisateur_id), NOT NULL          │
│ enseignant_id  │ BIGINT (FK)   │ → enseignants(utilisateur_id), NOT NULL        │
│ date_report    │ TIMESTAMP     │ NOT NULL, default NOW                          │
└────────────────┴───────────────┴────────────────────────────────────────────────┘
```

### 4.2 Relations entre tables

| Relation | Type | Description |
|----------|------|-------------|
| `utilisateurs` → `enseignants` | 1:1 (JOINED) | Héritage JPA |
| `utilisateurs` → `etudiants` | 1:1 (JOINED) | Héritage JPA |
| `enseignants` → `modules` | 1:N | Un enseignant a plusieurs modules |
| `modules` → `travaux_pratiques` | 1:N | Un module a plusieurs TP |
| `modules` → `rapports` | 1:N | Un module a plusieurs rapports |
| `etudiants` → `travaux_pratiques` | 1:N | Un étudiant a plusieurs TP |
| `travaux_pratiques` → `commentaires` | 1:N (CASCADE ALL) | Un TP a plusieurs commentaires |
| `utilisateurs` → `notifications` (dest) | 1:N | Un utilisateur reçoit plusieurs notifications |
| `utilisateurs` → `notifications` (exp) | 1:N | Un utilisateur envoie plusieurs messages |
| `etudiants` → `absence_reports` | 1:N | Signalements d'absence |
| `enseignants` → `absence_reports` | 1:N | Signalements d'absence |

---

## 5. Entités JPA — Annotations et code

### 5.1 `model.Utilisateur` (classe parente)

```java
@Entity
@Table(name = "utilisateurs")
@Inheritance(strategy = InheritanceType.JOINED)
public class Utilisateur {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String motDePasse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String prenom;

    public enum Role { ADMIN, ENSEIGNANT, ETUDIANT }

    // Constructeur vide (JPA)
    public Utilisateur() {}

    // Constructeur paramétré
    public Utilisateur(String email, String motDePasse, Role role, String nom, String prenom) { ... }

    // Getters & Setters
    public Long getId() { ... }
    public void setId(Long id) { ... }
    public String getEmail() { ... }
    public void setEmail(String email) { ... }
    public String getMotDePasse() { ... }
    public void setMotDePasse(String motDePasse) { ... }
    public Role getRole() { ... }
    public void setRole(Role role) { ... }
    public String getNom() { ... }
    public void setNom(String nom) { ... }
    public String getPrenom() { ... }
    public void setPrenom(String prenom) { ... }

    // Méthode utilitaire
    public String getNomComplet() { return prenom + " " + nom; }
}
```

**Annotations utilisées :**
- `@Entity` : marque la classe comme entité JPA
- `@Table(name = "...")` : nom de la table en BDD
- `@Inheritance(strategy = InheritanceType.JOINED)` : héritage avec table séparée par sous-classe
- `@Id` : clé primaire
- `@GeneratedValue(strategy = GenerationType.IDENTITY)` : auto-incrément MySQL
- `@Column(nullable, unique)` : contraintes sur la colonne
- `@Enumerated(EnumType.STRING)` : stocke l'enum en texte

---

### 5.2 `model.Enseignant` (hérite de Utilisateur)

```java
@Entity
@Table(name = "enseignants")
@PrimaryKeyJoinColumn(name = "utilisateur_id")
public class Enseignant extends Utilisateur {

    @Column
    private String specialite;

    @OneToMany(mappedBy = "enseignant", fetch = FetchType.LAZY)
    private List<Module> modules;

    // Getters & Setters
    public String getSpecialite() { ... }
    public void setSpecialite(String specialite) { ... }
    public List<Module> getModules() { ... }
    public void setModules(List<Module> modules) { ... }
}
```

**Annotations :**
- `@PrimaryKeyJoinColumn(name = "utilisateur_id")` : jointure sur la clé primaire parente
- `@OneToMany(mappedBy = "enseignant", fetch = FetchType.LAZY)` : relation 1:N, chargement paresseux

---

### 5.3 `model.Etudiant` (hérite de Utilisateur)

```java
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

    // Méthodes spécifiques
    public int getNbAbsences() { return nbAbsences != null ? nbAbsences : 0; }
    public void incrementNbAbsences() { this.nbAbsences = getNbAbsences() + 1; }
    public boolean isASupprimer() { return Boolean.TRUE.equals(aSupprimer); }
}
```

---

### 5.4 `model.Module`

```java
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
    private String filiere;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "enseignant_id")
    private Enseignant enseignant;

    @OneToMany(mappedBy = "module", fetch = FetchType.LAZY)
    private List<TravailPratique> travaux;
}
```

**Annotations :**
- `@ManyToOne(fetch = FetchType.EAGER)` : relation N:1, chargement immédiat
- `@JoinColumn(name = "enseignant_id")` : colonne de jointure

---

### 5.5 `model.Rapport`

```java
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

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "date_limite")
    private Date dateLimite;
}
```

**Annotations spécifiques :**
- `@Lob` : Large Object (BLOB)
- `@Column(columnDefinition = "LONGBLOB")` : type exact MySQL
- `@Temporal(TemporalType.TIMESTAMP)` : mapping Date → DATETIME

---

### 5.6 `model.TravailPratique`

```java
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
}
```

**Annotation importante :**
- `@OneToMany(cascade = CascadeType.ALL)` : suppression en cascade des commentaires si le TP est supprimé

---

### 5.7 `model.Commentaire`

```java
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
}
```

---

### 5.8 `model.Notification`

```java
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

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "expediteur_id")
    private Utilisateur expediteur;  // NULL = notification système
}
```

---

### 5.9 `model.AbsenceReport`

```java
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
}
```

---

### 5.10 DTOs (non-entités)

| Classe | Rôle |
|--------|------|
| `model.FeedItem` | Élément du flux d'activité (dashboard enseignant). Champs : `type` (RAPPORT/TP), `date`, `title`, `subtitle`, `authorName`, `actionUrl`, `actionLabel`, `id`. |
| `model.NonRemisItem` | Étudiant n'ayant pas rendu de TP pour un module (liste absences). Champs : `etudiant`, `module`, `rapport`. |

---

## 6. DAOs — Méthodes et requêtes JPQL

### 6.1 Pattern DAO

Chaque DAO utilise `JPAUtil.getEntityManager()`, gère les transactions et ferme l'EntityManager en `finally`.

### 6.2 `UtilisateurDAO`

| Méthode | Signature | JPQL / Logique |
|---------|-----------|----------------|
| `authenticate` | `Utilisateur authenticate(String email, String motDePasse)` | `SELECT u FROM Utilisateur u WHERE u.email = :email` puis `PasswordUtil.verify(...)` |
| `findAll` | `List<Utilisateur> findAll()` | `SELECT u FROM Utilisateur u` |
| `findById` | `Utilisateur findById(Long id)` | `em.find(Utilisateur.class, id)` |
| `findByRole` | `List<Utilisateur> findByRole(Role role)` | `SELECT u FROM Utilisateur u WHERE u.role = :role` |
| `findEnseignantById` | `Enseignant findEnseignantById(Long id)` | `em.find(Enseignant.class, id)` |
| `save` | `void save(Utilisateur u)` | `em.persist(u)` |
| `update` | `void update(Utilisateur u)` | `em.merge(u)` |
| `delete` | `void delete(Long id)` | `em.find` + `em.remove` |

---

### 6.3 `EtudiantDAO`

| Méthode | JPQL |
|---------|------|
| `findByEmail(String email)` | `SELECT e FROM Etudiant e WHERE LOWER(e.email) = LOWER(:email)` |
| `findAll()` | `SELECT e FROM Etudiant e` |
| `findByFiliere(String filiere)` | `SELECT e FROM Etudiant e WHERE e.filiere = :filiere` |
| `findFlaggedForDeletion()` | `SELECT e FROM Etudiant e WHERE e.aSupprimer = true` |
| `search(String keyword)` | `SELECT e FROM Etudiant e WHERE LOWER(e.nom) LIKE :kw OR LOWER(e.prenom) LIKE :kw OR LOWER(e.email) LIKE :kw OR LOWER(e.numeroEtudiant) LIKE :kw` |
| `findById(Long id)` | `em.find(Etudiant.class, id)` |
| `emailExists(String email, Long excludeId)` | `SELECT COUNT(e) FROM Etudiant e WHERE e.email = :email AND e.id <> :id` |
| `save(Etudiant e)` | `em.persist(e)` |
| `update(Etudiant e)` | `em.merge(e)` |
| `updateAbsencesAndFlag(Long id, int nb, boolean flag)` | `UPDATE Etudiant e SET e.nbAbsences = :nb, e.aSupprimer = :as WHERE e.id = :id` |
| `delete(Long id)` | `em.find` + `em.remove` |
| `count()` | `SELECT COUNT(e) FROM Etudiant e` |

---

### 6.4 `EnseignantDAO`

| Méthode | JPQL |
|---------|------|
| `findAll()` | `SELECT e FROM Enseignant e` |
| `findById(Long id)` | `em.find(Enseignant.class, id)` |
| `save(Enseignant e)` | `em.persist(e)` |
| `update(Enseignant e)` | `em.merge(e)` |
| `delete(Long id)` | `em.find` + `em.remove` |
| `search(String keyword)` | `SELECT e FROM Enseignant e WHERE LOWER(e.nom) LIKE :kw OR LOWER(e.prenom) LIKE :kw OR LOWER(e.email) LIKE :kw OR LOWER(e.specialite) LIKE :kw` |
| `emailExists(String email, Long excludeId)` | `SELECT COUNT(e) FROM Enseignant e WHERE e.email = :email AND e.id <> :id` |
| `count()` | `SELECT COUNT(e) FROM Enseignant e` |

---

### 6.5 `ModuleDAO`

| Méthode | JPQL |
|---------|------|
| `findAll()` | `SELECT m FROM Module m` |
| `findByFiliere(String filiere)` | `SELECT m FROM Module m WHERE m.filiere = :filiere` |
| `findById(Long id)` | `em.find(Module.class, id)` |
| `findByEnseignant(Long enseignantId)` | `SELECT m FROM Module m WHERE m.enseignant.id = :id` |
| `save(Module m)` | `em.persist(m)` |
| `update(Module m)` | `em.merge(m)` |
| `delete(Long id)` | `em.find` + `em.remove` |

---

### 6.6 `RapportDAO`

| Méthode | JPQL |
|---------|------|
| `findById(Long id)` | `em.find(Rapport.class, id)` |
| `findByIdWithModule(Long id)` | `SELECT r FROM Rapport r LEFT JOIN FETCH r.module m LEFT JOIN FETCH m.enseignant WHERE r.id = :id` |
| `findByModule(Long moduleId)` | `SELECT r FROM Rapport r WHERE r.module.id = :id ORDER BY r.dateCreation DESC` (limit 1) |
| `findAllByModule(Long moduleId)` | `SELECT r FROM Rapport r WHERE r.module.id = :id ORDER BY r.dateCreation DESC` |
| `getMaxDateLimiteForModule(Long moduleId)` | `SELECT MAX(r.dateLimite) FROM Rapport r WHERE r.module.id = :id AND r.dateLimite IS NOT NULL` |
| `findByEnseignant(Long enseignantId)` | `SELECT r FROM Rapport r JOIN r.module m WHERE m.enseignant.id = :id ORDER BY r.dateCreation DESC` |
| `findByEnseignantWithModule(Long enseignantId)` | `SELECT r FROM Rapport r LEFT JOIN FETCH r.module m WHERE m.enseignant.id = :id ORDER BY r.dateCreation DESC` |
| `findRapportsWithDateLimitePassed()` | `SELECT r FROM Rapport r LEFT JOIN FETCH r.module m LEFT JOIN FETCH m.enseignant WHERE r.dateLimite IS NOT NULL AND r.dateLimite < :now ORDER BY r.dateLimite DESC` |
| `findByModuleIds(List<Long> moduleIds)` | `SELECT r FROM Rapport r LEFT JOIN FETCH r.module WHERE r.module.id IN :ids` |
| `save(Rapport r)` | `em.persist(r)` |
| `update(Rapport r)` | `em.merge(r)` |
| `delete(Long id)` | `em.find` + `em.remove` |

---

### 6.7 `TravailPratiqueDAO`

| Méthode | JPQL |
|---------|------|
| `findAll()` | `SELECT t FROM TravailPratique t LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module ORDER BY t.dateSoumission DESC` |
| `findByEtudiant(Long etudiantId)` | `SELECT t FROM TravailPratique t LEFT JOIN FETCH t.module WHERE t.etudiant.id = :id ORDER BY t.dateSoumission DESC` |
| `findEtudiantsByEnseignant(Long enseignantId)` | `SELECT DISTINCT t.etudiant FROM TravailPratique t JOIN t.module m WHERE m.enseignant.id = :id AND t.etudiant IS NOT NULL` |
| `findEnseignantsByEtudiant(Long etudiantId)` | `SELECT DISTINCT e FROM TravailPratique t JOIN t.module m JOIN m.enseignant e WHERE t.etudiant.id = :id` |
| `findByModule(Long moduleId)` | `SELECT t FROM TravailPratique t LEFT JOIN FETCH t.etudiant WHERE t.module.id = :id ORDER BY t.dateSoumission DESC` |
| `findByEnseignant(Long enseignantId)` | `SELECT t FROM TravailPratique t LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module m WHERE m.enseignant.id = :id ORDER BY t.dateSoumission DESC` |
| `findByStatut(Statut statut)` | `SELECT t FROM TravailPratique t LEFT JOIN FETCH t.etudiant LEFT JOIN FETCH t.module WHERE t.statut = :statut ORDER BY t.dateSoumission DESC` |
| `findById(Long id)` | `em.find(TravailPratique.class, id)` |
| `save(TravailPratique t)` | `em.persist(t)` |
| `update(TravailPratique t)` | `em.merge(t)` → retourne l'entité mergée |
| `delete(Long id)` | `em.find` + `em.remove` |
| `deleteByEtudiant(Long etudiantId)` | SELECT puis `em.remove` pour chaque TP |
| `countByStatut(Statut statut)` | `SELECT COUNT(t) FROM TravailPratique t WHERE t.statut = :s` |

---

### 6.8 `CommentaireDAO`

| Méthode | JPQL |
|---------|------|
| `findByTravail(Long travailId)` | `SELECT c FROM Commentaire c WHERE c.travail.id = :id ORDER BY c.dateCreation ASC` |
| `save(Commentaire c)` | `em.persist(c)` |
| `delete(Long id)` | `em.find` + `em.remove` |

---

### 6.9 `NotificationDAO`

| Méthode | JPQL |
|---------|------|
| `findConversation(Long u1, Long u2)` | `SELECT DISTINCT n FROM Notification n LEFT JOIN FETCH n.expediteur LEFT JOIN FETCH n.destinataire WHERE n.expediteur IS NOT NULL AND ((n.destinataire.id = :u1 AND n.expediteur.id = :u2) OR (n.destinataire.id = :u2 AND n.expediteur.id = :u1)) ORDER BY n.dateCreation ASC` |
| `findByDestinataire(Long utilisateurId)` | `SELECT n FROM Notification n LEFT JOIN FETCH n.expediteur WHERE n.destinataire.id = :id ORDER BY n.lu ASC, n.dateCreation DESC` |
| `findNonLues(Long utilisateurId)` | `SELECT n FROM Notification n WHERE n.destinataire.id = :id AND n.lu = false ORDER BY n.dateCreation DESC` |
| `getLastMessageDate(Long u1, Long u2)` | `SELECT n.dateCreation FROM Notification n WHERE n.expediteur IS NOT NULL AND (...) ORDER BY n.dateCreation DESC` (limit 1) |
| `countUnreadFrom(Long dest, Long exp)` | `SELECT COUNT(n) FROM Notification n WHERE n.destinataire.id = :dest AND n.expediteur.id = :exp AND n.lu = false` |
| `countNonLues(Long utilisateurId)` | `SELECT COUNT(n) FROM Notification n WHERE n.destinataire.id = :id AND n.lu = false` |
| `save(Notification n)` | `em.persist(n)` |
| `marquerLue(Long id, Long destinataireUserId)` | `em.find` + `setLu(true)` (vérifie destinataire) |
| `marquerLuesFromExpediteur(Long dest, Long exp)` | `UPDATE Notification n SET n.lu = true WHERE n.destinataire.id = :dest AND n.expediteur.id = :exp AND n.lu = false` |
| `marquerToutesLues(Long utilisateurId)` | `UPDATE Notification n SET n.lu = true WHERE n.destinataire.id = :id AND n.lu = false` |
| `delete(Long id)` | `em.find` + `em.remove` |

---

### 6.10 `AbsenceReportDAO`

| Méthode | JPQL |
|---------|------|
| `save(AbsenceReport r)` | `em.persist(r)` |
| `countByEtudiant(Long etudiantId)` | `SELECT COUNT(r) FROM AbsenceReport r WHERE r.etudiant.id = :id` |
| `countDistinctEnseignantsByEtudiant(Long etudiantId)` | `SELECT COUNT(DISTINCT r.enseignant.id) FROM AbsenceReport r WHERE r.etudiant.id = :id` |

---

## 7. Servlets — Annotations et URLs

### 7.1 Annotations utilisées

| Annotation | Package | Rôle |
|------------|---------|------|
| `@WebServlet("/url")` | `jakarta.servlet.annotation` | Déclare une servlet mappée sur une URL |
| `@WebFilter("/pattern/*")` | `jakarta.servlet.annotation` | Déclare un filtre sur un pattern |
| `@MultipartConfig` | `jakarta.servlet.annotation` | Active l'upload de fichiers (`Part`) |

### 7.2 Tableau des servlets

| Classe | URL | Annotation | Méthodes HTTP | Rôle |
|--------|-----|------------|---------------|------|
| **Authentification** |
| `servlet.LoginServlet` | `/LoginServlet` | `@WebServlet("/LoginServlet")` | GET, POST | Affiche login, authentifie, redirige selon rôle |
| `servlet.LogoutServlet` | `/LogoutServlet` | `@WebServlet("/LogoutServlet")` | GET | Invalide session, redirige vers login |
| **Commun** |
| `servlet.NotificationServlet` | `/NotificationServlet` | `@WebServlet("/NotificationServlet")` | GET, POST | Liste, count (AJAX), marquer lu |
| `servlet.RapportDownloadServlet` | `/RapportDownloadServlet` | `@WebServlet("/RapportDownloadServlet")` | GET | Téléchargement fichier rapport (contrôle accès) |
| **Admin** |
| `servlet.admin.DashboardServlet` | `/admin/DashboardServlet` | `@WebServlet("/admin/DashboardServlet")` | GET | Tableau de bord admin |
| `servlet.admin.ModuleServlet` | `/admin/ModuleServlet` | `@WebServlet("/admin/ModuleServlet")` | GET, POST | CRUD modules (list, detail, form, save, delete) |
| `servlet.admin.EnseignantServlet` | `/admin/EnseignantServlet` | `@WebServlet("/admin/EnseignantServlet")` | GET, POST | CRUD enseignants |
| `servlet.admin.EtudiantServlet` | `/admin/EtudiantServlet` | `@WebServlet("/admin/EtudiantServlet")` | GET, POST | CRUD étudiants, signaler-absence |
| `servlet.admin.MessageServlet` | `/admin/MessageServlet` | `@WebServlet("/admin/MessageServlet")` | GET, POST | Messagerie admin |
| `servlet.admin.CheckNonRemisServlet` | `/admin/CheckNonRemisServlet` | `@WebServlet("/admin/CheckNonRemisServlet")` | GET | Déclenche `NonRemisCheckService.checkAndNotifyNonRemis()` |
| **Enseignant** |
| `servlet.enseignant.DashboardServlet` | `/enseignant/DashboardServlet` | `@WebServlet("/enseignant/DashboardServlet")` | GET | Tableau de bord, feed |
| `servlet.enseignant.RapportServlet` | `/enseignant/RapportServlet` | `@WebServlet("/enseignant/RapportServlet")` | GET, POST | Liste rapports, upload |
| `servlet.enseignant.CorrectionTPServlet` | `/enseignant/CorrectionTPServlet` | `@WebServlet("/enseignant/CorrectionTPServlet")` | GET, POST | Liste TP, détail, correction, commentaires |
| `servlet.enseignant.AbsenceServlet` | `/enseignant/AbsenceServlet` | `@WebServlet("/enseignant/AbsenceServlet")` | GET | Liste non-rendus (NonRemisItem) |
| `servlet.enseignant.SignalerAbsenceTpServlet` | `/enseignant/SignalerAbsenceTpServlet` | `@WebServlet("/enseignant/SignalerAbsenceTpServlet")` | GET | Signale absence vers AbsTrack |
| `servlet.enseignant.CommentaireServlet` | `/enseignant/CommentaireServlet` | `@WebServlet("/enseignant/CommentaireServlet")` | GET | Liste commentaires |
| `servlet.enseignant.MessageServlet` | `/enseignant/MessageServlet` | `@WebServlet("/enseignant/MessageServlet")` | GET, POST | Messagerie enseignant |
| **Étudiant** |
| `servlet.etudiant.DashboardServlet` | `/etudiant/DashboardServlet` | `@WebServlet("/etudiant/DashboardServlet")` | GET | Redirige vers DepotTPServlet |
| `servlet.etudiant.DepotTPServlet` | `/etudiant/DepotTPServlet` | `@WebServlet, @MultipartConfig` | GET, POST | Liste TP, dépôt fichier, détail |
| `servlet.etudiant.MessageServlet` | `/etudiant/MessageServlet` | `@WebServlet("/etudiant/MessageServlet")` | GET, POST | Messagerie étudiant |
| **API REST** |
| `servlet.api.AbsenceReportApiServlet` | `/api/absence` | `@WebServlet("/api/absence")` | GET, POST, OPTIONS | Enregistre signalement absence (appelé par AbsTrack) |
| `servlet.api.NonRendusApiServlet` | `/api/non-rendus` | `@WebServlet("/api/non-rendus")` | GET | Liste JSON des non-rendus |
| `servlet.api.AlerteDepassementApiServlet` | `/api/alerte-depassement` | `@WebServlet("/api/alerte-depassement")` | GET, POST, OPTIONS | Reçoit alerte dépassement (3 absences) depuis AbsTrack |

### 7.3 Exemple `@MultipartConfig`

```java
@WebServlet("/etudiant/DepotTPServlet")
@MultipartConfig(
    maxFileSize    = 10 * 1024 * 1024,  // 10 Mo par fichier
    maxRequestSize = 15 * 1024 * 1024   // 15 Mo par requête
)
public class DepotTPServlet extends HttpServlet { ... }
```

### 7.4 Filtre d'authentification

```java
@WebFilter("/vues/*")
public class AuthFilter implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);

        boolean loggedIn = (session != null && session.getAttribute("utilisateur") != null);

        if (!loggedIn) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
        } else {
            chain.doFilter(req, res);
        }
    }
}
```

---

## 8. Classes utilitaires

### 8.1 `util.PasswordUtil`

| Méthode | Signature | Rôle |
|---------|-----------|------|
| `hash` | `static String hash(String password)` | Retourne hash SHA-256 (64 hex) avec sel fixe `"EtudAcadPro#2025"` |
| `verify` | `static boolean verify(String inputPassword, String stored)` | Compare le hash du mot de passe saisi avec la valeur stockée ; compatible ancien stockage en clair |

### 8.2 `util.FileUploadUtil`

| Méthode | Signature | Rôle |
|---------|-----------|------|
| `sauvegarder` | `static String sauvegarder(Part part, Long etudiantId)` | Enregistre le fichier sous `user.home/tp_uploads/etudiant_<id>/` avec nom unique (UUID), retourne chemin relatif |
| `supprimer` | `static void supprimer(String cheminRelatif)` | Supprime le fichier du disque |
| `extraireNomFichier` | `static String extraireNomFichier(Part part)` | Extrait le nom du fichier depuis `Content-Disposition` |
| `obtenirExtension` | `static String obtenirExtension(String nom)` | Retourne l'extension (ex: `.pdf`) |
| `getTailleMax` | `static long getTailleMax()` | Retourne 10 Mo |

**Extensions autorisées :** `.pdf, .doc, .docx, .zip, .rar, .java, .py, .txt, .png, .jpg`

### 8.3 `util.NotificationService`

| Méthode | Signature | Rôle |
|---------|-----------|------|
| `envoyer` | `static void envoyer(Utilisateur destinataire, String message)` | Crée une notification système (expediteur = null) |
| `envoyerMessage` | `static void envoyerMessage(Utilisateur expediteur, Utilisateur destinataire, String message)` | Crée un message entre utilisateurs |
| `tpDepose` | `static void tpDepose(Utilisateur enseignant, String nomEtudiant, String nomModule)` | Notification "📄 ... a déposé un TP" |
| `tpCorrige` | `static void tpCorrige(Utilisateur etudiant, String nomModule, Double note)` | Notification "✅ Votre TP a été corrigé" |
| `nouveauCommentaire` | `static void nouveauCommentaire(Utilisateur destinataire, String auteur, String nomModule)` | Notification "💬 ... a ajouté un commentaire" |
| `tpEnRetard` | `static void tpEnRetard(Utilisateur etudiant, String nomModule)` | Notification "⚠️ Date limite dépassée" |

### 8.4 `util.AbsenceIntegrationService`

| Méthode | Signature | Rôle |
|---------|-----------|------|
| `notifyNonRemisTp` | `static boolean notifyNonRemisTp(Long etudiantId, Long moduleId, String moduleNom, String rapportTitre, String emailEtudiant, String emailEnseignant, String baseUrlOverride)` | POST vers `<base>/api/alerte` avec type `non_remis_tp` |
| `notifyNonRemisTp` | (surcharge sans baseUrlOverride) | Utilise propriété système ou env |
| `getAbsencesParEnseignant` | `static List<AbsenceParEnseignant> getAbsencesParEnseignant(String emailEtudiant, String baseUrlOverride)` | GET vers `<base>/api/etudiant/absences-par-enseignant?email=...` |
| `notifyDepassementAbsences` | `static void notifyDepassementAbsences(Long etudiantId)` | POST vers `<base>/api/alerte` avec type `depassement_absences` |

**DTO interne :** `AbsenceParEnseignant(String enseignantNom, int nbAbsences)`

### 8.5 `util.NonRemisCheckService`

| Méthode | Signature | Rôle |
|---------|-----------|------|
| `checkAndNotifyNonRemis` | `static void checkAndNotifyNonRemis()` | Parcourt les rapports dont `dateLimite < now`, pour chaque étudiant de la filière sans TP pour ce module, appelle `AbsenceIntegrationService.notifyNonRemisTp`. Évite les doublons (Set). |

---

## 9. Vues JSP — Structure et directives

### 9.1 Directives utilisées

| Directive | Exemple | Rôle |
|-----------|---------|------|
| `<%@ page %>` | `<%@ page contentType="text/html;charset=UTF-8" language="java" %>` | Définit le type de contenu et l'encodage |
| `<%@ page import %>` | `<%@ page import="model.Utilisateur, java.util.List" %>` | Importe des classes Java |
| `<% ... %>` | `<% String ctx = request.getContextPath(); %>` | Scriptlet Java |
| `<%= ... %>` | `<%= userSession.getNomComplet() %>` | Expression (affichage) |

### 9.2 Pattern des vues

Toutes les vues sont sous `WEB-INF/vues/` (protégées, accès par forward uniquement).

```jsp
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Utilisateur, model.Module, java.util.List" %>
<%
    // Récupération des attributs de requête
    Utilisateur userSession = (Utilisateur) session.getAttribute("utilisateur");
    List<Module> modules = (List<Module>) request.getAttribute("modules");
    Long nbNotifs = (Long) request.getAttribute("nbNotifs");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8"/>
    <title>Titre – EtudAcadPro</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: { extend: { colors: { primary: '#1a2744' } } }
        }
    </script>
</head>
<body class="bg-gray-100 min-h-screen">
    <!-- Header -->
    <!-- Sidebar / Navigation -->
    <!-- Contenu principal -->
    <!-- JavaScript -->
</body>
</html>
```

### 9.3 Liste des vues

| Chemin | Servlet associée | Rôle |
|--------|------------------|------|
| **Commun** |
| `login.jsp` | LoginServlet | Formulaire email/mot de passe, validation JS |
| `notifications.jsp` | NotificationServlet | Liste des notifications, marquage lu |
| **Admin** |
| `admin/dashboard.jsp` | DashboardServlet | Accueil admin, liens vers modules/enseignants/étudiants |
| `admin/modules.jsp` | ModuleServlet | Liste des modules (tableau, liens action) |
| `admin/module_detail.jsp` | ModuleServlet | Détail d'un module, modification |
| `admin/module_form.jsp` | ModuleServlet | Formulaire création/édition module |
| `admin/enseignants.jsp` | EnseignantServlet | Liste des enseignants |
| `admin/enseignant_detail.jsp` | EnseignantServlet | Fiche enseignant |
| `admin/enseignant_form.jsp` | EnseignantServlet | Formulaire enseignant |
| `admin/etudiants.jsp` | EtudiantServlet | Liste étudiants, section "à supprimer" |
| `admin/etudiant_detail.jsp` | EtudiantServlet | Fiche étudiant, absences par enseignant (API) |
| `admin/etudiant_form.jsp` | EtudiantServlet | Formulaire étudiant |
| `admin/messages.jsp` | MessageServlet | Messagerie admin |
| **Enseignant** |
| `enseignant/dashboard.jsp` | DashboardServlet | Feed d'activité, stats |
| `enseignant/rapports.jsp` | RapportServlet | Liste rapports, formulaire upload |
| `enseignant/liste_tps.jsp` | CorrectionTPServlet | Liste des TP à corriger |
| `enseignant/tp_correction.jsp` | CorrectionTPServlet | Détail TP, note, commentaires |
| `enseignant/absences.jsp` | AbsenceServlet | Liste non-rendus, bouton "Signaler" |
| `enseignant/commentaires.jsp` | CommentaireServlet | Liste commentaires |
| `enseignant/message.jsp` | MessageServlet | Messagerie enseignant |
| **Étudiant** |
| `etduaint/dashboard.jsp` | DashboardServlet | (redirige vers DepotTPServlet) |
| `etduaint/mes_tps.jsp` | DepotTPServlet | Liste TP (modules, devoirs, feedback) |
| `etduaint/depot_form.jsp` | DepotTPServlet | Formulaire dépôt TP |
| `etduaint/devoir_detail.jsp` | DepotTPServlet | Détail d'un devoir/rapport |
| `etduaint/tp_detail.jsp` | DepotTPServlet | Détail TP avec commentaires |
| `etduaint/message.jsp` | MessageServlet | Messagerie étudiant |

*Note : le dossier est nommé `etduaint` (typo pour `etudiant`).*

---

## 10. Sécurité et hashage des mots de passe

### 10.1 Algorithme

- **SHA-256** avec sel fixe `"EtudAcadPro#2025"`
- Résultat : chaîne hexadécimale de 64 caractères

### 10.2 Code (`util.PasswordUtil`)

```java
public static String hash(String password) {
    if (password == null) return null;
    try {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        md.update(SALT.getBytes(StandardCharsets.UTF_8));
        byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder(64);
        for (byte b : hash) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    } catch (NoSuchAlgorithmException e) {
        return null;
    }
}

public static boolean verify(String inputPassword, String stored) {
    if (inputPassword == null || stored == null) return false;
    // Si stocké en hash (64 hex), compare les hash
    if (stored.length() == 64 && stored.matches("[0-9a-fA-F]+")) {
        return stored.equalsIgnoreCase(hash(inputPassword));
    }
    // Sinon comparaison en clair (migration)
    return stored.equals(inputPassword);
}
```

### 10.3 Utilisation

- **Création étudiant** (`EtudiantServlet`) : `etudiant.setMotDePasse(PasswordUtil.hash(motDePasse))`
- **Création enseignant** (`EnseignantServlet`) : `enseignant.setMotDePasse(PasswordUtil.hash(motDePasse))`
- **Connexion** (`UtilisateurDAO.authenticate`) : `PasswordUtil.verify(motDePasse, u.getMotDePasse())`

---

## 11. Intégration API avec l'application des absences

### 11.1 Configuration

**`web.xml` :**

```xml
<context-param>
    <param-name>absence.system.url</param-name>
    <param-value>http://localhost:8081/AbsTrack</param-value>
</context-param>
```

**Lecture dans les servlets :**

```java
String baseUrl = getServletContext().getInitParameter("absence.system.url");
```

### 11.2 Appels sortants (EtudAcadPro → AbsTrack)

| Appel | Endpoint AbsTrack | Déclencheur |
|-------|-------------------|-------------|
| Non remis TP | `POST <base>/api/alerte` | `NonRemisCheckService`, `SignalerAbsenceTpServlet` |
| Dépassement absences | `POST <base>/api/alerte` | `EtudiantServlet (signaler-absence)` |
| Absences par enseignant | `GET <base>/api/etudiant/absences-par-enseignant?email=...` | `EtudiantServlet (detail)` |

### 11.3 API exposées par EtudAcadPro

| Méthode | URL | Corps | Réponse |
|---------|-----|-------|---------|
| POST | `/api/absence` | `{ "etudiantId": 1, "enseignantId": 2 }` | `{ "success": true, "etudiantId": 1, "nbAbsences": 3, "aSupprimer": true }` |
| GET | `/api/non-rendus` | — | `[{ "etudiantId": 1, "etudiantNom": "...", "moduleId": 1, "moduleNom": "..." }]` |
| POST | `/api/alerte-depassement` | `{ "emailEtudiant": "...", "nbAbsences": 5 }` | `{ "success": true, "message": "..." }` |

**CORS activé** : `Access-Control-Allow-Origin: *`

---

## 12. Structure complète du projet

```
EtudAcadPro/
├── src/java/
│   ├── dao/
│   │   ├── AbsenceReportDAO.java
│   │   ├── CommentaireDAO.java
│   │   ├── EnseignantDAO.java
│   │   ├── EtudiantDAO.java
│   │   ├── JPAUtil.java
│   │   ├── ModuleDAO.java
│   │   ├── NotificationDAO.java
│   │   ├── RapportDAO.java
│   │   ├── TravailPratiqueDAO.java
│   │   └── UtilisateurDAO.java
│   ├── model/
│   │   ├── AbsenceReport.java
│   │   ├── Commentaire.java
│   │   ├── Enseignant.java
│   │   ├── Etudiant.java
│   │   ├── FeedItem.java
│   │   ├── Module.java
│   │   ├── NonRemisItem.java
│   │   ├── Notification.java
│   │   ├── Rapport.java
│   │   ├── TravailPratique.java
│   │   └── Utilisateur.java
│   ├── servlet/
│   │   ├── LoginServlet.java
│   │   ├── LogoutServlet.java
│   │   ├── NotificationServlet.java
│   │   ├── RapportDownloadServlet.java
│   │   ├── admin/
│   │   │   ├── CheckNonRemisServlet.java
│   │   │   ├── DashboardServlet.java
│   │   │   ├── EnseignantServlet.java
│   │   │   ├── EtudiantServlet.java
│   │   │   ├── MessageServlet.java
│   │   │   └── ModuleServlet.java
│   │   ├── api/
│   │   │   ├── AbsenceReportApiServlet.java
│   │   │   ├── AlerteDepassementApiServlet.java
│   │   │   └── NonRendusApiServlet.java
│   │   ├── enseignant/
│   │   │   ├── AbsenceServlet.java
│   │   │   ├── CommentaireServlet.java
│   │   │   ├── CorrectionTPServlet.java
│   │   │   ├── DashboardServlet.java
│   │   │   ├── MessageServlet.java
│   │   │   ├── RapportServlet.java
│   │   │   └── SignalerAbsenceTpServlet.java
│   │   └── etudiant/
│   │       ├── DashboardServlet.java
│   │       ├── DepotTPServlet.java
│   │       └── MessageServlet.java
│   └── util/
│       ├── AbsenceIntegrationService.java
│       ├── AuthFilter.java
│       ├── FileUploadUtil.java
│       ├── NonRemisCheckService.java
│       ├── NotificationService.java
│       └── PasswordUtil.java
├── web/
│   ├── index.jsp
│   └── WEB-INF/
│       ├── web.xml
│       ├── classes/META-INF/persistence.xml
│       └── vues/
│           ├── login.jsp
│           ├── notifications.jsp
│           ├── admin/ (8 JSP)
│           ├── enseignant/ (7 JSP)
│           └── etduaint/ (6 JSP)
├── dist/
│   └── EtudAcadPro.war
├── README.md
└── EVALUATION.md
```

---

## 13. Installation et déploiement

### 13.1 Prérequis

- JDK 17
- MySQL 8
- WildFly 27+ (ou serveur Jakarta EE compatible)

### 13.2 Base de données

```sql
CREATE DATABASE miniprojet_be4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Configurer `persistence.xml` avec URL, utilisateur, mot de passe.

### 13.3 Build

NetBeans : **Clean and Build** → `dist/EtudAcadPro.war`

### 13.4 Déploiement

Copier `EtudAcadPro.war` dans `standalone/deployments/` (WildFly).

### 13.5 Accès

`http://localhost:8080/EtudAcadPro/`

---

## 14. Auteurs

**Mini-projet Jakarta EE — ELKHARRAF / MANSOURI**

Gestion académique : étudiants, enseignants, modules, TP, rapports, absences. Hashage des mots de passe, intégration API avec l'application de gestion des absences (AbsTrack / Gestion_AbsencesAlerts).
