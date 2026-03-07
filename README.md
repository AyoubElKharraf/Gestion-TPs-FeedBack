# EtudAcadPro — Application de gestion académique

**Mini-projet Jakarta EE** : gestion des étudiants, enseignants, modules, travaux pratiques (TP), rapports et absences, avec intégration API vers un système externe (AbsTrack / Gestion_AbsencesAlerts).

**Version 2.0** — Sécurité renforcée (PBKDF2, API Key, Logger centralisé)

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
9. [Système de sécurité complet](#9-système-de-sécurité-complet)
10. [Authentification et filtres](#10-authentification-et-filtres)
11. [Logger centralisé](#11-logger-centralisé)
12. [Gestion des versions des TPs](#12-gestion-des-versions-des-tps)
13. [Vues JSP — Structure et JSTL](#13-vues-jsp--structure-et-jstl)
14. [Intégration API avec l'application des absences](#14-intégration-api-avec-lapplication-des-absences)
15. [Structure complète du projet](#15-structure-complète-du-projet)
16. [Installation et déploiement](#16-installation-et-déploiement)
17. [Auteurs](#17-auteurs)

---

## 1. Technologies et Stack

| Composant | Technologie | Version / Détail |
|-----------|-------------|------------------|
| Langage | **Java** | 17 |
| Plateforme | **Jakarta EE** | Servlets 6.0, JSP 3.1, JPA 3.1, JSTL 3.0 |
| ORM | **Hibernate** | 5.6+ (provider JPA) |
| Base de données | **MySQL** | 8 (driver `com.mysql.cj.jdbc.Driver`) |
| Serveur d'application | **WildFly** | 27+ (Jakarta EE 10/11) |
| Build | **NetBeans / Ant** | WAR : `EtudAcadPro.war` |
| CSS | **TailwindCSS** | CDN (via `<script src="cdn.tailwindcss.com">`) |
| Sécurité | **PBKDF2** | Hashage mots de passe avec sel unique |
| Logging | **AppLogger** | Logger centralisé fichier + console |

---

## 2. Architecture MVC

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT (Navigateur)                                │
└────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                              CHAÎNE DE FILTRES                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │ 1. SecurityFilter (@WebFilter "/*")                                      │  │
│  │    → Ajoute en-têtes HTTP de sécurité (CSP, X-Frame-Options, etc.)       │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │ 2. ApiKeyFilter (@WebFilter "/api/*")                                    │  │
│  │    → Vérifie clé API (header X-API-Key) ou IP whitelist                  │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │ 3. AuthFilter (@WebFilter "/vues/*", "/admin/*", "/enseignant/*",        │  │
│  │                           "/etudiant/*")                                 │  │
│  │    → Vérifie session + rôle utilisateur                                  │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                         CONTRÔLEUR (Servlets)                                   │
│  servlet.LoginServlet, servlet.admin.*, servlet.enseignant.*,                   │
│  servlet.etudiant.*, servlet.api.*                                              │
│  Annotations : @WebServlet, @WebFilter, @MultipartConfig                        │
└────────────────────────────────────────────────────────────────────────────────┘
           │ request.setAttribute()              │ forward() / sendRedirect()
           ▼                                     ▼
┌─────────────────────────────┐     ┌─────────────────────────────────────────────┐
│       MODÈLE (JPA)          │     │              VUE (JSP + JSTL)                │
│  model.Utilisateur,         │     │  WEB-INF/vues/login.jsp,                     │
│  model.Etudiant,            │     │  admin/*.jsp, enseignant/*.jsp,              │
│  model.Module, ...          │     │  etudiant/*.jsp, notifications.jsp           │
│  dao.*DAO                   │     │  JSTL: <c:out>, <c:if>, <c:forEach>          │
│                             │     │  HtmlUtil.escape() pour scriptlets           │
└─────────────────────────────┘     └─────────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                         BASE DE DONNÉES (MySQL)                                 │
│  Tables : utilisateurs, enseignants, etudiants, modules, rapports,              │
│           travaux_pratiques, commentaires, notifications, absence_reports       │
└────────────────────────────────────────────────────────────────────────────────┘
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

/**
 * Gestionnaire singleton pour l'EntityManagerFactory JPA.
 * Pattern singleton pour éviter les fuites de connexions.
 */
public class JPAUtil {
    private static final EntityManagerFactory emf;

    static {
        emf = Persistence.createEntityManagerFactory("MiniProjetPU");
    }

    /**
     * Crée un nouvel EntityManager.
     * IMPORTANT : toujours fermer l'EntityManager après utilisation.
     */
    public static EntityManager getEntityManager() {
        return emf.createEntityManager();
    }

    /**
     * Ferme l'EntityManagerFactory (à appeler à l'arrêt de l'application).
     */
    public static void close() {
        if (emf != null && emf.isOpen()) {
            emf.close();
        }
    }
}
```

---

## 4. Architecture de la base de données

### 4.1 Schéma relationnel complet

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              UTILISATEURS (utilisateurs)                        │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ email          │ VARCHAR(255)  │ UNIQUE, NOT NULL                               │
│ mot_de_passe   │ VARCHAR(255)  │ NOT NULL (PBKDF2 ou SHA-256 legacy)            │
│ role           │ ENUM          │ 'ADMIN', 'ENSEIGNANT', 'ETUDIANT'              │
│ nom            │ VARCHAR(255)  │ NOT NULL                                       │
│ prenom         │ VARCHAR(255)  │ NOT NULL                                       │
└────────────────┴───────────────┴────────────────────────────────────────────────┘
         ▲ (héritage JOINED)
         │
    ┌────┴────┐
    │         │
┌───▼────────────────┐ ┌───▼─────────────────┐
│   ENSEIGNANTS      │ │     ETUDIANTS       │
├────────────────────┤ ├─────────────────────┤
│utilisateur_id (PK,FK)│ │utilisateur_id (PK,FK)│
│specialite (VARCHAR)  │ │filiere (VARCHAR)      │
│                      │ │numero_etudiant        │
│                      │ │nb_absences (INT)      │
│                      │ │a_supprimer (BOOLEAN)  │
└────────────────────┘ └─────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              MODULES (modules)                                  │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ nom            │ VARCHAR(255)  │ NOT NULL                                       │
│ filiere        │ VARCHAR(100)  │ Ex: "M2I", "GLSI"                              │
│ enseignant_id  │ BIGINT (FK)   │ → enseignants(utilisateur_id)                  │
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
│ parent_id      │ BIGINT (FK)   │ → travaux_pratiques(id) [VERSION PARENTE]      │
│ statut         │ ENUM          │ 'SOUMIS', 'EN_CORRECTION', 'CORRIGE', 'RENDU'  │
│ note           │ DOUBLE        │ Note sur 20                                    │
│ date_soumission│ DATETIME      │                                                │
│ date_limite    │ DATETIME      │                                                │
│ etudiant_id    │ BIGINT (FK)   │ → etudiants(utilisateur_id)                    │
│ module_id      │ BIGINT (FK)   │ → modules(id)                                  │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              RAPPORTS (rapports)                                │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ titre          │ VARCHAR(255)  │ NOT NULL                                       │
│ description    │ TEXT          │                                                │
│ chemin_fichier │ VARCHAR(255)  │ Chemin du support de cours                     │
│ nom_fichier    │ VARCHAR(255)  │                                                │
│ date_limite    │ DATETIME      │ Date limite de rendu TP                        │
│ date_creation  │ DATETIME      │                                                │
│ module_id      │ BIGINT (FK)   │ → modules(id)                                  │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                           COMMENTAIRES (commentaires)                           │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ contenu        │ TEXT          │ NOT NULL                                       │
│ date_creation  │ DATETIME      │                                                │
│ auteur_id      │ BIGINT (FK)   │ → utilisateurs(id)                             │
│ travail_id     │ BIGINT (FK)   │ → travaux_pratiques(id) ON DELETE CASCADE      │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                          NOTIFICATIONS (notifications)                          │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ message        │ TEXT          │ NOT NULL                                       │
│ lue            │ BOOLEAN       │ default FALSE                                  │
│ date_creation  │ DATETIME      │                                                │
│ destinataire_id│ BIGINT (FK)   │ → utilisateurs(id)                             │
│ expediteur_id  │ BIGINT (FK)   │ → utilisateurs(id) [NULLABLE - système]        │
└────────────────┴───────────────┴────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                        ABSENCE_REPORTS (absence_reports)                        │
├────────────────┬───────────────┬────────────────────────────────────────────────┤
│ id             │ BIGINT (PK)   │ AUTO_INCREMENT                                 │
│ date_signalement│ DATETIME     │                                                │
│ etudiant_id    │ BIGINT (FK)   │ → etudiants(utilisateur_id)                    │
│ enseignant_id  │ BIGINT (FK)   │ → enseignants(utilisateur_id)                  │
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
| `travaux_pratiques` → `travaux_pratiques` | N:1 (self) | **Versioning** : lien parent |
| `travaux_pratiques` → `commentaires` | 1:N (CASCADE ALL) | Un TP a plusieurs commentaires |
| `utilisateurs` → `notifications` (dest) | 1:N | Un utilisateur reçoit plusieurs notifications |

---

## 5. Entités JPA — Annotations et code

### 5.1 `model.Utilisateur` (Classe parente — Héritage JOINED)

```java
package model;

import jakarta.persistence.*;

/**
 * Entité parente pour tous les utilisateurs.
 * Stratégie d'héritage JOINED : une table par sous-classe.
 */
@Entity
@Table(name = "utilisateurs")
@Inheritance(strategy = InheritanceType.JOINED)
public class Utilisateur {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "mot_de_passe", nullable = false)
    private String motDePasse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String prenom;

    public enum Role { ADMIN, ENSEIGNANT, ETUDIANT }

    // Méthode utilitaire
    public String getNomComplet() {
        return prenom + " " + nom;
    }

    // Getters & Setters...
}
```

**Annotations utilisées :**
| Annotation | Rôle |
|------------|------|
| `@Entity` | Déclare la classe comme entité JPA |
| `@Table(name = "...")` | Spécifie le nom de la table |
| `@Inheritance(strategy = InheritanceType.JOINED)` | Héritage avec tables séparées |
| `@Id` | Clé primaire |
| `@GeneratedValue(strategy = GenerationType.IDENTITY)` | Auto-incrément |
| `@Column` | Mapping colonne avec contraintes |
| `@Enumerated(EnumType.STRING)` | Stockage enum en texte |

### 5.2 `model.Etudiant` (Sous-classe)

```java
package model;

import jakarta.persistence.*;

/**
 * Sous-classe représentant un étudiant.
 * Hérite de Utilisateur avec table jointe.
 */
@Entity
@Table(name = "etudiants")
@PrimaryKeyJoinColumn(name = "utilisateur_id")
public class Etudiant extends Utilisateur {

    @Column
    private String filiere;

    @Column(name = "numero_etudiant")
    private String numeroEtudiant;

    @Column(name = "nb_absences")
    private int nbAbsences = 0;

    @Column(name = "a_supprimer")
    private boolean aSupprimer = false;

    // Getters & Setters...
}
```

### 5.3 `model.TravailPratique` (avec versioning)

```java
package model;

import jakarta.persistence.*;
import java.util.Date;
import java.util.List;

/**
 * Entité représentant un travail pratique soumis par un étudiant.
 * Supporte le versioning via le champ parent.
 */
@Entity
@Table(name = "travaux_pratiques")
public class TravailPratique {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titre;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "chemin_fichier")
    private String cheminFichier;

    @Column(name = "nom_fichier")
    private String nomFichier;

    @Column
    private int version = 1;

    @Enumerated(EnumType.STRING)
    @Column
    private Statut statut = Statut.SOUMIS;

    @Column
    private Double note;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "date_soumission")
    private Date dateSoumission;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "date_limite")
    private Date dateLimite;

    // Relations
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "etudiant_id")
    private Etudiant etudiant;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "module_id")
    private Module module;

    // VERSIONING : Référence à la version parente
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private TravailPratique parent;

    // Commentaires avec cascade
    @OneToMany(mappedBy = "travail", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Commentaire> commentaires;

    @PrePersist
    protected void onCreate() {
        dateSoumission = new Date();
    }

    public enum Statut { SOUMIS, EN_CORRECTION, CORRIGE, RENDU }

    // Getters & Setters incluant getParent() / setParent()
}
```

**Annotations de relation :**
| Annotation | Usage |
|------------|-------|
| `@ManyToOne` | Relation N:1 |
| `@OneToMany` | Relation 1:N |
| `@JoinColumn` | Colonne de jointure |
| `fetch = FetchType.LAZY` | Chargement à la demande |
| `fetch = FetchType.EAGER` | Chargement immédiat |
| `cascade = CascadeType.ALL` | Propagation des opérations |
| `@PrePersist` | Callback avant insertion |

---

## 6. DAOs — Méthodes et requêtes JPQL

### 6.1 Pattern DAO utilisé

```java
/**
 * Patron de conception DAO (Data Access Object).
 * Encapsule l'accès aux données et les requêtes JPQL.
 */
public class ExempleDAO {
    
    public Entity findById(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(Entity.class, id);
        } finally {
            em.close();  // IMPORTANT : toujours fermer
        }
    }

    public void save(Entity entity) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            em.getTransaction().begin();
            em.persist(entity);
            em.getTransaction().commit();
        } catch (Exception e) {
            em.getTransaction().rollback();
            throw e;
        } finally {
            em.close();
        }
    }
}
```

### 6.2 `UtilisateurDAO` — Authentification

```java
package dao;

/**
 * DAO pour la gestion des utilisateurs.
 */
public class UtilisateurDAO {

    /**
     * Authentifie un utilisateur par email et mot de passe.
     * Compatible avec les formats PBKDF2 (nouveau) et SHA-256 (legacy).
     * 
     * @param email Email de l'utilisateur
     * @param password Mot de passe en clair
     * @return Utilisateur authentifié ou null
     */
    public Utilisateur authenticate(String email, String password) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Utilisateur> list = em.createQuery(
                "SELECT u FROM Utilisateur u WHERE u.email = :email",
                Utilisateur.class
            )
            .setParameter("email", email)
            .getResultList();

            if (list.isEmpty()) return null;
            
            Utilisateur user = list.get(0);
            if (PasswordUtil.verify(password, user.getMotDePasse())) {
                AppLogger.info("UtilisateurDAO", "Authentification réussie: " + email);
                return user;
            }
            
            AppLogger.warn("UtilisateurDAO", "Mot de passe incorrect: " + email);
            return null;
        } finally {
            em.close();
        }
    }

    /**
     * Recherche les utilisateurs par rôle.
     */
    public List<Utilisateur> findByRole(Utilisateur.Role role) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT u FROM Utilisateur u WHERE u.role = :role",
                Utilisateur.class
            )
            .setParameter("role", role)
            .getResultList();
        } finally {
            em.close();
        }
    }
}
```

### 6.3 `TravailPratiqueDAO` — Versioning

```java
package dao;

