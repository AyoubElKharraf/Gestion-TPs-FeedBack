# Configuration et dépannage – Système Absences (AbsTrack)

Lorsque le message **« Le système Absences n'a pas enregistré l'absence »** s'affiche, vérifier les trois points ci‑dessous.

---

## (1) URL configurée dans `web.xml`

**Où :** `web/WEB-INF/web.xml`  
**Paramètre :** `absence.system.url` (context-param)

**Exemple (projet Gestion Absences dans `../ElKharrafMansouri_MiniProjet_JakartaEE`, sous-contexte `/AbsTrack`) :**
```xml
<context-param>
    <param-name>absence.system.url</param-name>
    <param-value>http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack</param-value>
</context-param>
```
- Si AbsTrack est déployé à la racine du projet → `http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE`
- Si AbsTrack est sous un sous-chemin → `http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack` (sans slash final).

- La valeur doit pointer vers la **racine** de l’application AbsTrack (sans `/api/alerte` à la fin).
- Pas d’espace avant/après, pas de slash final.
- En production, remplacer `localhost:8081` par l’hôte et le port réels du serveur AbsTrack.

**Vérification :** après redémarrage de l’application EtudAcadPro, la page Absences (en cas d’échec) affiche l’URL configurée ; comparer avec l’URL réelle de votre AbsTrack.

---

## (2) L’application Gestion Absences est démarrée

- Le serveur qui héberge **AbsTrack** (ou Gestion_AbsencesAlerts) doit être **démarré**.
- EtudAcadPro envoie une requête **POST** vers :  
  `{absence.system.url}/api/alerte`  
  avec un corps JSON (type `non_remis_tp`, emails étudiant/enseignant, module, etc.).

**Test rapide (URL configurée : `.../ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack`) :**
```bash
# 1. Vérifier que l’application répond
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack/

# 2. Tester l’endpoint appelé par EtudAcadPro (doit renvoyer du JSON contenant "success":true)
curl -X POST "http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack/api/alerte" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"non_remis_tp\",\"emailEtudiant\":\"etudiant@test.com\",\"emailEnseignant\":\"ens@test.com\",\"moduleNom\":\"Jakarta EE\",\"rapportTitre\":\"TP1\"}"
```
**Important :** EtudAcadPro considère que l’absence est enregistrée **uniquement si** la réponse HTTP est 2xx **et** que le corps JSON contient `"success":true`. Si votre API renvoie un autre format, adaptez-la ou le code dans `AbsenceIntegrationService`.

- Si le serveur n’est pas démarré : connexion refusée → le signalement côté EtudAcadPro échoue et le message d’erreur s’affiche.
- Si AbsTrack exige une clé API (ex. `X-API-Key`), il faut que l’appel depuis EtudAcadPro envoie cette clé (voir documentation AbsTrack / `AbsenceIntegrationService`).

---

## (3) Étudiant et enseignant existent dans Gestion Absences avec les mêmes emails

- EtudAcadPro envoie à AbsTrack les **adresses email** de l’étudiant et de l’enseignant (telles que stockées dans EtudAcadPro).
- Dans l’application Gestion Absences / AbsTrack, il doit exister :
  - un **étudiant** dont l’email est **strictement le même** que dans EtudAcadPro ;
  - un **enseignant** dont l’email est **strictement le même** que dans EtudAcadPro.

**À vérifier :**
- Pas de différence de casse (ex. `Jean.Dupont@univ.fr` vs `jean.dupont@univ.fr`).
- Pas d’espace avant/après.
- Même format (pas un alias différent entre les deux applications).

Si l’un des deux (étudiant ou enseignant) n’existe pas dans AbsTrack ou avec un email différent, l’enregistrement de l’absence peut échouer et le message « Le système Absences n'a pas enregistré l'absence » s’affiche.

---

## Récapitulatif

| Point | Où vérifier | Action |
|-------|-------------|--------|
| (1) URL | `web.xml` → `absence.system.url` | Ex. `http://localhost:8081/ElKharrafMansouri_MiniProjet_JakartaEE/AbsTrack` (sans slash final). L’appel réel est `{cette_url}/api/alerte`. |
| (2) Démarré | Serveur AbsTrack | Démarrer l’application Gestion Absences sur le bon port ; tester avec `curl` ci‑dessus. |
| (3) Emails | Base / config AbsTrack | Créer ou aligner les comptes étudiant et enseignant avec les **mêmes** emails que dans EtudAcadPro. |

Après toute modification de `web.xml` ou du serveur AbsTrack, **redémarrer** EtudAcadPro (ou recharger le contexte) pour que la nouvelle configuration soit prise en compte.
