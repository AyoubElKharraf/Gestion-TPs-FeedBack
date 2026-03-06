# Évaluation de l'application EtudAcadPro

Document d'évaluation technique et fonctionnelle du mini-projet Jakarta EE — gestion académique (étudiants, enseignants, modules, TP, absences, intégration API).

**Version mise à jour** avec les dernières améliorations de sécurité et fonctionnalités.

---

## 1. Synthèse globale

| Critère            | Note / Commentaire |
|--------------------|--------------------|
| **Fonctionnalités** | ✅ Complètes (admin, enseignant, étudiant, API absences, **versioning TPs**). |
| **Architecture**    | ✅ MVC classique (Servlets + JSP/JSTL + DAO), claire et maintenable. |
| **Sécurité**        | ✅ **Renforcée** : protection XSS, en-têtes HTTP, validation entrées. |
| **Intégration API** | ✅ Bien conçue (entrant/sortant), CORS, JSON, documentation. |
| **Base de données** | ✅ JPA/Hibernate, requêtes paramétrées, schéma cohérent. |
| **Qualité du code** | ✅ Lisible, utilitaires réutilisables, peu de duplication. |

**Verdict :** Application **solide et sécurisée**, adaptée à un mini-projet Jakarta EE avancé, avec une vraie valeur ajoutée (hashage des mots de passe, protection XSS, versioning des TPs, intégration API externe).

---

## 2. Points forts

### 2.1 Fonctionnalités et rôles

- **Trois rôles bien séparés** (ADMIN, ENSEIGNANT, ETUDIANT) avec redirections selon le rôle après login.
- **Admin** : CRUD modules, enseignants, étudiants ; messages ; vérification des non-rendus ; liste des étudiants « à supprimer » (3 absences).
- **Enseignant** : rapports (supports de cours), correction des TP, commentaires, liste des non-rendus, signalement d'absence vers AbsTrack, messages.
- **Étudiant** : dépôt de TP avec **versioning** (mise à jour avant deadline), consultation des feedbacks, messages.
- **Notifications** : centralisées (NotificationServlet), avec compteur et marquage « lu ».

### 2.2 Gestion des versions des TPs *(NOUVEAU)*

- **Versioning complet** : un étudiant peut soumettre plusieurs versions d'un TP avant la date limite.
- **Modèle enrichi** : colonne `parent_id` dans `TravailPratique` pour lier les versions.
- **Historique visuel** : interface déroulante affichant toutes les versions avec dates et fichiers.
- **DAO dédié** : méthodes `findVersionHistory()` et `findRootVersion()` pour récupérer la chaîne des versions.

```
┌─────────────────────────────────────────────┐
│ 🕐 Historique des versions              ▼  │
│    3 versions                               │
├─────────────────────────────────────────────┤
│ ● Version 1 : 27 Fév · 17:33   [Voir]  ⬇   │
│ ● Version 2 : 27 Fév · 18:04   [Voir]  ⬇   │
│ ● Version 3 : 28 Fév [Actuelle]        ⬇   │
└─────────────────────────────────────────────┘
```

### 2.3 Sécurité des mots de passe

- **Hachage systématique** avant stockage en base (`PasswordUtil.hash` avec SHA-256 + sel).
- Utilisation dans `EtudiantServlet` et `EnseignantServlet` à la création/mise à jour.
- Vérification à la connexion via `PasswordUtil.verify` dans `UtilisateurDAO`.

### 2.4 Protection XSS *(NOUVEAU - IMPLÉMENTÉ)*

| Technique | Implémentation | Fichiers concernés |
|-----------|----------------|-------------------|
| **JSTL `<c:out>`** | Échappement automatique | `login.jsp` |
| **HtmlUtil.escape()** | Échappement manuel | Tous les JSP avec scriptlets |
| **HtmlUtil.escapeJs()** | JavaScript inline | `messages.jsp` |

**Classe `util.HtmlUtil`** :
```java
public static String escape(String input) {
    // Remplace & < > " ' par entités HTML
    // &amp; &lt; &gt; &quot; &#x27;
}

public static String escapeJs(String input) {
    // Échappement pour JavaScript inline
    // \\ \' \" \n \r \u003c \u003e
}
```

**Utilisation dans les JSP** :
```jsp
<!-- Avant (vulnérable) -->
<%= user.getNom() %>

<!-- Après (sécurisé) -->
<%= HtmlUtil.escape(user.getNom()) %>

<!-- Avec JSTL -->
<c:out value="${erreur}"/>
```