/**
 * DAO pour les travaux pratiques avec gestion du versioning.
 */
public class TravailPratiqueDAO {

    /**
     * Récupère l'historique complet des versions d'un TP.
     * Remonte à la version racine puis récupère toutes les versions.
     * 
     * @param tpId ID d'une version quelconque du TP
     * @return Liste des versions ordonnées par numéro de version
     */
    public List<TravailPratique> findVersionHistory(Long tpId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TravailPratique tp = em.find(TravailPratique.class, tpId);
            if (tp == null) {
                AppLogger.debug("TravailPratiqueDAO", "TP non trouvé: " + tpId);
                return Collections.emptyList();
            }

            // Remonter jusqu'à la version racine (version 1)
            TravailPratique root = tp;
            while (root.getParent() != null) {
                root = root.getParent();
            }

            // Récupérer toutes les versions par titre, étudiant et module
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "WHERE t.etudiant.id = :etudiantId " +
                "AND t.module.id = :moduleId " +
                "AND t.titre = :titre " +
                "ORDER BY t.version ASC",
                TravailPratique.class
            )
            .setParameter("etudiantId", root.getEtudiant().getId())
            .setParameter("moduleId", root.getModule().getId())
            .setParameter("titre", root.getTitre())
            .getResultList();
        } finally {
            em.close();
        }
    }

    /**
     * Trouve la version racine (version 1) d'un TP.
     */
    public TravailPratique findRootVersion(Long tpId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TravailPratique tp = em.find(TravailPratique.class, tpId);
            if (tp == null) return null;
            
            while (tp.getParent() != null) {
                tp = tp.getParent();
            }
            return tp;
        } finally {
            em.close();
        }
    }

    /**
     * Recherche les TP d'un étudiant avec filtre optionnel par statut.
     */
    public List<TravailPratique> findByEtudiant(Long etudiantId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                "SELECT t FROM TravailPratique t " +
                "WHERE t.etudiant.id = :etudiantId " +
                "ORDER BY t.dateSoumission DESC",
                TravailPratique.class
            )
            .setParameter("etudiantId", etudiantId)
            .getResultList();
        } finally {
            em.close();
        }
    }
}
```

### 6.4 Tableau des méthodes DAO

| DAO | Méthode | Requête JPQL |
|-----|---------|--------------|
| `UtilisateurDAO` | `authenticate(email, password)` | `SELECT u FROM Utilisateur u WHERE u.email = :email` |
| `UtilisateurDAO` | `findByRole(role)` | `SELECT u FROM Utilisateur u WHERE u.role = :role` |
| `EtudiantDAO` | `findByFiliere(filiere)` | `SELECT e FROM Etudiant e WHERE e.filiere = :filiere` |
| `EtudiantDAO` | `search(keyword)` | `WHERE LOWER(e.nom) LIKE :kw OR LOWER(e.prenom) LIKE :kw` |
| `TravailPratiqueDAO` | `findVersionHistory(tpId)` | Voir code ci-dessus |
| `TravailPratiqueDAO` | `findByEtudiant(id)` | `WHERE t.etudiant.id = :id ORDER BY t.dateSoumission DESC` |
| `NotificationDAO` | `countNonLues(userId)` | `SELECT COUNT(n) FROM Notification n WHERE n.destinataire.id = :id AND n.lue = false` |
| `RapportDAO` | `findByModuleIds(ids)` | `WHERE r.module.id IN :ids` |

---

## 7. Servlets — Annotations et URLs

### 7.1 Tableau complet des servlets

| Classe | URL | Annotation | Rôle |
|--------|-----|------------|------|
| **Authentification** |
| `servlet.LoginServlet` | `/LoginServlet` | `@WebServlet` | Formulaire login, authentification |
| `servlet.LogoutServlet` | `/LogoutServlet` | `@WebServlet` | Déconnexion, invalidation session |
| **Admin** |
| `servlet.admin.DashboardServlet` | `/admin/DashboardServlet` | `@WebServlet` | Tableau de bord admin |
| `servlet.admin.ModuleServlet` | `/admin/ModuleServlet` | `@WebServlet` | CRUD modules |
| `servlet.admin.EnseignantServlet` | `/admin/EnseignantServlet` | `@WebServlet` | CRUD enseignants |
| `servlet.admin.EtudiantServlet` | `/admin/EtudiantServlet` | `@WebServlet` | CRUD étudiants |
| `servlet.admin.MessageServlet` | `/admin/MessageServlet` | `@WebServlet` | Messagerie admin |
| `servlet.admin.CheckNonRemisServlet` | `/admin/CheckNonRemisServlet` | `@WebServlet` | Vérification TP non rendus |
| **Enseignant** |
| `servlet.enseignant.DashboardServlet` | `/enseignant/DashboardServlet` | `@WebServlet` | Tableau de bord enseignant |
| `servlet.enseignant.RapportServlet` | `/enseignant/RapportServlet` | `@WebServlet` + `@MultipartConfig` | Upload rapports/supports |
| `servlet.enseignant.CorrectionTPServlet` | `/enseignant/CorrectionTPServlet` | `@WebServlet` | Correction et notation des TP |
| `servlet.enseignant.AbsenceServlet` | `/enseignant/AbsenceServlet` | `@WebServlet` | Gestion des absences |
| `servlet.enseignant.MessageServlet` | `/enseignant/MessageServlet` | `@WebServlet` | Messagerie enseignant |
| **Étudiant** |
| `servlet.etudiant.DashboardServlet` | `/etudiant/DashboardServlet` | `@WebServlet` | Tableau de bord étudiant |
| `servlet.etudiant.DepotTPServlet` | `/etudiant/DepotTPServlet` | `@WebServlet` + `@MultipartConfig` | Dépôt TP avec **versioning** |
| `servlet.etudiant.MessageServlet` | `/etudiant/MessageServlet` | `@WebServlet` | Messagerie étudiant |
| **API REST** |
| `servlet.api.AbsenceReportApiServlet` | `/api/absence` | `@WebServlet` | Signalement absence (POST) |
| `servlet.api.AlerteDepassementApiServlet` | `/api/alerte-depassement` | `@WebServlet` | Réception alerte dépassement |
| `servlet.api.NonRendusApiServlet` | `/api/non-rendus` | `@WebServlet` | Liste TP non rendus (GET) |

### 7.2 Annotation `@MultipartConfig`

```java
@WebServlet("/etudiant/DepotTPServlet")
@MultipartConfig(
    maxFileSize    = 10 * 1024 * 1024,  // 10 Mo par fichier
    maxRequestSize = 15 * 1024 * 1024   // 15 Mo par requête
)
public class DepotTPServlet extends HttpServlet {
    // ...
}
```

---

## 8. Classes utilitaires

### 8.1 `util.PasswordUtil` — Hashage des mots de passe (MISE À JOUR)

```java
package util;

