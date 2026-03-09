# Tests de sécurité – Exemples d’attaques à essayer

Ce document décrit des **exemples d’attaques** que vous pouvez lancer contre votre application pour vérifier que les protections (XSS, injection SQL, en-têtes HTTP, API, contrôle d’accès) fonctionnent correctement.

**Important :** effectuez ces tests uniquement en **environnement de développement** (localhost). Ne les utilisez pas contre des systèmes en production sans autorisation.

---

## 1. Tests XSS (Cross-Site Scripting)

L’objectif est de vérifier que le contenu malveillant est **échappé** et affiché comme du texte, et non exécuté comme du code.

### 1.1 Page de connexion (message d’erreur)

**Où :** `/EtudAcadPro/LoginServlet` (POST)  
**Comment :** soumettre le formulaire avec un email invalide ou un mot de passe faux, puis (si l’appli renvoie l’email dans l’URL ou en session) refaire une requête avec un paramètre contenant du script.

**Payload à tester dans le champ email (si l’erreur réaffiche l’email) :**
```
<script>alert('XSS')</script>
```
ou
```
"><img src=x onerror=alert('XSS')>
```

**Résultat attendu (sécurité OK) :** le texte s’affiche littéralement (ex. `&lt;script&gt;alert('XSS')&lt;/script&gt;` ou équivalent), **aucune** boîte `alert` ne s’ouvre.

---

### 1.2 Commentaire / feedback (enseignant ou étudiant)

**Où :**  
- Enseignant : page de correction d’un TP → zone « Répondre à l’étudiant » ou « Feedback détaillé ».  
- Étudiant : détail d’un TP → formulaire pour ajouter un commentaire.

**Payloads à coller dans le champ texte :**
```
<script>alert('XSS')</script>
```
```
<img src=x onerror="alert('XSS')">
```
```
<svg onload=alert('XSS')>
```
```
javascript:alert('XSS')
```

**Résultat attendu :** le contenu est affiché comme **texte** (caractères visibles), pas exécuté. Aucune alerte JavaScript.

---

### 1.3 Paramètres d’URL réaffichés dans la page

Si une page affiche un paramètre d’URL (ex. `?message=...` ou `?erreur=...`), tester :

**URL à ouvrir (adapter le contexte et le chemin) :**
```
/EtudAcadPro/LoginServlet?erreur=<script>alert(1)</script>
```
ou
```
/EtudAcadPro/enseignant/CorrectionTPServlet?action=detail&id=1&msg=<img src=x onerror=alert(1)>
```

**Résultat attendu :** le paramètre est affiché échappé (texte uniquement), pas exécuté.

---

## 2. Tests d’injection SQL

L’application utilise JPA / requêtes paramétrées, donc les injections SQL « classiques » ne devraient **pas** modifier la requête. Ces tests servent à le confirmer.

### 2.1 Connexion (login)

**Où :** formulaire de connexion (POST vers `LoginServlet`).

**Payloads à tester dans le champ email :**
```
' OR '1'='1
```
```
admin'--
```
```
' OR 1=1--
```

**Résultat attendu :** la connexion **échoue** (message d’erreur « identifiants incorrects » ou équivalent). Aucune connexion en tant qu’admin ou autre utilisateur sans mot de passe valide.

---

### 2.2 Paramètres numériques (ID)

**Où :** toute URL avec un paramètre `id` (ex. détail TP, détail rapport, détail étudiant).

**Exemples d’URL à tester (adapter le chemin et l’ID) :**
```
/EtudAcadPro/enseignant/CorrectionTPServlet?action=detail&id=1 OR 1=1
```
```
/EtudAcadPro/enseignant/RapportServlet?action=detail&id=1; DROP TABLE rapports--
```

**Résultat attendu :**  
- Soit erreur 400 / page d’erreur (paramètre invalide).  
- Soit la page ne retourne pas plus de données que pour un seul ID.  
- **Aucune** suppression ou modification de tables.

---

### 2.3 Recherche / filtre (si présent)

S’il existe un champ de recherche (étudiants, TPs, etc.) :

**Payload à saisir :**
```
' OR '1'='1' UNION SELECT id,email,password FROM utilisateurs--
```