### 2.5 En-têtes de sécurité HTTP *(NOUVEAU)*

Le filtre `SecurityFilter` (`@WebFilter("/*")`) ajoute automatiquement :

| En-tête | Valeur | Protection |
|---------|--------|------------|
| `X-Frame-Options` | `SAMEORIGIN` | Anti-clickjacking |
| `X-Content-Type-Options` | `nosniff` | Anti-MIME sniffing |
| `X-XSS-Protection` | `1; mode=block` | XSS navigateur |
| `Content-Security-Policy` | Politique stricte | Scripts/styles autorisés |
| `Cache-Control` | `no-store` | Pas de mise en cache |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Contrôle referrer |

### 2.6 Validation des entrées *(NOUVEAU)*

Classe `util.InputValidator` pour valider côté serveur :

| Méthode | Rôle |
|---------|------|
| `isValidEmail(String)` | Valide format email |
| `isValidName(String)` | Lettres, espaces, tirets |
| `isNumeric(String)` | Chaîne numérique |
| `parseId(String)` | Parse Long sécurisé |
| `sanitize(String)` | Nettoie espaces superflus |
| `isValidPassword(String)` | Minimum 6 caractères |

### 2.7 Intégration avec l'application des absences (AbsTrack)

- **Configuration centralisée** : `absence.system.url` dans `web.xml`.
- **Sortant** : alertes « non remis TP », notification dépassement, récupération absences.
- **Entrant** : API REST (`/api/absence`, `/api/non-rendus`, `/api/alerte-depassement`).
- CORS configuré, réponses JSON structurées.

### 2.8 Modèle de données et accès

- **JPA** avec entités claires (héritage JOINED, relations ManyToOne/OneToMany).
- **DAOs** avec `EntityManager` géré proprement.
- **Requêtes paramétrées** partout → **pas de risque d'injection SQL**.

### 2.9 Upload de fichiers (TP)

- **Taille limitée** : `@MultipartConfig` (10 Mo fichier, 15 Mo requête).
- **Extensions autorisées** : liste blanche (pdf, doc, zip, java, etc.).
- **Noms de fichiers** : suffixe UUID pour éviter les collisions.

---

## 3. Améliorations implémentées (anciens points d'attention)

### 3.1 ~~Pas d'échappement XSS dans les JSP~~ ✅ CORRIGÉ

**Avant** : Les vues utilisaient `<%= ... %>` sans échappement.

**Maintenant** :
- `HtmlUtil.escape()` appliqué sur tous les contenus utilisateur (noms, messages, commentaires).
- `HtmlUtil.escapeJs()` pour les variables JavaScript inline.
- JSTL `<c:out>` utilisé dans `login.jsp`.

**Fichiers corrigés** :
- `login.jsp` (JSTL)
- `tp_detail.jsp` (HtmlUtil)
- `admin/messages.jsp` (HtmlUtil)
- `enseignant/message.jsp` (HtmlUtil)
- `etudiant/message.jsp` (HtmlUtil)
- `notifications.jsp` (HtmlUtil)

### 3.2 ~~Pas d'en-têtes de sécurité HTTP~~ ✅ AJOUTÉ

**Nouveau filtre** `SecurityFilter` appliqué sur toutes les requêtes (`/*`) :
- Protection clickjacking
- Protection MIME sniffing
- Content Security Policy
- Cache-Control pour pages sensibles

---

## 4. Points d'attention restants (non bloquants)

### 4.1 Filtre d'authentification limité à `/vues/*`

- **AuthFilter** ne s'applique qu'à `/vues/*`. La sécurité repose sur les vérifications servlet.
- **Recommandation** : étendre le filtre à `/admin/*`, `/enseignant/*`, `/etudiant/*`.

### 4.2 API publiques sans authentification

- Les endpoints `/api/*` sont accessibles sans token.
- Acceptable pour un projet pédagogique ; en production, ajouter une API key.

### 4.3 Hashage des mots de passe (SHA-256 + sel fixe)

- Suffisant pour un projet pédagogique.
- **Production** : préférer BCrypt ou PBKDF2 avec sel par utilisateur.

### 4.4 Typo dans un chemin de vues

- Le répertoire est nommé `etduaint` au lieu de `etudiant`.
- Impact cosmétique uniquement.

### 4.5 Gestion d'erreurs et logs

- Pas de logger centralisé visible.
- **Recommandation** : utiliser SLF4J + Logback.

---