/**
 * Utilitaire de hashage des mots de passe.
 * 
 * NOUVEAU : Utilise PBKDF2 (via BCryptUtil) pour les nouveaux mots de passe.
 * Maintient la compatibilité avec l'ancien format SHA-256.
 * 
 * Migration progressive :
 * - Les nouveaux hash utilisent PBKDF2 (plus sécurisé)
 * - Les anciens hash SHA-256 restent vérifiables
 */
public final class PasswordUtil {

    private static final String SALT = "EtudAcadPro#2025";
    private static final boolean USE_NEW_ALGORITHM = true;

    /**
     * Hash un mot de passe avec l'algorithme le plus sécurisé (PBKDF2).
     * Format : $PBKDF2$10000$<salt_base64>$<hash_base64>
     */
    public static String hash(String password) {
        if (password == null) return null;
        
        if (USE_NEW_ALGORITHM) {
            String newHash = BCryptUtil.hash(password);
            AppLogger.debug("PasswordUtil", "Nouveau hash PBKDF2 généré");
            return newHash;
        }
        
        return hashSha256(password);
    }

    /**
     * Vérifie un mot de passe contre un hash stocké.
     * Compatible avec tous les formats :
     * - PBKDF2 (nouveau format, commence par $PBKDF2$)
     * - SHA-256 (ancien format, 64 caractères hex)
     * - Texte clair (très ancien, pour migration)
     */
    public static boolean verify(String inputPassword, String stored) {
        if (inputPassword == null || stored == null) return false;
        
        // Nouveau format PBKDF2
        if (BCryptUtil.isNewFormat(stored)) {
            return BCryptUtil.verify(inputPassword, stored);
        }
        
        // Ancien format SHA-256
        if (stored.length() == 64 && stored.matches("[0-9a-fA-F]+")) {
            return stored.equalsIgnoreCase(hashSha256(inputPassword));
        }
        
        // Texte clair (migration)
        return stored.equals(inputPassword);
    }

