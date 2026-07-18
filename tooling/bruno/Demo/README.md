# Demo (full flow) — antisèche de présentation

Liste unique de **57 requêtes** (2 logins + 55 étapes) qui exercent **toutes
les API** du contexte Recruitment, dans un ordre qui se chaîne tout seul
(chaque requête capture les IDs pour la suivante). Auto-suffisante (crée sa
propre offre + son test) et **rejouable** sans reset : chaque exécution recrée
des entités neuves.

## Avant de présenter
1. Base + backend : bloc PowerShell de préparation dans `docs/DEMO_ENCADRANT.md`
   (ou `docker compose up -d` si la base est déjà propre).
2. Bruno → **Open Collection** → `tooling\bruno` → environnement **Local** (en haut à droite).
3. Ouvrir le dossier **Demo**.
   - **Mode narration** : cliquer **Send** sur 00, 00, 01, … jusqu'à 54.
   - **Mode 1-clic** : survoler le dossier **Demo** → icône **Run** → *Run Collection*.
   - **Mode CLI** : `npx @usebruno/cli run Demo --env Local` depuis `tooling/bruno`.

## Phrase d'intro (pour l'équipe)
> « Les deux requêtes 00 font un vrai login JWT (contrat aligné sur la squad
> Identity) : tout le reste s'exécute avec un Bearer token réel, plus de header
> simulé. L'API Recruitment est complète — vous allez voir chaque endpoint
> répondre en direct, y compris les refus (401/403/404/422) qui prouvent que
> le backend se défend. »

## Les étapes (statut attendu · phrase)

### Logins (00)
0. **Login Rania (REC)** puis **Login Aicha (CAND)** · 200 · « Vrais JWT, refresh rotation. »

### Mise en place — le recruteur publie (01–09)
1. **Create job offer** · 201 · « Le recruteur crée une offre (ACTIVE, seuil de réussite 60 par défaut). »
2. **List my offers** · 200 · « Il retrouve ses offres. »
3. **Activate offer** · 200 · « Statut piloté serveur (déjà ACTIVE — idempotent pour la démo). »
4. **Offer detail** (candidat) · 200 · « Côté candidat, le détail de l'offre. »
5. **Search offers** · 200 · « Le fil des offres actives. »
6. **Search filtered** · 200 · « Recherche filtrée (niveau SENIOR). »
7. **Create assessment** · 201 · « Le recruteur crée un test technique (QCM) + lien partageable. »
8. **List my assessments** · 200 · « Ses tests. »
9. **Assessment detail** · 200 · « Détail du test. »

### Le swipe & le match (10–13)
10. **Candidate swipes offer** · 201 · « Le candidat like l'offre → `matched:false` (moitié du match). »
11. **Recruiter swipes candidate** · 201 · « Le recruteur like le candidat → `matched:true`, match créé. »
12. **Candidate matches** · 200 · « Le match apparaît côté candidat. »
13. **Recruiter matches** · 200 · « …et côté recruteur. »

### Candidature & évaluation (14–22)
14. **Apply to offer** · 201 · « Dépôt spontané → PENDING (le test la rejoindra en 20). »
15. **My applications** · 200 · « Ses candidatures (onglet Progress du mobile). »
16. **Application detail** · 200 · « Détail de la candidature. »
17. **Applications for offer** (recruteur) · 200 · « Lignes **enrichies** : identité, tentative (score/intégrité), fit score — réservé au propriétaire. »
18. **Shortlist application** · 200 · « Il présélectionne → SHORTLISTED. »
19. **Approve application** · 200 · « Puis approuve → APPROVED (machine à états respectée). »
19b. **Attach test to offer** · 200 · « Le test devient LE test de l'offre — postuler = le passer (cadrage 16/07). »
20. **Submit assessment attempt** · 201 · « Le candidat passe le test (consentement anti-fraude requis) → score 100, la réponse porte l'`applicationId` : **la tentative EST la candidature**. »
21. **Attempt result** · 200 · « Son résultat. »
22. **Attempt results for offer** · 200 · « Le recruteur voit les résultats du test. »