## 5. Tableau récapitulatif des améliorations

| Fonctionnalité | Statut | Détail |
|----------------|--------|--------|
| Protection XSS | ✅ Implémenté | `HtmlUtil`, JSTL `<c:out>` |
| En-têtes HTTP sécurisés | ✅ Implémenté | `SecurityFilter` |
| Validation des entrées | ✅ Implémenté | `InputValidator` |
| Versioning des TPs | ✅ Implémenté | `parent_id`, historique UI |
| Hashage mots de passe | ✅ Existant | SHA-256 + sel |
| Requêtes paramétrées (SQL) | ✅ Existant | JPA/JPQL |
| Contrôle d'accès par rôle | ✅ Existant | Vérification dans servlets |
| Extension filtre auth | ⏳ Recommandé | `/admin/*`, `/enseignant/*`, `/etudiant/*` |
| Authentification API | ⏳ Recommandé | Token ou API key |
| Logger centralisé | ⏳ Recommandé | SLF4J + Logback |

---

## 6. Recommandations pour une évolution

| Priorité | Action | Statut |
|----------|--------|--------|
| ~~Haute~~ | ~~Échappement XSS dans les JSP~~ | ✅ FAIT |
| ~~Haute~~ | ~~En-têtes de sécurité HTTP~~ | ✅ FAIT |
| Moyenne  | Étendre filtre d'authentification aux URLs métier | ⏳ À faire |
| Moyenne  | Migrer vers BCrypt pour le hashage | ⏳ À faire |
| Moyenne  | Sécuriser API d'intégration (token, IP whitelist) | ⏳ À faire |
| Basse    | Renommer le dossier `etduaint` en `etudiant` | ⏳ À faire |
| Basse    | Introduire un logger centralisé | ⏳ À faire |

---

## 7. Architecture de sécurité actuelle

```
┌─────────────────────────────────────────────────────────────────────┐
│                         REQUÊTE HTTP                                │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│              SECURITY FILTER (@WebFilter("/*"))                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • X-Frame-Options: SAMEORIGIN                                 │  │
│  │ • X-Content-Type-Options: nosniff                             │  │
│  │ • X-XSS-Protection: 1; mode=block                             │  │
│  │ • Content-Security-Policy: default-src 'self'; ...            │  │
│  │ • Cache-Control: no-store                                     │  │
│  │ • Referrer-Policy: strict-origin-when-cross-origin            │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 AUTH FILTER (@WebFilter("/vues/*"))                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • Vérifie session.getAttribute("utilisateur")                 │  │
│  │ • Redirige vers /LoginServlet si non connecté                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          SERVLET                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • Vérification rôle (isAdmin(), getEtudiantSession(), etc.)   │  │
│  │ • Validation entrées (InputValidator)                         │  │
│  │ • Logique métier                                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DAO (JPA)                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • Requêtes JPQL paramétrées (:email, :id, :kw)                │  │
│  │ • Pas de concaténation SQL → Pas d'injection                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        VUE (JSP)                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • JSTL <c:out> pour données dynamiques                        │  │
│  │ • HtmlUtil.escape() pour scriptlets                           │  │
│  │ • HtmlUtil.escapeJs() pour JavaScript inline                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Conclusion

L'application **EtudAcadPro** est **très bien réalisée** pour un mini-projet Jakarta EE avancé :

### Objectifs atteints ✅
- Gestion des rôles (admin, enseignant, étudiant)
- CRUD complet (modules, enseignants, étudiants, TP, rapports)
- **Versioning des TPs** avec historique visuel
- Intégration API avec système d'absences externe
- **Sécurité renforcée** : XSS, en-têtes HTTP, hashage mots de passe

### Qualité technique ✅
- Architecture MVC propre et maintenable
- JPA/Hibernate avec requêtes paramétrées (pas d'injection SQL)
- Classes utilitaires réutilisables (`HtmlUtil`, `InputValidator`, `PasswordUtil`)
- Documentation complète (README.md, EVALUATION.md)

### Points d'amélioration identifiés (mineurs)
- Extension du filtre d'authentification
- Migration vers BCrypt (production)
- Authentification des API
- Logger centralisé

**Note indicative :** Excellent niveau pour un mini-projet, avec une vraie maturité sur les aspects sécurité et architecture. Les améliorations restantes sont des bonnes pratiques pour un passage en production.

---

*Document mis à jour après implémentation des protections XSS, des en-têtes de sécurité HTTP et du versioning des TPs.*