    /**
     * Indique si un hash doit être mis à jour vers le nouveau format.
     */
    public static boolean needsRehash(String storedHash) {
        return BCryptUtil.needsRehash(storedHash);
    }
}
```

### 8.2 `util.BCryptUtil` — Hashage PBKDF2 sécurisé (NOUVEAU)

```java
package util;

/**
 * Utilitaire de hachage de mots de passe basé sur PBKDF2.
 * Plus sécurisé que SHA-256 simple car :
 * - Sel unique par mot de passe (stocké avec le hash)
 * - 10000 itérations pour ralentir les attaques
 * - Format auto-contenu : $PBKDF2$iterations$salt$hash
 */
public final class BCryptUtil {

    private static final int ITERATIONS = 10000;
    private static final int SALT_LENGTH = 16;
    private static final int HASH_LENGTH = 32;
    private static final String PREFIX = "$PBKDF2$";
    
    private static final SecureRandom RANDOM = new SecureRandom();

    /**
     * Hash un mot de passe avec un sel unique généré aléatoirement.
     * 
     * @param password Le mot de passe en clair
     * @return Le hash au format $PBKDF2$iterations$salt$hash
     */
    public static String hash(String password) {
        if (password == null || password.isEmpty()) return null;

        byte[] salt = new byte[SALT_LENGTH];
        RANDOM.nextBytes(salt);

        byte[] hash = pbkdf2(password, salt, ITERATIONS);
        
        String saltBase64 = Base64.getEncoder().encodeToString(salt);
        String hashBase64 = Base64.getEncoder().encodeToString(hash);
        
        return PREFIX + ITERATIONS + "$" + saltBase64 + "$" + hashBase64;
    }

    /**
     * Vérifie qu'un mot de passe correspond au hash stocké.
     * Utilise une comparaison en temps constant pour éviter les attaques timing.
     */
    public static boolean verify(String password, String storedHash) {
        if (password == null || storedHash == null) return false;

        if (storedHash.startsWith(PREFIX)) {
            return verifyPbkdf2(password, storedHash);
        }
        
        // Fallback vers ancien format
        return PasswordUtil.verify(password, storedHash);
    }

    /**
     * Vérifie si un hash est au nouveau format PBKDF2.
     */
    public static boolean isNewFormat(String storedHash) {
        return storedHash != null && storedHash.startsWith(PREFIX);
    }

    /**
     * Comparaison en temps constant pour éviter les attaques timing.
     */
    private static boolean constantTimeEquals(byte[] a, byte[] b) {
        if (a.length != b.length) return false;
        int result = 0;
        for (int i = 0; i < a.length; i++) {
            result |= a[i] ^ b[i];
        }
        return result == 0;
    }
}
```

### 8.3 `util.HtmlUtil` — Protection XSS

```java
package util;

/**
 * Utilitaires d'échappement HTML/JavaScript pour prévenir les attaques XSS.
 */
public class HtmlUtil {

    /**
     * Échappe les caractères HTML dangereux.
     * Remplace: & < > " ' par leurs entités HTML.
     * 
     * @param input Chaîne à échapper
     * @return Chaîne sécurisée pour affichage HTML
     */
    public static String escape(String input) {
        if (input == null) return "";
        StringBuilder escaped = new StringBuilder(input.length() * 2);
        for (char c : input.toCharArray()) {
            switch (c) {
                case '&':  escaped.append("&amp;");  break;
                case '<':  escaped.append("&lt;");   break;
                case '>':  escaped.append("&gt;");   break;
                case '"':  escaped.append("&quot;"); break;
                case '\'': escaped.append("&#x27;"); break;
                default:   escaped.append(c);
            }
        }
        return escaped.toString();
    }

    /**
     * Échappe pour utilisation dans un attribut HTML.
     */
    public static String escapeAttr(String input) {
        return escape(input);
    }

    /**
     * Échappe pour utilisation dans du JavaScript inline.
     * Sécurise les variables injectées dans des scripts.
     */
    public static String escapeJs(String input) {
        if (input == null) return "";
        StringBuilder escaped = new StringBuilder(input.length() * 2);
        for (char c : input.toCharArray()) {
            switch (c) {
                case '\\': escaped.append("\\\\"); break;
                case '\'': escaped.append("\\'");  break;
                case '"':  escaped.append("\\\""); break;
                case '\n': escaped.append("\\n");  break;
                case '\r': escaped.append("\\r");  break;
                case '<':  escaped.append("\\u003c"); break;
                case '>':  escaped.append("\\u003e"); break;
                default:   escaped.append(c);
            }
        }
        return escaped.toString();
    }
}
```

### 8.4 `util.InputValidator` — Validation des entrées

```java
package util;

/**
 * Validation et sanitisation des entrées utilisateur.
 * À utiliser côté serveur pour toutes les données reçues.
 */
public class InputValidator {

    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    
    private static final Pattern ALPHANUMERIC_PATTERN = 
        Pattern.compile("^[A-Za-zÀ-ÿ\\s\\-']+$");
    
    private static final Pattern NUMERIC_PATTERN = 
        Pattern.compile("^\\d+$");

    /**
     * Valide un format email.
     */
    public static boolean isValidEmail(String email) {
        return email != null && EMAIL_PATTERN.matcher(email).matches();
    }

    /**
     * Valide un nom (lettres, espaces, tirets, apostrophes).
     */
    public static boolean isValidName(String name) {
        return name != null && !name.trim().isEmpty() 
            && ALPHANUMERIC_PATTERN.matcher(name).matches();
    }

    /**
     * Vérifie si une chaîne est numérique.
     */
    public static boolean isNumeric(String str) {
        return str != null && NUMERIC_PATTERN.matcher(str).matches();
    }

