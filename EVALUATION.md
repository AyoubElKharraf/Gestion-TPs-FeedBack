# Évaluation de l'application EtudAcadPro

**Projet :** Mini-projet Jakarta EE – Gestion académique (étudiants, enseignants, modules, TPs, rapports, notifications)  
**Contexte :** Master M2I – Semestre 1

---

## Note globale : **14,5 / 20**

Répartition indicative :

| Critère | Note / 4 | Commentaire |
|--------|----------|-------------|
| **Fonctionnalités & couverture métier** | 4/4 | Tous les rôles (Admin, Enseignant, Étudiant) sont couverts ; CRUD complet, dépôt/correction TPs, rapports, notifications, messages, absences, fil d’activité type Classroom. |
| **Architecture & structure** | 3,5/4 | Modèle (entités JPA), DAO, Servlets par rôle, utilitaires. Séparation claire. Quelques doublons (AuthFilter limité, pas de filtre par rôle central). |
| **Persistance & données** | 3,5/4 | JPA/Hibernate, relations cohérentes, transactions manuelles correctes. Pas de Bean Validation ; mots de passe en clair. |
| **Sécurité** | 2,5/4 | Contrôle de session et rôle dans chaque servlet (bon). Mots de passe non hashés ; API absence sans auth ; AuthFilter uniquement sur `/vues/*`. |
| **Interface & ergonomie** | 3/4 | JSPs cohérentes (Tailwind), notifications AJAX, vue type Classroom pour l’étudiant. Beaucoup de duplication header/sidebar ; pas de layout commun. |
| **Robustesse & évolutivité** | 2,5/4 | Gestion d’erreurs et validations présentes mais dispersées ; pas de tests automatisés ni de doc API centralisée. |

---

## Points forts

1. **Couverture fonctionnelle**
   - Admin : modules, enseignants, étudiants, messages, notifications.
   - Enseignant : tableau de bord, TPs à corriger, rapports par module, commentaires, absences, messages.
   - Étudiant : modules (cartes type Classroom), voir devoir (rapport), déposer TP, détails TP, messages.
   - Notifications avec badge, liste AJAX et affichage « De : expéditeur ».

2. **Modèle de données**
   - Entités bien découpées (Utilisateur / Etudiant / Enseignant, Module, TravailPratique, Commentaire, Notification, Rapport, AbsenceReport).
   - Relations claires (OneToMany / ManyToOne), héritance sur Utilisateur.

3. **Couche d’accès**
   - Un DAO par entité principale, méthodes cohérentes (findBy*, save, update, delete).
   - Transactions manuelles (begin/commit/rollback) et fermeture de l’EntityManager.

4. **Contrôle d’accès**
   - Chaque servlet vérifie la session et le rôle avant de traiter la requête.
   - Redirection vers le bon tableau de bord selon le rôle si accès à une URL d’un autre rôle.

5. **Expérience utilisateur**
   - Interface homogène (Tailwind, couleurs, cartes).
   - Vue « Mes modules » type Classroom pour l’étudiant (en-têtes colorés, « Voir le devoir », « Déposer un TP »).
   - Page détail devoir avec « Vos devoirs » (Attribué / Rendu) et lien message privé à l’enseignant.

---

## Points à améliorer (suggestions pour la suite)

### Sécurité (priorité haute)

1. **Mots de passe**
   - Ne jamais stocker les mots de passe en clair.
   - Utiliser un hash (ex. BCrypt) à l’enregistrement et à la connexion (via `UtilisateurDAO.authenticate` et les servlets admin qui créent/modifient les comptes).

2. **Protection des URLs**
   - Étendre la protection : soit un filtre unique sur toutes les URLs sauf login/logout, soit des filtres par préfixe (`/admin/*`, `/enseignant/*`, `/etudiant/*`) qui vérifient le rôle en plus de la session.
   - Éviter de se reposer uniquement sur le fait que chaque servlet fait la vérification.

3. **API absence**
   - L’endpoint `/api/absence` (ou équivalent) ne doit pas être public.
   - Exiger une session (et idéalement un rôle autorisé) ou un token avant de créer un signalement d’absence.