**Résultat attendu :** pas de liste d’utilisateurs avec mots de passe ; au pire erreur ou liste vide / comportement normal.

---

## 3. En-têtes HTTP de sécurité

**Objectif :** vérifier que les en-têtes anti-cliquage, anti-MIME-sniffing, etc. sont bien envoyés.

**Méthode 1 – Navigateur :**  
1. Ouvrir les outils développeur (F12).  
2. Onglet **Réseau** (Network).  
3. Recharger la page ou naviguer.  
4. Cliquer sur la requête principale (document HTML).  
5. Dans **En-têtes de la réponse** (Response Headers), vérifier la présence d’au moins :

| En-tête | Exemple de valeur | Rôle |
|--------|--------------------|------|
| `X-Frame-Options` | `DENY` ou `SAMEORIGIN` | Limite l’inclusion en iframe (anti-cliquage) |
| `X-Content-Type-Options` | `nosniff` | Empêche le navigateur de deviner le type MIME |
| `X-XSS-Protection` | `1; mode=block` | Renforce la protection XSS du navigateur |
| `Content-Security-Policy` | (présent, même minimal) | Restreint les sources de scripts/contenu |

**Méthode 2 – Ligne de commande (curl) :**
```bash
curl -I "http://localhost:8080/EtudAcadPro/"
```
Remplacer le port et le chemin par ceux de votre déploiement. Vérifier dans la sortie que les en-têtes ci-dessus sont présents.

**Résultat attendu :** ces en-têtes apparaissent dans la réponse.

---

## 4. Authentification des APIs (clé API)

Si votre application expose des APIs (ex. pour AbsTrack) protégées par une clé :

**URL type à tester (adapter le chemin selon votre projet) :**
```
http://localhost:8080/EtudAcadPro/api/...
```

**Test 1 – Sans clé API :**
```bash
curl -X POST "http://localhost:8080/EtudAcadPro/api/AbsenceReportApiServlet" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```
**Résultat attendu :** réponse **401 Unauthorized** (ou 403) et message du type « API key required » / « Accès refusé ».

**Test 2 – Avec une mauvaise clé :**
```bash
curl -X POST "http://localhost:8080/EtudAcadPro/api/AbsenceReportApiServlet" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: fake-key-123" \
  -d '{"test": true}'
```
**Résultat attendu :** **401** ou **403**.

**Test 3 – Avec la clé configurée (web.xml) :**
```bash
curl -X POST "http://localhost:8080/EtudAcadPro/api/AbsenceReportApiServlet" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: EtudAcadPro-API-2025-SecretKey" \
  -d '{}'
```
**Résultat attendu :** la requête est acceptée (réponse 200 ou 400 selon le corps, mais pas 401 pour cause de clé).

---

## 5. Contrôle d’accès (rôles) – **y compris « copier l’URL dans un nouvel onglet »**

Cette vulnérabilité (**accès par copier-coller d’URL**) est **corrigée** dans votre application : le `AuthFilter` vérifie le **rôle** de l’utilisateur pour chaque requête vers `/admin/*`, `/enseignant/*`, `/etudiant/*`. Si un étudiant copie une URL admin et l’ouvre dans un **nouvel onglet** (même session), le serveur renvoie **403 Forbidden** et non la page admin.

### Test explicite : copier l’URL et l’ouvrir dans un nouvel onglet

**Scénario :**  
1. Se connecter en tant qu’**étudiant**.  
2. Copier une URL d’**admin** (ex. `http://localhost:8080/EtudAcadPro/admin/DashboardServlet`) depuis un lien ou en la tapant.  
3. Ouvrir un **nouvel onglet** (Ctrl+T ou Cmd+T) et **coller** cette URL puis Entrée.

**Résultat attendu (vulnérabilité corrigée) :**  
- La page affiche **403 Forbidden** avec le message « Accès non autorisé pour votre rôle. »  
- **Aucune** page d’administration ne s’affiche.

**Même test dans l’autre sens :**  
- Connecté en **admin**, copier une URL **étudiant** (ex. `/EtudAcadPro/etudiant/DepotTPServlet`) → l’admin peut y accéder (votre filtre autorise ADMIN sur `/etudiant/*`).  
- Connecté en **enseignant**, copier une URL **admin** dans un nouvel onglet → **403 Forbidden**.

