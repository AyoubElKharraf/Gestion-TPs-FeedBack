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
9. [Sécurité de l'application](#9-sécurité-de-lapplication)
10. [Gestion des versions des TPs](#10-gestion-des-versions-des-tps)
11. [Vues JSP — Structure et JSTL](#11-vues-jsp--structure-et-jstl)
12. [Intégration API avec l'application des absences](#12-intégration-api-avec-lapplication-des-absences)
13. [Structure complète du projet](#13-structure-complète-du-projet)
14. [Installation et déploiement](#14-installation-et-déploiement)
15. [Auteurs](#15-auteurs)

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

---

## 2. Architecture MVC

```
┌────────────────────────────────────────────────────────────────────┐
│                           CLIENT (Navigateur)                      │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│                         FILTRES                                    │
│  util.AuthFilter (@WebFilter "/vues/*")                            │
│  util.SecurityFilter (@WebFilter "/*") ← En-têtes HTTP sécurisés   │
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
│      MODÈLE (JPA)       │     │            VUE (JSP + JSTL)         │
│  model.Utilisateur,     │     │  WEB-INF/vues/login.jsp,            │
│  model.Etudiant,        │     │  admin/*.jsp, enseignant/*.jsp,     │
│  model.Module, ...      │     │  etudiant/*.jsp, notifications.jsp  │
│  dao.*DAO               │     │  JSTL: <c:out>, <c:if>, <c:forEach> │
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

### 5.1 `model.TravailPratique` (avec versioning)

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

    // NOUVEAU : Référence à la version parente pour le versioning
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private TravailPratique parent;

    @OneToMany(mappedBy = "travail", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Commentaire> commentaires;

    public enum Statut { SOUMIS, EN_CORRECTION, CORRIGE, RENDU }

    // Getters & Setters incluant getParent() / setParent()
}
```

**Annotation importante :**
- `@ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "parent_id")` : relation auto-référentielle pour lier les versions

---

## 6. DAOs — Méthodes et requêtes JPQL

### 6.1 `TravailPratiqueDAO` — Nouvelles méthodes de versioning

| Méthode | JPQL / Logique |
|---------|----------------|
| `findVersionHistory(Long tpId)` | Remonte à la racine via `parent`, puis `SELECT t FROM TravailPratique t WHERE t.etudiant.id = :etudiantId AND t.module.id = :moduleId AND t.titre = :titre ORDER BY t.version ASC` |
| `findRootVersion(Long tpId)` | Boucle sur `parent` jusqu'à `parent == null` |

```java
/**
 * Récupère l'historique des versions d'un TP (toutes les versions liées).
 */
public List<TravailPratique> findVersionHistory(Long tpId) {
    EntityManager em = JPAUtil.getEntityManager();
    try {
        TravailPratique tp = em.find(TravailPratique.class, tpId);
        if (tp == null) return Collections.emptyList();

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
    } finally { em.close(); }
}
```

---

## 7. Servlets — Annotations et URLs

### 7.1 Tableau des servlets

| Classe | URL | Rôle |
|--------|-----|------|
| **Authentification** |
| `servlet.LoginServlet` | `/LoginServlet` | Formulaire login, authentification |
| `servlet.LogoutServlet` | `/LogoutServlet` | Déconnexion |
| **Admin** |
| `servlet.admin.ModuleServlet` | `/admin/ModuleServlet` | CRUD modules |
| `servlet.admin.EnseignantServlet` | `/admin/EnseignantServlet` | CRUD enseignants |
| `servlet.admin.EtudiantServlet` | `/admin/EtudiantServlet` | CRUD étudiants |
| `servlet.admin.MessageServlet` | `/admin/MessageServlet` | Messagerie admin |
| **Enseignant** |
| `servlet.enseignant.CorrectionTPServlet` | `/enseignant/CorrectionTPServlet` | Correction des TP |
| `servlet.enseignant.RapportServlet` | `/enseignant/RapportServlet` | Upload rapports |
| `servlet.enseignant.MessageServlet` | `/enseignant/MessageServlet` | Messagerie enseignant |
| **Étudiant** |
| `servlet.etudiant.DepotTPServlet` | `/etudiant/DepotTPServlet` | Dépôt TP avec **versioning** |
| `servlet.etudiant.MessageServlet` | `/etudiant/MessageServlet` | Messagerie étudiant |
| **API REST** |
| `servlet.api.AbsenceReportApiServlet` | `/api/absence` | Signalement absence |
| `servlet.api.AlerteDepassementApiServlet` | `/api/alerte-depassement` | Réception alerte dépassement |

---

## 8. Classes utilitaires

### 8.1 `util.PasswordUtil` — Hashage des mots de passe

```java
public class PasswordUtil {
    private static final String SALT = "EtudAcadPro#2025";

    // SHA-256 avec sel fixe → 64 caractères hex
    public static String hash(String password) {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        md.update(SALT.getBytes(StandardCharsets.UTF_8));
        byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
        // Conversion en hexadécimal...
    }

    public static boolean verify(String inputPassword, String stored) {
        // Compare hash ou en clair (migration)
    }
}
```

### 8.2 `util.HtmlUtil` — Protection XSS

```java
/**
 * Échappe les caractères HTML dangereux pour prévenir les attaques XSS.
 * Remplace: & < > " ' par leurs entités HTML correspondantes.
 */
public class HtmlUtil {

    public static String escape(String input) {
        if (input == null) return "";
        StringBuilder escaped = new StringBuilder();
        for (char c : input.toCharArray()) {
            switch (c) {
                case '&': escaped.append("&amp;"); break;
                case '<': escaped.append("&lt;"); break;
                case '>': escaped.append("&gt;"); break;
                case '"': escaped.append("&quot;"); break;
                case '\'': escaped.append("&#x27;"); break;
                default: escaped.append(c);
            }
        }
        return escaped.toString();
    }

    // Échappe pour JavaScript inline
    public static String escapeJs(String input) { ... }
}
```

### 8.3 `util.InputValidator` — Validation des entrées

```java
public class InputValidator {

    // Patterns de validation
    private static final Pattern EMAIL_PATTERN = 
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    public static boolean isValidEmail(String email) { ... }
    public static boolean isValidName(String name) { ... }
    public static boolean isNumeric(String str) { ... }
    public static Long parseId(String idStr) { ... }
    public static String sanitize(String input) { ... }
    public static boolean isValidPassword(String password) { ... }
}
```

### 8.4 `util.SecurityFilter` — En-têtes HTTP de sécurité

```java
@WebFilter("/*")
public class SecurityFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) {
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
            "frame-ancestors 'self';"
        );

        // Cache-Control pour pages sensibles
        httpResponse.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        httpResponse.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

        chain.doFilter(request, response);
    }
}
```

### 8.5 `util.FileUploadUtil` — Gestion des fichiers

| Méthode | Rôle |
|---------|------|
| `sauvegarder(Part, Long)` | Enregistre fichier sous `tp_uploads/etudiant_<id>/` |
| `supprimer(String)` | Supprime fichier du disque |
| `extraireNomFichier(Part)` | Extrait nom depuis `Content-Disposition` |
| `getTailleMax()` | Retourne 10 Mo |

**Extensions autorisées :** `.pdf, .doc, .docx, .zip, .rar, .java, .py, .txt, .png, .jpg`

---

## 9. Sécurité de l'application

### 9.1 Protection contre les injections SQL

**Méthode** : Requêtes paramétrées JPA (JPQL)

```java
// ✅ SÉCURISÉ : paramètre bindé
em.createQuery("SELECT e FROM Etudiant e WHERE LOWER(e.nom) LIKE :kw")
  .setParameter("kw", "%" + keyword.toLowerCase() + "%")
  .getResultList();

// ❌ VULNÉRABLE (jamais utilisé dans l'application)
em.createQuery("SELECT e FROM Etudiant e WHERE e.nom = '" + nom + "'")
```

### 9.2 Protection contre XSS

| Technique | Fichier | Usage |
|-----------|---------|-------|
| **JSTL `<c:out>`** | JSP | `<c:out value="${erreur}"/>` échappement automatique |
| **HtmlUtil.escape()** | JSP scriptlets | `<%= HtmlUtil.escape(user.getNom()) %>` |
| **HtmlUtil.escapeJs()** | JavaScript inline | `var ctx = '<%= HtmlUtil.escapeJs(ctx) %>';` |

**Exemple dans `login.jsp` :**

```jsp
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!-- Message d'erreur sécurisé -->
<c:if test="${not empty erreur}">
    <div class="bg-red-50 text-red-700 px-4 py-3 rounded-lg">
        <c:out value="${erreur}"/>
    </div>
</c:if>

<!-- Valeur de formulaire sécurisée -->
<input type="email" name="email" value="<c:out value='${emailValue}'/>"/>
```

**Exemple dans `tp_detail.jsp` :**

```jsp
<%@ page import="util.HtmlUtil" %>

<!-- Titre sécurisé -->
<h2><%= HtmlUtil.escape(tp.getTitre()) %></h2>

<!-- Commentaire utilisateur sécurisé -->
<p><%= HtmlUtil.escape(commentaire.getContenu()) %></p>
```

### 9.3 En-têtes HTTP de sécurité

Le filtre `SecurityFilter` ajoute automatiquement :

| En-tête | Valeur | Protection |
|---------|--------|------------|
| `X-Frame-Options` | `SAMEORIGIN` | Anti-clickjacking |
| `X-Content-Type-Options` | `nosniff` | Anti-MIME sniffing |
| `X-XSS-Protection` | `1; mode=block` | XSS navigateur |
| `Content-Security-Policy` | (voir code) | Politique de sécurité |
| `Cache-Control` | `no-store` | Pas de cache |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Contrôle referrer |

### 9.4 Hashage des mots de passe

- **Algorithme** : SHA-256 avec sel fixe `"EtudAcadPro#2025"`
- **Format** : Chaîne hexadécimale de 64 caractères
- **Utilisation** : Création/modification utilisateur, authentification

---

## 10. Gestion des versions des TPs

### 10.1 Fonctionnement

L'application permet aux étudiants de soumettre plusieurs versions d'un TP **avant la date limite**.

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORKFLOW DE VERSIONING                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Étudiant dépose TP initial       → version = 1, parent = null │
│  2. Étudiant clique "Nouvelle version" → version = 2, parent = TP1 │
│  3. Étudiant clique "Nouvelle version" → version = 3, parent = TP2 │
│  ...                                                             │
│  Date limite atteinte → bouton "Nouvelle version" disparaît      │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 Interface utilisateur

**Page de détail du TP (`tp_detail.jsp`)** :

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

### 10.3 Code servlet (`DepotTPServlet.java`)

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
```

### 10.4 Conditions d'affichage

| Condition | Bouton "Nouvelle version" |
|-----------|---------------------------|
| Statut = SOUMIS + date limite non dépassée | ✅ Affiché |
| Statut = EN_CORRECTION, CORRIGE ou RENDU | ❌ Masqué |
| Date limite dépassée | ❌ Masqué + message |

---

## 11. Vues JSP — Structure et JSTL

### 11.1 Directives et taglibs

```jsp
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.*, java.util.*, util.HtmlUtil" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
```

### 11.2 Utilisation JSTL vs Scriptlets

| Cas d'usage | Méthode recommandée |
|-------------|---------------------|
| Afficher texte utilisateur | `<c:out value="${variable}"/>` |
| Condition simple | `<c:if test="${condition}">...</c:if>` |
| Boucle sur liste | `<c:forEach items="${liste}" var="item">` |
| Scriptlets complexes | `<%= HtmlUtil.escape(valeur) %>` |
| JavaScript inline | `var x = '<%= HtmlUtil.escapeJs(val) %>';` |

### 11.3 Liste des vues

| Chemin | Rôle | Sécurité XSS |
|--------|------|--------------|
| `login.jsp` | Formulaire connexion | JSTL `<c:out>`, `<c:if>` |
| `notifications.jsp` | Liste notifications | `HtmlUtil.escape()` |
| `admin/messages.jsp` | Messagerie admin | `HtmlUtil.escape()` |
| `enseignant/message.jsp` | Messagerie enseignant | `HtmlUtil.escape()` |
| `etudiant/message.jsp` | Messagerie étudiant | `HtmlUtil.escape()` |
| `etudiant/tp_detail.jsp` | Détail TP + historique versions | `HtmlUtil.escape()` |

---

## 12. Intégration API avec l'application des absences

### 12.1 Configuration

**`web.xml` :**

```xml
<context-param>
    <param-name>absence.system.url</param-name>
    <param-value>http://localhost:8081/AbsTrack</param-value>
</context-param>
```

### 12.2 API exposées par EtudAcadPro

| Méthode | URL | Corps | Réponse |
|---------|-----|-------|---------|
| POST | `/api/absence` | `{ "etudiantId": 1, "enseignantId": 2 }` | `{ "success": true }` |
| GET | `/api/non-rendus` | — | `[{ "etudiantId": 1, "moduleNom": "..." }]` |
| POST | `/api/alerte-depassement` | `{ "emailEtudiant": "...", "nbAbsences": 5 }` | `{ "success": true }` |

**CORS activé** : `Access-Control-Allow-Origin: *`

---

## 13. Structure complète du projet

```
EtudAcadPro/
├── src/java/
│   ├── dao/
│   │   ├── JPAUtil.java
│   │   ├── UtilisateurDAO.java
│   │   ├── EtudiantDAO.java
│   │   ├── EnseignantDAO.java
│   │   ├── ModuleDAO.java
│   │   ├── RapportDAO.java
│   │   ├── TravailPratiqueDAO.java      ← findVersionHistory()
│   │   ├── CommentaireDAO.java
│   │   ├── NotificationDAO.java
│   │   └── AbsenceReportDAO.java
│   ├── model/
│   │   ├── Utilisateur.java
│   │   ├── Enseignant.java
│   │   ├── Etudiant.java
│   │   ├── Module.java
│   │   ├── Rapport.java
│   │   ├── TravailPratique.java         ← parent (versioning)
│   │   ├── Commentaire.java
│   │   ├── Notification.java
│   │   ├── AbsenceReport.java
│   │   ├── FeedItem.java
│   │   └── NonRemisItem.java
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
│   │   │   ├── RapportServlet.java
│   │   │   ├── CorrectionTPServlet.java
│   │   │   ├── AbsenceServlet.java
│   │   │   ├── CommentaireServlet.java
│   │   │   ├── MessageServlet.java
│   │   │   └── SignalerAbsenceTpServlet.java
│   │   ├── etudiant/
│   │   │   ├── DashboardServlet.java
│   │   │   ├── DepotTPServlet.java      ← versioning logic
│   │   │   └── MessageServlet.java
│   │   └── api/
│   │       ├── AbsenceReportApiServlet.java
│   │       ├── AlerteDepassementApiServlet.java
│   │       └── NonRendusApiServlet.java
│   └── util/
│       ├── PasswordUtil.java            ← hashage SHA-256
│       ├── HtmlUtil.java                ← protection XSS (NEW)
│       ├── InputValidator.java          ← validation entrées (NEW)
│       ├── SecurityFilter.java          ← en-têtes HTTP (NEW)
│       ├── AuthFilter.java
│       ├── FileUploadUtil.java
│       ├── NotificationService.java
│       ├── AbsenceIntegrationService.java
│       └── NonRemisCheckService.java
├── web/
│   ├── index.jsp
│   └── WEB-INF/
│       ├── web.xml
│       ├── classes/META-INF/persistence.xml
│       └── vues/
│           ├── login.jsp                ← JSTL sécurisé
│           ├── notifications.jsp        ← HtmlUtil.escape()
│           ├── admin/
│           │   ├── messages.jsp         ← HtmlUtil.escape()
│           │   └── ... (7 autres JSP)
│           ├── enseignant/
│           │   ├── message.jsp          ← HtmlUtil.escape()
│           │   └── ... (6 autres JSP)
│           └── etduaint/
│               ├── tp_detail.jsp        ← versioning UI + HtmlUtil
│               ├── message.jsp          ← HtmlUtil.escape()
│               └── ... (4 autres JSP)
├── dist/
│   └── EtudAcadPro.war
├── README.md
└── EVALUATION.md
```

---

## 14. Installation et déploiement

### 14.1 Prérequis

- JDK 17
- MySQL 8
- WildFly 27+ (ou serveur Jakarta EE compatible)

### 14.2 Base de données

```sql
CREATE DATABASE miniprojet_be4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 14.3 Build et déploiement

1. NetBeans : **Clean and Build** → `dist/EtudAcadPro.war`
2. Copier WAR dans `standalone/deployments/` (WildFly)
3. Accès : `http://localhost:8081/EtudAcadPro/`

---

## 15. Auteurs

**Mini-projet Jakarta EE — ELKHARRAF / MANSOURI**

Application de gestion académique avec :
- Gestion des étudiants, enseignants, modules, TP
- **Versioning des TPs** avec historique
- **Sécurité renforcée** : XSS, SQL Injection, en-têtes HTTP
- Hashage des mots de passe (SHA-256)
- Intégration API avec l'application de gestion des absences (AbsTrack)