### Architecture & maintenabilité

4. **Layout JSP**
   - Introduire un layout commun (include ou tag file) pour header, sidebar et footer par rôle.
   - Réduire la duplication entre les nombreuses JSP (admin, enseignant, etudiant).

5. **Validation**
   - Ajouter Bean Validation (Jakarta Validation) sur les entités (`@NotNull`, `@NotBlank`, `@Size`, `@Email`, etc.).
   - Appeler la validation dans les servlets (ou dans une couche service) avant `dao.save()` pour avoir des messages d’erreur uniformes.

6. **Gestion d’erreurs**
   - Définir une page d’erreur globale dans `web.xml` (`<error-page>`) pour 404 et 500.
   - Centraliser les messages utilisateur (fichier de propriétés ou constantes) au lieu de chaînes en dur dans les servlets.

7. **Typo**
   - Renommer le dossier des vues `etduaint` en `etudiant` (et mettre à jour les chemins dans les servlets) pour éviter la confusion.

### Données & persistance

8. **Configuration base de données**
   - Ne pas mettre le mot de passe MySQL en clair dans `persistence.xml`.
   - Utiliser des variables d’environnement ou un mécanisme de configuration du serveur (ex. datasource WildFly) et injecter la source de données en JPA.

9. **Cycle de vie EntityManager**
   - Pour aller plus loin : envisager un EntityManager par requête (ou par transaction) au lieu d’un par méthode dans les DAO, pour mieux gérer le lazy loading et les transactions (éventuellement avec un filtre « Open Session in View » si nécessaire, en restant conscient des bonnes pratiques).

### Fonctionnalités possibles (évolutions)

10. **Fil d’activité enseignant**
    - Les données `feedItems` sont déjà préparées dans le DashboardServlet enseignant ; afficher ce fil (rapports publiés + TPs déposés par les étudiants) sur le tableau de bord, comme pour l’étudiant.

11. **Recherche et pagination**
    - Paginer les listes (étudiants, modules, TPs) lorsque le volume grandit.
    - Conserver ou étendre la recherche existante (ex. étudiants par nom/email/numéro).

12. **Dates limites**
    - Si besoin : stocker une date limite par rapport ou par module pour les TPs et l’afficher sur la page « Voir le devoir » (comme « Date limite : 28 févr. 23:59 »).

13. **Tests**
    - Tests unitaires sur les DAO (avec base H2 en mémoire) et sur la logique métier.
    - Tests d’intégration sur les servlets (simulation de requêtes GET/POST et vérification des redirections et des attributs).

14. **Documentation**
    - Un README technique (prérequis, build, déploiement, configuration BDD).
    - Commentaire ou doc sur les URLs principales par rôle (comme dans APPLICATION_SUMMARY.md, à garder à jour).

---

## Évaluation de trois évolutions

| Évolution | Décision | Détail |
|----------|----------|--------|
| **Fil d'activité enseignant** | **Fait** | Données déjà dans DashboardServlet ; affichage ajouté sur le tableau de bord (section Fil d'activité : rapports publiés + TPs déposés, avec lien Télécharger/Corriger). |
| **Date limite par devoir** | **Déjà en place** | Rapport.dateLimite ; formulaire Rapports ; affichage sur Voir le devoir ; blocage modification TP après date. |
| **Pagination des listes** | **Non prioritaire** | Listes de taille raisonnable pour un mini-projet ; à ajouter plus tard si besoin (page, size, total). |

---

## Synthèse

L’application est **solide et complète** pour un mini-projet Jakarta EE : rôles bien séparés, fonctionnalités riches (CRUD, TPs, rapports, notifications, vue type Classroom), et code structuré (modèle, DAO, servlets). La note reflète un très bon travail avec des marges de progression surtout en **sécurité** (mots de passe, protection des URLs et de l’API) et en **maintenabilité** (layout commun, validation, gestion d’erreurs). Les suggestions ci-dessus peuvent servir de feuille de route pour les prochaines itérations ou pour un projet plus long (stage, PFE).