    /**
     * Parse un ID de manière sécurisée.
     * @return L'ID parsé ou null si invalide
     */
    public static Long parseId(String idStr) {
        if (idStr == null || idStr.trim().isEmpty()) return null;
        try {
            return Long.parseLong(idStr.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Nettoie une chaîne (trim + suppression espaces multiples).
     */
    public static String sanitize(String input) {
        if (input == null) return null;
        return input.trim().replaceAll("\\s+", " ");
    }

    /**
     * Valide un mot de passe (minimum 6 caractères).
     */
    public static boolean isValidPassword(String password) {
        return password != null && password.length() >= 6;
    }

    /**
     * Vérifie qu'une chaîne n'est pas vide.
     */
    public static boolean isNotEmpty(String input) {
        return input != null && !input.trim().isEmpty();
    }
}
```

### 8.5 `util.FileUploadUtil` — Gestion des fichiers

```java
package util;

/**
 * Utilitaire pour la gestion sécurisée des uploads de fichiers.
 */
public class FileUploadUtil {

    private static final long TAILLE_MAX = 10 * 1024 * 1024; // 10 Mo
    private static final String BASE_DIR = System.getProperty("user.home") + "/tp_uploads";
    
    private static final Set<String> EXTENSIONS_AUTORISEES = Set.of(
        "pdf", "doc", "docx", "zip", "rar", "java", "py", "txt", "png", "jpg", "jpeg"
    );

    /**
     * Sauvegarde un fichier uploadé de manière sécurisée.
     * 
     * @param part Le Part du fichier multipart
     * @param etudiantId ID de l'étudiant (pour sous-dossier)
     * @return Chemin relatif du fichier sauvegardé
     * @throws IOException Si le fichier est refusé ou erreur d'écriture
     */
    public static String sauvegarder(Part part, Long etudiantId) throws IOException {
        String nomOriginal = extraireNomFichier(part);
        String extension = getExtension(nomOriginal);
        
        // Vérification extension
        if (!EXTENSIONS_AUTORISEES.contains(extension.toLowerCase())) {
            throw new IOException("Extension non autorisée: " + extension);
        }
        
        // Vérification taille
        if (part.getSize() > TAILLE_MAX) {
            throw new IOException("Fichier trop volumineux (max 10 Mo)");
        }
        
        // Génération nom unique avec UUID
        String nomUnique = UUID.randomUUID().toString() + "_" + nomOriginal;
        String sousRepertoire = "etudiant_" + etudiantId;
        
        File dossier = new File(BASE_DIR, sousRepertoire);
        if (!dossier.exists()) {
            dossier.mkdirs();
        }
        
        File fichier = new File(dossier, nomUnique);
        try (InputStream is = part.getInputStream();
             FileOutputStream fos = new FileOutputStream(fichier)) {
            is.transferTo(fos);
        }
        
        AppLogger.info("FileUploadUtil", "Fichier sauvegardé: " + fichier.getPath());
        return sousRepertoire + "/" + nomUnique;
    }

    /**
     * Supprime un fichier du disque.
     */
    public static void supprimer(String cheminRelatif) {
        if (cheminRelatif == null) return;
        File fichier = new File(BASE_DIR, cheminRelatif);
        if (fichier.exists() && fichier.delete()) {
            AppLogger.info("FileUploadUtil", "Fichier supprimé: " + cheminRelatif);
        }
    }

    public static long getTailleMax() {
        return TAILLE_MAX;
    }
}
```

---

## 9. Système de sécurité complet

### 9.1 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SÉCURITÉ MULTI-COUCHES                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 1 : TRANSPORT (HTTPS recommandé en production)                  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 2 : EN-TÊTES HTTP (SecurityFilter)                              │   │
│  │  • X-Frame-Options: SAMEORIGIN                                          │   │
│  │  • X-Content-Type-Options: nosniff                                      │   │
│  │  • Content-Security-Policy                                              │   │
│  │  • Cache-Control: no-store                                              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 3 : AUTHENTIFICATION API (ApiKeyFilter)                         │   │
│  │  • Vérification X-API-Key header                                        │   │
│  │  • IP whitelist pour localhost                                          │   │
│  │  • Logging des accès refusés                                            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 4 : AUTHENTIFICATION UTILISATEUR (AuthFilter)                   │   │
│  │  • Vérification session                                                 │   │
│  │  • Vérification rôle (ADMIN, ENSEIGNANT, ETUDIANT)                      │   │
│  │  • Redirection si non autorisé                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 5 : VALIDATION ENTRÉES (InputValidator + Servlets)              │   │
│  │  • Validation format (email, nom, ID)                                   │   │
│  │  • Sanitisation des chaînes                                             │   │
│  │  • Vérification taille fichiers                                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 6 : PROTECTION SQL (JPA + JPQL paramétré)                       │   │
│  │  • Requêtes paramétrées (:email, :id)                                   │   │
│  │  • Pas de concaténation SQL                                             │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 7 : PROTECTION XSS (HtmlUtil + JSTL)                            │   │
│  │  • HtmlUtil.escape() pour scriptlets                                    │   │
│  │  • <c:out> pour JSTL                                                    │   │
│  │  • HtmlUtil.escapeJs() pour JavaScript inline                           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  COUCHE 8 : HASHAGE MOTS DE PASSE (BCryptUtil / PasswordUtil)           │   │
│  │  • PBKDF2 avec sel unique (nouveau)                                     │   │
│  │  • 10000 itérations                                                     │   │
│  │  • Compatible SHA-256 legacy                                            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Protection contre les injections SQL

**Méthode** : Requêtes paramétrées JPA (JPQL)

```java
// ✅ SÉCURISÉ : paramètre bindé, impossible d'injecter du SQL
em.createQuery("SELECT e FROM Etudiant e WHERE LOWER(e.nom) LIKE :kw")
  .setParameter("kw", "%" + keyword.toLowerCase() + "%")
  .getResultList();

// ✅ SÉCURISÉ : find() utilise l'ID directement
em.find(Etudiant.class, etudiantId);

// ❌ VULNÉRABLE (jamais utilisé dans l'application)
em.createQuery("SELECT e FROM Etudiant e WHERE e.nom = '" + nom + "'")
```

### 9.3 Protection contre XSS

| Technique | Usage | Exemple |
|-----------|-------|---------|
| **JSTL `<c:out>`** | Valeurs dans JSP | `<c:out value="${erreur}"/>` |
| **HtmlUtil.escape()** | Scriptlets | `<%= HtmlUtil.escape(user.getNom()) %>` |
| **HtmlUtil.escapeJs()** | JavaScript inline | `var x = '<%= HtmlUtil.escapeJs(val) %>';` |
| **CSP Header** | Politique globale | `script-src 'self' ...` |

### 9.4 Hashage des mots de passe (PBKDF2)

| Caractéristique | Valeur |
|-----------------|--------|
| Algorithme | PBKDF2 avec SHA-256 |
| Itérations | 10 000 |
| Longueur sel | 16 bytes (aléatoire unique) |
| Longueur hash | 32 bytes |
| Format stocké | `$PBKDF2$10000$<sel_base64>$<hash_base64>` |
| Compatibilité | SHA-256 legacy (64 caractères hex) |

---

## 10. Authentification et filtres

### 10.1 `util.SecurityFilter` — En-têtes HTTP

```java
package util;

/**
 * Filtre ajoutant les en-têtes de sécurité HTTP à toutes les réponses.
 * Appliqué sur toutes les URLs (/*).
 */
@WebFilter("/*")
public class SecurityFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Protection contre le clickjacking
        httpResponse.setHeader("X-Frame-Options", "SAMEORIGIN");

        // Protection contre le MIME sniffing
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");

        // Protection XSS du navigateur
        httpResponse.setHeader("X-XSS-Protection", "1; mode=block");

        // Content Security Policy (CSP)
        httpResponse.setHeader("Content-Security-Policy",
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com; " +
            "style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; " +
            "img-src 'self' data:; " +
            "connect-src 'self'; " +
            "frame-ancestors 'self';"
        );

        // Désactivation du cache pour pages sensibles
        httpResponse.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        httpResponse.setHeader("Pragma", "no-cache");

        // Politique de referrer
        httpResponse.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

        chain.doFilter(request, response);
    }
}
```

### 10.2 `util.AuthFilter` — Authentification et rôles (MISE À JOUR)

```java
package util;

/**
 * Filtre d'authentification étendu.
 * Protège les URLs /vues/*, /admin/*, /enseignant/*, /etudiant/*
 * avec vérification du rôle approprié.
 */
@WebFilter(urlPatterns = {"/vues/*", "/admin/*", "/enseignant/*", "/etudiant/*"})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);
        String path = request.getServletPath();

        Utilisateur user = (session != null) 
            ? (Utilisateur) session.getAttribute("utilisateur") 
            : null;

        // Vérification authentification
        if (user == null) {
            AppLogger.warn("AuthFilter", "Accès non authentifié à " + path);
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        // Vérification rôle
        if (!isAuthorized(user, path)) {
            AppLogger.warn("AuthFilter", "Accès non autorisé: " + user.getEmail() + " vers " + path);
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Accès non autorisé pour votre rôle.");
            return;
        }

        chain.doFilter(req, res);
    }

    /**
     * Vérifie si l'utilisateur a le rôle requis pour accéder au chemin.
     */
    private boolean isAuthorized(Utilisateur user, String path) {
        if (path == null) return true;
        
        Utilisateur.Role role = user.getRole();
        
        // URLs admin : ADMIN uniquement
        if (path.startsWith("/admin/") || path.contains("/admin/")) {
            return role == Utilisateur.Role.ADMIN;
        }
        
        // URLs enseignant : ENSEIGNANT ou ADMIN
        if (path.startsWith("/enseignant/") || path.contains("/enseignant/")) {
            return role == Utilisateur.Role.ENSEIGNANT || role == Utilisateur.Role.ADMIN;
        }
        
        // URLs étudiant : ETUDIANT ou ADMIN
        if (path.startsWith("/etudiant/") || path.contains("/etudiant/")) {
            return role == Utilisateur.Role.ETUDIANT || role == Utilisateur.Role.ADMIN;
        }
        
        return true;
    }
}
```

### 10.3 `util.ApiKeyFilter` — Authentification API (NOUVEAU)

```java
package util;

