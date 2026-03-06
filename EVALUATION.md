# Évaluation de l'application EtudAcadPro

Document d'évaluation technique et fonctionnelle du mini-projet Jakarta EE — gestion académique (étudiants, enseignants, modules, TP, absences, intégration API).

---

## 1. Synthèse globale

| Critère            | Note / Commentaire |
|--------------------|--------------------|
| **Fonctionnalités** | ✅ Complètes pour le périmètre (admin, enseignant, étudiant, API absences). |
| **Architecture**    | ✅ MVC classique (Servlets + JSP + DAO), claire et maintenable. |
| **Sécurité**        | ⚠️ Correcte pour un projet étudiant ; améliorations possibles (voir §4). |
| **Intégration API** | ✅ Bien conçue (entrant/sortant), CORS, JSON, documentation. |
| **Base de données** | ✅ JPA/Hibernate, requêtes paramétrées, schéma cohérent. |
| **Qualité du code** | ✅ Lisible, rôles vérifiés dans chaque servlet, peu de duplication. |

**Verdict :** Application solide, adaptée à un mini-projet Jakarta EE, avec une vraie valeur ajoutée (hashage des mots de passe, intégration avec un système d’absences externe, API REST).

---

## 2. Points forts

### 2.1 Fonctionnalités et rôles

- **Trois rôles bien séparés** (ADMIN, ENSEIGNANT, ETUDIANT) avec redirections selon le rôle après login.
- **Admin** : CRUD modules, enseignants, étudiants ; messages ; vérification des non-rendus ; liste des étudiants « à supprimer » (3 absences).
- **Enseignant** : rapports (supports de cours), correction des TP, commentaires, liste des non-rendus, signalement d’absence vers AbsTrack, messages.
- **Étudiant** : dépôt de TP (avec filtres par module/statut/dates), consultation des feedbacks, messages.
- **Notifications** : centralisées (NotificationServlet), avec compteur et marquage « lu ».

### 2.2 Sécurité des mots de passe

- **Hachage systématique** avant stockage en base (`PasswordUtil.hash` avec SHA-256 + sel).
- Utilisation dans `EtudiantServlet` et `EnseignantServlet` à la création/mise à jour.
- Vérification à la connexion via `PasswordUtil.verify` dans `UtilisateurDAO`.
- Pas de stockage en clair pour les nouveaux comptes ; rétrocompatibilité gérée pour d’éventuels anciens comptes.

### 2.3 Intégration avec l’application des absences (AbsTrack)

- **Configuration centralisée** : `absence.system.url` dans `web.xml` (context-param), utilisée par les servlets qui appellent AbsTrack.
- **Sortant** : envoi d’alertes « non remis TP » et possibilité de notifier le « dépassement » (3 enseignants) ; récupération des absences par enseignant pour la fiche étudiant.
- **Entrant** : API REST bien définies :
  - `POST /api/absence` : enregistrement d’un signalement (étudiant + enseignant), calcul de `nbAbsences` et `aSupprimer` (≥ 3 enseignants distincts).
  - `GET /api/non-rendus` : liste des étudiants n’ayant pas rendu leur TP (date limite dépassée).
  - `POST /api/alerte-depassement` : réception d’une alerte depuis AbsTrack ; mise à jour de l’étudiant et notification des admins.
- CORS configuré sur les API pour les appels cross-origin.
- Réponses JSON structurées (`success`, `error`, champs métier).

### 2.4 Modèle de données et accès

- **JPA** avec entités claires (Utilisateur héritage JOINED, Module, Rapport, TravailPratique, AbsenceReport, Notification, etc.).
- **DAOs** avec `EntityManager` ouvert/fermé correctement, transactions (begin/commit/rollback).
- **Requêtes paramétrées** partout (`:email`, `:kw`, etc.) — pas de concaténation SQL → **pas de risque d’injection SQL**.

### 2.5 Contrôle d’accès métier

- Chaque servlet « métier » vérifie la **session** et le **rôle** (ex. `isAdmin()`, `getEtudiantSession()`), puis redirige si non autorisé.
- **RapportDownloadServlet** : accès au rapport selon le rôle (admin toujours ; enseignant propriétaire du module ; étudiant de la même filière que le module).

### 2.6 Upload de fichiers (TP)

- **Taille limitée** : `@MultipartConfig` (10 Mo fichier, 15 Mo requête) et `FileUploadUtil.getTailleMax()`.
- **Extensions autorisées** : liste blanche (pdf, doc, zip, java, etc.).
- **Noms de fichiers** : suffixe UUID pour éviter les collisions et les chemins prévisibles.
- Stockage sous `user.home/tp_uploads` avec sous-dossiers par étudiant.