---

### 5.1 Étudiant → pages Admin

**Étapes :**  
1. Se connecter en tant qu’**étudiant**.  
2. Ouvrir manuellement une URL réservée à l’admin (ou la copier dans un nouvel onglet), par exemple :  
   `http://localhost:8080/EtudAcadPro/admin/DashboardServlet`  
   ou  
   `http://localhost:8080/EtudAcadPro/admin/EtudiantServlet`

**Résultat attendu :** **403 Forbidden** « Accès non autorisé pour votre rôle. » — **pas** le tableau de bord admin.

---

### 5.2 Étudiant → pages Enseignant

**Étapes :**  
1. Rester connecté en tant qu’**étudiant**.  
2. Ouvrir :  
   `http://localhost:8080/EtudAcadPro/enseignant/DashboardServlet`  
   ou  
   `http://localhost:8080/EtudAcadPro/enseignant/CorrectionTPServlet?action=list`

**Résultat attendu :** **403 Forbidden** « Accès non autorisé pour votre rôle. » — **pas** la liste des TPs à corriger (même en collant l’URL dans un nouvel onglet).

---

### 5.3 Enseignant → pages Admin

**Étapes :**  
1. Se connecter en tant qu’**enseignant**.  
2. Ouvrir :  
   `http://localhost:8080/EtudAcadPro/admin/EtudiantServlet`

**Résultat attendu :** **403 Forbidden** « Accès non autorisé pour votre rôle. » (même en ouvrant l’URL dans un nouvel onglet).

---

### 5.4 Sans être connecté

**Étapes :**  
1. Ouvrir une session en navigation privée (ou se déconnecter).  
2. Tenter d’accéder directement à :  
   `http://localhost:8080/EtudAcadPro/etudiant/DepotTPServlet`  
   ou  
   `http://localhost:8080/EtudAcadPro/enseignant/CorrectionTPServlet`

**Résultat attendu :** redirection vers la **page de connexion**.

---

## 6. Récapitulatif – Checklist

| Test | Où / Comment | Résultat si la sécurité tient |
|------|----------------|-------------------------------|
| XSS (login / erreur) | Champ email ou paramètre d’erreur | Texte affiché, pas d’exécution de script |
| XSS (commentaire / feedback) | Zone de commentaire ou feedback | Même chose |
| SQL (login) | Email / mot de passe avec `' OR '1'='1` | Connexion refusée |
| SQL (paramètre id) | URL avec `id=1 OR 1=1` ou `id=1; DROP...` | Erreur ou comportement sans impact |
| En-têtes sécurité | Onglet Réseau ou `curl -I` | Présence de X-Frame-Options, X-Content-Type-Options, etc. |
| API sans clé | `curl` sans `X-API-Key` | 401 / 403 |
| API mauvaise clé | `curl` avec `X-API-Key: fake` | 401 / 403 |
| Étudiant → /admin/* | Copier URL admin, ouvrir dans nouvel onglet (session étudiant) | **403 Forbidden** |
| Étudiant → /enseignant/* | Même test avec URL enseignant | **403 Forbidden** |
| Enseignant → /admin/* | Copier URL admin dans nouvel onglet | **403 Forbidden** |
| Non connecté → /etudiant/* ou /enseignant/* | Coller l’URL en navigation privée | Redirection vers login |

---

## 7. En cas de faille

- **XSS :** s’assurer que toutes les sorties utilisateur passent par `HtmlUtil.escape()` ou JSTL `<c:out>` (pas de `<%= ... %>` brut pour du contenu saisi par l’utilisateur).  
- **Injection SQL :** ne jamais concaténer les paramètres dans une requête SQL/JPQL ; utiliser uniquement des paramètres nommés ou positionnels.  
- **APIs :** vérifier que `ApiKeyFilter` (ou équivalent) est bien mappé sur toutes les URLs d’API et que la clé est lue depuis la configuration (web.xml).  
- **Contrôle d’accès :** dans `AuthFilter` (ou dans chaque servlet), vérifier le **rôle** de l’utilisateur en plus de la simple présence en session.

En utilisant ces exemples, vous pouvez valider que votre sécurité se comporte comme prévu dans les cas courants (XSS, SQL, en-têtes, API, rôles).