/**
 * Filtre de sécurité pour les API REST.
 * Vérifie la présence et la validité d'une clé API.
 * 
 * Authentification via :
 * - Header HTTP : X-API-Key: <clé>
 * - Paramètre URL : ?apiKey=<clé>
 * 
 * Configuration dans web.xml :
 * - api.key : clé(s) API valide(s), séparées par virgule
 * - api.key.enabled : true/false pour activer/désactiver
 * - api.allowed.ips : liste d'IPs autorisées (optionnel)
 */
@WebFilter("/api/*")
public class ApiKeyFilter implements Filter {

    private static final String HEADER_API_KEY = "X-API-Key";
    private static final String PARAM_API_KEY = "apiKey";
    
    private Set<String> validApiKeys = new HashSet<>();
    private Set<String> allowedIps = new HashSet<>();
    private boolean enabled = true;

    @Override
    public void init(FilterConfig config) throws ServletException {
        ServletContext ctx = config.getServletContext();
        
        // Lecture configuration
        String enabledParam = ctx.getInitParameter("api.key.enabled");
        if (enabledParam != null) {
            enabled = Boolean.parseBoolean(enabledParam);
        }
        
        // Clés API valides
        String apiKeys = ctx.getInitParameter("api.key");
        if (apiKeys != null && !apiKeys.isBlank()) {
            for (String key : apiKeys.split(",")) {
                validApiKeys.add(key.trim());
            }
        }
        
        // IPs autorisées sans clé
        String allowedIpsParam = ctx.getInitParameter("api.allowed.ips");
        if (allowedIpsParam != null && !allowedIpsParam.isBlank()) {
            for (String ip : allowedIpsParam.split(",")) {
                allowedIps.add(ip.trim());
            }
        }
        
        AppLogger.info("ApiKeyFilter", "Initialisé [enabled=" + enabled + 
            ", keys=" + validApiKeys.size() + "]");
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        
        // OPTIONS toujours autorisé (CORS preflight)
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            chain.doFilter(req, res);
            return;
        }
        
        // Filtre désactivé
        if (!enabled) {
            chain.doFilter(req, res);
            return;
        }
        
        String clientIp = getClientIp(request);
        
        // IP whitelist
        if (allowedIps.contains(clientIp) || allowedIps.contains("127.0.0.1") 
                && (clientIp.equals("localhost") || clientIp.equals("0:0:0:0:0:0:0:1"))) {
            chain.doFilter(req, res);
            return;
        }
        
        // Vérification clé API
        String apiKey = request.getHeader(HEADER_API_KEY);
        if (apiKey == null || apiKey.isBlank()) {
            apiKey = request.getParameter(PARAM_API_KEY);
        }
        
        if (apiKey == null || apiKey.isBlank()) {
            AppLogger.logSecurity("API_ACCESS_DENIED", "Clé API manquante [ip=" + clientIp + "]");
            sendUnauthorized(response, "Clé API requise");
            return;
        }
        
        if (!validApiKeys.contains(apiKey)) {
            AppLogger.logSecurity("API_INVALID_KEY", "Clé API invalide [ip=" + clientIp + "]");
            sendUnauthorized(response, "Clé API invalide");
            return;
        }
        
        chain.doFilter(req, res);
    }

    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.getWriter().print("{\"success\":false,\"error\":\"" + message + "\",\"code\":401}");
    }
}
```

### 10.4 Configuration `web.xml` (MISE À JOUR)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee 
         http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">

    <display-name>MiniProjet-BE4</display-name>

    <!-- ==================== CONFIGURATION GÉNÉRALE ==================== -->
    
    <!-- URL du système externe AbsTrack -->
    <context-param>
        <param-name>absence.system.url</param-name>
        <param-value>http://localhost:8081/AbsTrack</param-value>
    </context-param>

    <!-- ==================== CONFIGURATION SÉCURITÉ API ==================== -->
    
    <!-- Activer/désactiver l'authentification API -->
    <context-param>
        <param-name>api.key.enabled</param-name>
        <param-value>true</param-value>
    </context-param>
    
    <!-- Clé(s) API valide(s), séparées par virgule 
         IMPORTANT: Changer ces clés en production! -->
    <context-param>
        <param-name>api.key</param-name>
        <param-value>EtudAcadPro-API-2025-SecretKey,AbsTrack-Integration-Key</param-value>
    </context-param>
    
    <!-- IPs autorisées sans clé API (localhost par défaut) -->
    <context-param>
        <param-name>api.allowed.ips</param-name>
        <param-value>127.0.0.1</param-value>
    </context-param>

    <!-- ==================== FILTRES ==================== -->
    
    <!-- Filtre d'authentification utilisateurs -->
    <filter>
        <filter-name>AuthFilter</filter-name>
        <filter-class>util.AuthFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>AuthFilter</filter-name>
        <url-pattern>/vues/*</url-pattern>
    </filter-mapping>
    <filter-mapping>
        <filter-name>AuthFilter</filter-name>
        <url-pattern>/admin/*</url-pattern>
    </filter-mapping>
    <filter-mapping>
        <filter-name>AuthFilter</filter-name>
        <url-pattern>/enseignant/*</url-pattern>
    </filter-mapping>
    <filter-mapping>
        <filter-name>AuthFilter</filter-name>
        <url-pattern>/etudiant/*</url-pattern>
    </filter-mapping>

    <!-- Page d'accueil -->
    <welcome-file-list>
        <welcome-file>index.jsp</welcome-file>
    </welcome-file-list>
</web-app>
```

---