### Callbacks de services externes (23–26)
23. **Fit-score callback (AI)** · 200 · « Le service IA externe peut poster un score (X-Callback-Secret vérifié). »
24. **Get fit score** · 200 · « On lit le score (91). »
25. **Integrity callback (anti-fraud)** · 200 · « L'anti-fraude valide l'intégrité du test. »
26. **Attempt after integrity** · 200 · « integrityStatus est passé à VALIDATED. »

### Vérification d'identité (27–30)
27. **Request identity verification** · 201 · « Le recruteur demande une vérif d'identité (anti-fraude facial). »
28. **Identity status PENDING** · 200 · « Statut initial : PENDING. »
29. **Identity callback (facial)** · 200 · « Le service de reconnaissance faciale renvoie le résultat. »
30. **Identity status SUCCESS** · 200 · « Statut : COMPLETED_SUCCESS. »

### Offre d'opportunité (31–36)
31. **Send opportunity offer** · 201 · « "Recruit" direct depuis le sourcing — sans match ni candidature exigés (cadrage 16/07), mais candidat vérifié + offre du recruteur. »
32. **Opportunity offer detail** · 200 · « Le candidat la consulte. »
33. **Confirm opportunity** · 200 · « Il confirme → déclenche l'OTP SMS (OTP_SENT). »
34. **Verify opportunity OTP** · 200 · « Il valide l'OTP → CONFIRMED. »
35. **Send 2nd opportunity** · 201 · « Une 2e offre… »
36. **Reject opportunity** · 200 · « …que le candidat refuse → REJECTED. »

### Paiement visioconférence (37–39)
37. **Initiate payment** · 201 · « Le recruteur paie la visio (9,99 € + taxe) → OTP_SENT. »
38. **Payment detail** · 200 · « Statut OTP_SENT. »
39. **Verify payment OTP** · 200 · « OTP validé → CONFIRMED. »

### Suppression / intégrité (40–42)
40. **Create throwaway draft** · 201 · « Une offre jetable en DRAFT. »
41. **Delete draft offer** · 204 · « Supprimée. »
42. **Delete assessment** · **409** · « Refusé : le test est attaché à l'offre (19b) — le backend protège l'intégrité référentielle. »

### IA & fit scores (43–48)
43. **Generate assessment AI** · 201 · « Groq génère un QCM complet (stub hors ligne sans clé). »
44. **Recompute fit scores** · 200 · « Recalcul synchrone : chaque profil scoré par Groq contre l'offre 2 (levier démo — le déclenchement normal est asynchrone à l'activation d'une offre). »
45. **Deck with fit scores** · 200 · « Deck recruteur trié par score réel de la paire — le profil Flutter domine l'offre Flutter. »
46. **Offers with fit score** · 200 · « Vue candidat : ses scores sur les offres, `sort=fit`. »
47. **Remove from fit scores** · 204 · « Le recruteur écarte Omar du deck (dismissed, jamais supprimé). »
48. **Deck after dismiss** · 200 · « Omar n'apparaît plus — et un recalcul ne le ressuscite pas. »

### Le backend se défend (49–54)
49. **Callback wrong secret** · **401** · « Un secret invalide ne peut plus forger de scores. »
50. **Application stats** · 200 · « Candidates / Success rate (tentatives FLAGGED exclues). »
51. **Applications non-owner** · **403** · « Rania ne lit pas le pipeline de l'offre de Youssef. »
52. **Attempt without consent** · **422** · « Pas de test sans consentement anti-fraude. »
53. **Opportunity ghost candidate** · **404** · « Pas de proposition salariale vers un candidat fantôme. »
54. **Opportunity foreign offer** · **403** · « Ni adossée à l'offre d'un autre recruteur. »

## Si ça coince
- **4xx “déjà swipé / déjà postulé”** : tu as relancé une requête déjà jouée sur la même
  entité. Le dossier Demo crée une offre neuve à chaque run complet, donc relance depuis
  **00**. Pour repartir totalement à zéro : bloc de préparation de `docs/DEMO_ENCADRANT.md`.
- **500 / page vide** : le backend n'est pas lancé → `docker compose up -d` puis santé sur
  http://localhost:8080/actuator/health.
- **Les OTP** ne sont pas vérifiés en dev : n'importe quel code (ex. `12345`) confirme.
- **44 lent (~3-10 s)** : normal avec une vraie clé Groq (6 appels IA synchrones).