### 2.7 Documentation et lisibilité

- **README.md** et **EVALUATION.md** (ce document) donnent une vue d’ensemble.
- Commentaires Javadoc utiles sur les API et les services (ex. `AbsenceIntegrationService`, `AlerteDepassementApiServlet`).
- Noms de classes et de méthodes cohérents (français pour le domaine métier).

---

## 3. Points d’attention (non bloquants)

### 3.1 Filtre d’authentification limité à `/vues/*`

- **AuthFilter** ne s’applique qu’à `/vues/*`. Les URLs `/admin/*`, `/enseignant/*`, `/etudiant/*` ne sont **pas** protégées par le filtre.
- **Conséquence** : la sécurité repose entièrement sur les vérifications faites dans chaque servlet. C’est cohérent et fonctionnel, mais un oubli dans une future servlet exposerait une URL sans contrôle.
- **Recommandation** : étendre le filtre à `/admin/*`, `/enseignant/*`, `/etudiant/*` (et exclure explicitement `/LoginServlet`, `/api/*` si besoin), ou centraliser la vérification rôle dans un filtre unique pour éviter la duplication.

### 3.2 Pas d’échappement XSS dans les JSP

- Les vues utilisent souvent `<%= ... %>` pour afficher des données (nom, email, message, etc.).
- Si ces données proviennent de saisies utilisateur ou de la base (commentaires, messages), un contenu malveillant pourrait être exécuté dans le navigateur (XSS).
- **Recommandation** : utiliser `<c:out value="..." />` ou `fn:escapeXml()` pour tout affichage de données dynamiques, ou activer l’échappement par défaut (JSP 2.0+).

### 3.3 API publiques sans authentification

- Les endpoints `/api/absence`, `/api/non-rendus`, `/api/alerte-depassement` sont accessibles sans token ni authentification.
- Pour un mini-projet et une communication entre deux applications sur un réseau contrôlé, c’est acceptable. En production, il faudrait restreindre (IP, token partagé, ou API key).

### 3.4 Hashage des mots de passe (SHA-256 + sel fixe)

- **PasswordUtil** utilise SHA-256 avec un sel fixe. C’est bien au-dessus du stockage en clair et suffisant pour un projet pédagogique.
- Pour une **production** : préférer **BCrypt** ou **PBKDF2** avec un sel par utilisateur (comme indiqué dans les commentaires du code).

### 3.5 Typo dans un chemin de vues

- Le répertoire des JSP étudiant est nommé **`etduaint`** au lieu de `etudiant`. Cela n’impacte pas la correction mais peut prêter à confusion lors de la maintenance.

### 3.6 Gestion d’erreurs et logs

- Les exceptions sont souvent attrapées et peu remontées (ex. `NumberFormatException` ignorée, `IOException` avalée dans `FileUploadUtil.supprimer`). Aucun mécanisme de log centralisé visible.
- **Recommandation** : utiliser un logger (ex. SLF4J + Logback) et logger au moins les erreurs (et en production éviter d’exposer les stack traces à l’utilisateur).

---

## 4. Recommandations pour une évolution

| Priorité | Action |
|----------|--------|
| Haute    | Échappement XSS dans les JSP (`c:out` / `fn:escapeXml`) pour les champs saisis par l’utilisateur. |
| Haute    | Étendre le filtre d’authentification aux URLs `/admin/*`, `/enseignant/*`, `/etudiant/*` (ou ajouter un filtre par rôle). |
| Moyenne  | Migrer le hashage des mots de passe vers BCrypt (ou équivalent) pour les nouveaux comptes. |
| Moyenne  | Sécuriser les API d’intégration (token, IP whitelist ou API key) si déploiement en environnement partagé. |
| Basse    | Renommer le dossier `etduaint` en `etudiant`. |
| Basse    | Introduire un logger et une gestion d’erreurs homogène (messages utilisateur + logs serveur). |

---

## 5. Conclusion

L’application **EtudAcadPro** est **bien réalisée** pour un mini-projet Jakarta EE : les objectifs fonctionnels (gestion des rôles, TP, rapports, absences, intégration avec un système externe) sont atteints, le code est structuré, et les choix de sécurité (hachage des mots de passe, requêtes paramétrées, contrôle d’accès par servlet) sont corrects. Les points d’attention relevés (filtre limité à `/vues/*`, XSS, API publiques, renforcement du hashage en production) sont des améliorations classiques pour passer d’un contexte « projet / démo » à un déploiement plus exigeant.

**Note indicative :** bon niveau pour un mini-projet (équivalent à une note très satisfaisante), avec une marge d’amélioration clairement identifiée pour la sécurité et la maintenabilité.