## 11. Logger centralisé (NOUVEAU)

### 11.1 `util.AppLogger` — Système de logging

```java
package util;

/**
 * Logger centralisé pour l'application EtudAcadPro.
 * Écrit les logs dans un fichier et dans la console.
 * 
 * Niveaux de log : DEBUG, INFO, WARN, ERROR
 * 
 * Utilisation :
 *   AppLogger.info("MonServlet", "Action effectuée");
 *   AppLogger.error("MonDAO", "Erreur de connexion", exception);
 */
public final class AppLogger {

    public enum Level { DEBUG, INFO, WARN, ERROR }

    private static final String LOG_DIR = System.getProperty("user.home") + "/etudacadpro_logs";
    private static final String LOG_FILE = LOG_DIR + "/application.log";
    
    private static Level minLevel = Level.INFO;

    /**
     * Log niveau DEBUG (détails techniques).
     */
    public static void debug(String source, String message) {
        log(Level.DEBUG, source, message, null);
    }

    /**
     * Log niveau INFO (événements normaux).
     */
    public static void info(String source, String message) {
        log(Level.INFO, source, message, null);
    }

    /**
     * Log niveau WARN (avertissements).
     */
    public static void warn(String source, String message) {
        log(Level.WARN, source, message, null);
    }

    /**
     * Log niveau ERROR avec exception.
     */
    public static void error(String source, String message, Throwable throwable) {
        log(Level.ERROR, source, message, throwable);
    }

    /**
     * Log un événement de sécurité.
     */
    public static void logSecurity(String event, String details) {
        warn("SECURITY", event + " - " + details);
    }

    /**
     * Log une requête HTTP (pour débogage).
     */
    public static void logRequest(String servlet, String method, String path, String user) {
        debug(servlet, String.format("%s %s [user=%s]", method, path, 
            user != null ? user : "anonymous"));
    }

    private static void log(Level level, String source, String message, Throwable throwable) {
        if (level.ordinal() < minLevel.ordinal()) return;

        String timestamp = LocalDateTime.now().format(
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS"));
        String formattedMessage = String.format("[%s] [%s] [%s] %s",
            timestamp, level.name(), source, message);

        // Console
        System.out.println(formattedMessage);
        if (throwable != null) {
            throwable.printStackTrace(System.out);
        }

        // Fichier
        writeToFile(formattedMessage, throwable);
    }

    private static synchronized void writeToFile(String message, Throwable throwable) {
        try (PrintWriter writer = new PrintWriter(new FileWriter(LOG_FILE, true))) {
            writer.println(message);
            if (throwable != null) {
                throwable.printStackTrace(writer);
            }
        } catch (IOException e) {
            System.err.println("Erreur d'écriture log: " + e.getMessage());
        }
    }
}
```

### 11.2 Exemples d'utilisation

```java
// Dans un servlet
AppLogger.info("LoginServlet", "Connexion réussie: " + user.getEmail());
AppLogger.warn("DepotTPServlet", "Tentative de dépôt après deadline");

// Dans un DAO
AppLogger.debug("EtudiantDAO", "Recherche étudiant id=" + id);
AppLogger.error("TravailPratiqueDAO", "Erreur sauvegarde TP", exception);

// Événements de sécurité
AppLogger.logSecurity("LOGIN_FAILED", "Email: " + email + ", IP: " + ip);
AppLogger.logSecurity("API_ACCESS_DENIED", "Clé invalide depuis IP: " + ip);
```

### 11.3 Format des logs

```
[2025-02-28 14:32:15.123] [INFO] [LoginServlet] Connexion réussie: etudiant@univ.ma
[2025-02-28 14:32:16.456] [DEBUG] [EtudiantDAO] Recherche étudiant id=42
[2025-02-28 14:33:01.789] [WARN] [SECURITY] API_ACCESS_DENIED - Clé invalide depuis IP: 192.168.1.100
[2025-02-28 14:35:22.012] [ERROR] [TravailPratiqueDAO] Erreur sauvegarde TP
jakarta.persistence.PersistenceException: ...
    at org.hibernate...
```

---

## 12. Gestion des versions des TPs

### 12.1 Fonctionnement

L'application permet aux étudiants de soumettre plusieurs versions d'un TP **avant la date limite**.

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORKFLOW DE VERSIONING                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Étudiant dépose TP initial       → version=1, parent=null   │
│  2. Étudiant clique "Nouvelle version" → version=2, parent=TP1  │
│  3. Étudiant clique "Nouvelle version" → version=3, parent=TP2  │
│  ...                                                             │
│  Date limite atteinte → bouton "Nouvelle version" disparaît      │
└─────────────────────────────────────────────────────────────────┘
```

### 12.2 Interface utilisateur

```
┌─────────────────────────────────────────────────┐
│ 🕐 Historique des versions                  ▼  │
│    3 versions                                   │
├─────────────────────────────────────────────────┤
│ ● Version 1 : 27 Fév                            │
│   TP3-JSP.pdf · 17:33              [Voir]  ⬇   │
│                                                 │
│ ● Version 2 : 27 Fév                            │
│   TP3-JSP-v2.pdf · 18:04           [Voir]  ⬇   │
│                                                 │
│ ● Version 3 : 28 Fév        [Actuelle]          │
│   TP3-final.pdf · 09:15                    ⬇   │
└─────────────────────────────────────────────────┘
```

### 12.3 Code servlet (`DepotTPServlet.java`)

```java
// Lors du dépôt d'une nouvelle version
String tpParentStr = req.getParameter("tpParentId");

int version = 1;
TravailPratique parentTp = null;

if (tpParentStr != null && !tpParentStr.isEmpty()) {
    parentTp = tpDAO.findById(Long.parseLong(tpParentStr));
    if (parentTp != null) {
        version = parentTp.getVersion() + 1;
    }
}

TravailPratique tp = new TravailPratique();
tp.setTitre(titre);
tp.setVersion(version);
tp.setParent(parentTp);  // Lien vers la version précédente
// ...
tpDAO.save(tp);

AppLogger.info("DepotTPServlet", "Nouvelle version déposée: " + titre + " v" + version);
```

---

## 13. Vues JSP — Structure et JSTL

### 13.1 Directives et taglibs

```jsp
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*, java.util.*, util.HtmlUtil" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
```

### 13.2 Sécurisation XSS dans les JSP

```jsp
<!-- JSTL : échappement automatique -->
<c:out value="${erreur}"/>
<input value="<c:out value='${emailValue}'/>"/>

<!-- HtmlUtil : pour scriptlets -->
<h2><%= HtmlUtil.escape(tp.getTitre()) %></h2>
<p><%= HtmlUtil.escape(commentaire.getContenu()) %></p>

<!-- JavaScript inline -->
<script>
var ctx = '<%= HtmlUtil.escapeJs(request.getContextPath()) %>';
var userName = '<%= HtmlUtil.escapeJs(user.getNom()) %>';
</script>
```

### 13.3 Liste des vues

| Chemin | Rôle | Sécurité XSS |
|--------|------|--------------|
| `login.jsp` | Formulaire connexion | JSTL `<c:out>` |
| `notifications.jsp` | Liste notifications | `HtmlUtil.escape()` |
| `admin/messages.jsp` | Messagerie admin | `HtmlUtil.escape()` |
| `enseignant/message.jsp` | Messagerie enseignant | `HtmlUtil.escape()` |
| `etudiant/message.jsp` | Messagerie étudiant | `HtmlUtil.escape()` |
| `etudiant/tp_detail.jsp` | Détail TP + historique | `HtmlUtil.escape()` |

---

## 14. Intégration API avec l'application des absences

### 14.1 Configuration

```xml
<!-- web.xml -->
<context-param>
    <param-name>absence.system.url</param-name>
    <param-value>http://localhost:8081/AbsTrack</param-value>
</context-param>

<!-- Clés API pour l'intégration -->
<context-param>
    <param-name>api.key</param-name>
    <param-value>EtudAcadPro-API-2025-SecretKey,AbsTrack-Integration-Key</param-value>
</context-param>
```

### 14.2 API exposées par EtudAcadPro

| Méthode | URL | Headers | Corps | Réponse |
|---------|-----|---------|-------|---------|
| POST | `/api/absence` | `X-API-Key: <clé>` | `{ "etudiantId": 1, "enseignantId": 2 }` | `{ "success": true }` |
| GET | `/api/non-rendus` | `X-API-Key: <clé>` | — | `[{ "etudiantId": 1, "moduleNom": "..." }]` |
| POST | `/api/alerte-depassement` | `X-API-Key: <clé>` | `{ "emailEtudiant": "...", "nbAbsences": 5 }` | `{ "success": true }` |

### 14.3 CORS et authentification

```java
private void addCors(HttpServletResponse resp) {
    resp.setHeader("Access-Control-Allow-Origin", "*");
    resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    resp.setHeader("Access-Control-Allow-Headers", "Content-Type, X-API-Key");
}
```

### 14.4 Exemple d'appel depuis AbsTrack

```javascript
fetch('http://localhost:8080/EtudAcadPro/api/alerte-depassement', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'AbsTrack-Integration-Key'
    },
    body: JSON.stringify({
        emailEtudiant: 'etudiant@univ.ma',
        nbAbsences: 5
    })
})
.then(response => response.json())
.then(data => console.log(data));
```

---

## 15. Structure complète du projet

```
EtudAcadPro/
├── src/java/
│   ├── dao/
│   │   ├── JPAUtil.java                    ← EntityManager singleton
│   │   ├── UtilisateurDAO.java             ← authenticate(), findByRole()
│   │   ├── EtudiantDAO.java                ← findByFiliere(), search()
│   │   ├── EnseignantDAO.java
│   │   ├── ModuleDAO.java
│   │   ├── RapportDAO.java
│   │   ├── TravailPratiqueDAO.java         ← findVersionHistory() [VERSIONING]
│   │   ├── CommentaireDAO.java
│   │   ├── NotificationDAO.java
│   │   └── AbsenceReportDAO.java
│   │
│   ├── model/
│   │   ├── Utilisateur.java                ← @Entity, @Inheritance(JOINED)
│   │   ├── Enseignant.java                 ← @PrimaryKeyJoinColumn
│   │   ├── Etudiant.java                   ← nbAbsences, aSupprimer
│   │   ├── Module.java
│   │   ├── Rapport.java
│   │   ├── TravailPratique.java            ← parent (versioning)
│   │   ├── Commentaire.java
│   │   ├── Notification.java
│   │   ├── AbsenceReport.java
│   │   ├── FeedItem.java                   ← DTO
│   │   └── NonRemisItem.java               ← DTO
│   │
│   ├── servlet/
│   │   ├── LoginServlet.java
│   │   ├── LogoutServlet.java
│   │   ├── NotificationServlet.java
│   │   ├── RapportDownloadServlet.java
│   │   ├── admin/
│   │   │   ├── DashboardServlet.java
│   │   │   ├── ModuleServlet.java
│   │   │   ├── EnseignantServlet.java
│   │   │   ├── EtudiantServlet.java
│   │   │   ├── MessageServlet.java
│   │   │   └── CheckNonRemisServlet.java
│   │   ├── enseignant/
│   │   │   ├── DashboardServlet.java
│   │   │   ├── RapportServlet.java         ← @MultipartConfig
│   │   │   ├── CorrectionTPServlet.java
│   │   │   ├── AbsenceServlet.java
│   │   │   ├── CommentaireServlet.java
│   │   │   ├── MessageServlet.java
│   │   │   └── SignalerAbsenceTpServlet.java
│   │   ├── etudiant/
│   │   │   ├── DashboardServlet.java
│   │   │   ├── DepotTPServlet.java         ← @MultipartConfig, versioning
│   │   │   └── MessageServlet.java
│   │   └── api/
│   │       ├── AbsenceReportApiServlet.java
│   │       ├── AlerteDepassementApiServlet.java
│   │       └── NonRendusApiServlet.java
│   │
│   └── util/
│       ├── PasswordUtil.java               ← hash() PBKDF2, verify() [UPDATED]
│       ├── BCryptUtil.java                 ← PBKDF2 avec sel unique [NEW]
│       ├── HtmlUtil.java                   ← escape(), escapeJs() [XSS]
│       ├── InputValidator.java             ← validation entrées [NEW]
│       ├── SecurityFilter.java             ← en-têtes HTTP [NEW]
│       ├── AuthFilter.java                 ← session + rôle [UPDATED]
│       ├── ApiKeyFilter.java               ← authentification API [NEW]
│       ├── AppLogger.java                  ← logger centralisé [NEW]
│       ├── FileUploadUtil.java
│       ├── NotificationService.java
│       ├── AbsenceIntegrationService.java
│       └── NonRemisCheckService.java
│
├── web/
│   ├── index.jsp
│   └── WEB-INF/
│       ├── web.xml                         ← api.key, api.allowed.ips [UPDATED]
│       ├── classes/META-INF/persistence.xml
│       └── vues/
│           ├── login.jsp                   ← JSTL <c:out>
│           ├── notifications.jsp           ← HtmlUtil.escape()
│           ├── admin/
│           │   ├── messages.jsp
│           │   └── ... (7 autres JSP)
│           ├── enseignant/
│           │   ├── message.jsp
│           │   └── ... (6 autres JSP)
│           └── etudiant/
│               ├── tp_detail.jsp           ← versioning UI + HtmlUtil
│               ├── message.jsp
│               └── ... (4 autres JSP)
│
├── dist/
│   └── EtudAcadPro.war
├── README.md
└── EVALUATION.md
```

---

## 16. Installation et déploiement

### 16.1 Prérequis

- JDK 17+
- MySQL 8
- WildFly 27+ (ou serveur Jakarta EE compatible)

### 16.2 Base de données

```sql
CREATE DATABASE miniprojet_be4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 16.3 Build et déploiement

1. NetBeans : **Clean and Build** → `dist/EtudAcadPro.war`
2. Copier WAR dans `standalone/deployments/` (WildFly)
3. Accès : `http://localhost:8080/EtudAcadPro/`

### 16.4 Configuration API en production

```xml
<!-- web.xml - À MODIFIER EN PRODUCTION -->
<context-param>
    <param-name>api.key</param-name>
    <param-value>VOTRE-CLE-SECRETE-PRODUCTION</param-value>
</context-param>
```

---

## 17. Auteurs

**Mini-projet Jakarta EE — ELKHARRAF / MANSOURI**

Application de gestion académique avec :
- Gestion des étudiants, enseignants, modules, TP
- **Versioning des TPs** avec historique visuel
- **Sécurité complète** :
  - PBKDF2 pour hashage mots de passe (nouveau)
  - Protection XSS (HtmlUtil, JSTL)
  - Protection SQL Injection (JPA paramétré)
  - En-têtes HTTP sécurisés (SecurityFilter)
  - Authentification API avec clé (ApiKeyFilter)
  - Contrôle d'accès par rôle (AuthFilter étendu)
  - Logger centralisé (AppLogger)
- Intégration API avec l'application de gestion des absences (AbsTrack)
