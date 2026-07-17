# Recruitment — Plan d'implémentation post-réunion (100 % correct)

> **Statut :** plan de référence après la réunion de cadrage (16/07) et l'analyse des 13 maquettes.
> **Scope :** backend recruitment (+ mobile wizard/decks). Aucun autre module modifié sans validation.
> **Source de vérité produit :** décisions réunion + 13 écrans + `notes (1).md` (critique).
> **Contrat :** `contracts/recruitment.openapi.yaml`. **Doc module :** `RECRUITMENT_MODULE.md`.
>
> **Exécution 2026-07-16 :** l'ordre exécutable de `CODEX_BRIEF.md` fait autorité pour
> les migrations : V16 lien attempt/application, V17 sous-scores, V18 dismissals.
> Le backend est réalisé ; les exceptions restantes sont tracées dans `TASKS.md`.

---

## 0. Décisions verrouillées (autorité = réunion + maquettes)

| # | Sujet | Décision |
|---|-------|----------|
| D1 | **Composition du fit score** | `soft skills (games) + CV vs description de l'offre + description entreprise`. **Tests hard exclus** (le score précède le test). |
| D2 | **Déclenchement** | **Précalculé par paire (candidat, offre)** — existe **avant toute interaction**. Rescore quand : offre publiée (vs profils connus) / profil-CV-games mis à jour (vs offres actives). Upsert (le dernier gagne). |
| D3 | **Calculateur** | **Groq maintenant, derrière un port** `FitScoreCalculator`. Swap vers le service IA de l'autre équipe plus tard **sans toucher le domaine**. Le contrat callback `POST /callbacks/fit-score` reste un écrivain alternatif. |
| D4 | **Consommateurs** | Deck « Fits » **bidirectionnel** (candidat swipe offres / recruteur swipe pros), Search, détail profil (badge %, chip « Good fit », barre soft-skills). Action **« Remove from Fit Scores »**. |
| D5 | **Deux tunnels restent séparés** (⇐ **override** de la reco `notes` 1.2) | **Tunnel A** : `Recruit` → `JobOpportunityOffer` (poste + salaire) **directement** depuis un profil fit-scoré. **Aucune précondition** (ni match, ni APPROVED). **Tunnel B** : la candidature s'ouvre **exclusivement via l'assessment**. |
| D6 | **Assessment = la candidature** (⇐ **override** de la reco `notes` 1.3) | Démarrer le test attaché à l'offre **crée l'Application**. `AssessmentAttempt ↔ Application` liés. Case de consentement = callback intégrité anti-fraude. |
| D7 | **Seuil de réussite** | **60 % par défaut, override par offre**. `passed = scoreQCM ≥ seuil`. |
| D8 | **Résultats recruteur** | `GET /job-offers/{id}/applications` = liste des candidatures **enrichie** du meilleur attempt (score QCM %, Successful/Failed, statut intégrité, date test) + agrégats (nb candidats, taux de réussite). |
| D9 | **Champs offre** | salaire (existe), hiring contact (existe), **applicant count** (à exposer), show/hide (existe), **shareable test link** (existe). |
| D10 | **STUDENT = CANDIDATE** | Déjà codé ainsi. |

> **Renommage** `JobOpportunityOffer → SalaryProposal` : recommandé (reco `notes` 1.5) mais **non bloquant** — refactor mécanique à faire avant la fusion des repos. Hors périmètre de ce plan sauf demande.

---

## 1. Comparaison — plan `notes` (recommandations) vs plan réunion (autorité)

| Sujet | Recommandation `notes` | **Décision réunion (ce qu'on implémente)** |
|-------|------------------------|--------------------------------------------|
| Déclencheur fit score | Sur candidature **OU** match | **Précalcul par paire, avant interaction** (D2) |
| Calculateur | Leur service IA via callback | **Groq maintenant** derrière un port (D3) |
| Entrées | Profil + offre (games ?) | **Soft-skills games + CV/offre + entreprise, hard exclu** (D1) |
| Tunnels | **Convergence** (match→invitation, opportunity **post-APPROVED**, précondition) | **Restent séparés, aucune précondition** (D5) |
| Test technique | Non bloquant, info jointe | **Le test EST la candidature** (crée l'Application) (D6) |
| Statuts | Ajouter motif rejet + HIRED | À confirmer — **non tranché par les maquettes** (voir PROBLEMS Q-B10) |

**Conséquence :** plusieurs recommandations de `notes` sont **abandonnées** par la réunion. Ce fichier est l'autorité ; `notes (1).md` reste la trace du raisonnement.

---

## 2. Audit de l'existant (ancré dans le code — branche `integration`)

| Brique | État | À faire |
|--------|------|---------|
| `FitScore` (id, candidateId, jobOfferId, score, computedAt) | Écrit **uniquement** par callback ; rien ne calcule/ordonne | **Ajouter le moteur de calcul + la consommation** |
| `JobOfferStatus` DRAFT→ACTIVE→HIDDEN→CLOSED + `PATCH /status` | **Show/hide OK** | Câbler mobile ; rien côté domaine |
| `Assessment.shareableLink` (`/tests/{id}`) | **Existe** | Ajouter l'endpoint **public** de passage de test |
| `AssessmentAttempt` (a `passed`, `integrityStatus`) | **Aucun `applicationId`** | **Lier à Application + créer l'Application au démarrage du test** |
| `ApplicationStatus` PENDING→SHORTLISTED→APPROVED/REJECTED | Pas de HIRED, pas de lien attempt | Décision statuts (Q-B10) + enrichir la liste recruteur |
| `JobOpportunityOffer.send()` sans précondition | **Conforme D5** | Rien (documenter que c'est voulu) |
| Seuil de réussite | **Absent** | Ajouter `passingScore` (défaut 60, override offre) |
| Deck `GET /swipes/targets`, matches | **Non ordonnés par score** | Ordonner par fit score |
| Inputs cross-module | `GameResultRecordedEvent` **existe** ; **aucun event Profile identity** | Projections + **event identity manquant = point dur** |

> ⚠️ **Écart de branche.** `notes` et le récap décrivent `feature/REC-04-mobile-integration` (JWT Phase 1 + IA assessments Phase 2 + correctifs sécu Part 3). **Ce repo est sur `integration`**, où la **Phase 2 IA est absente**. → **P0 : réconcilier les branches** avant de démarrer (voir PROBLEMS P0).

---

## 3. Prochaine numérotation Flyway : **V16, V17, …** (jamais éditer V1–V15)

---

## Phase 0 — Prérequis (débloquer avant de coder)

1. **Réconcilier les branches** : intégrer Phase 2 IA (assessments Groq) présente sur REC-04 mais absente d'`integration`, OU travailler sur REC-04. Décision utilisateur.
2. **Confirmer les entrées cross-module** (D1) : games (event OK) + CV/profil identity (**event à créer côté identity → externe, validation**). Interim : Groq calcule avec les données locales disponibles + stub profil, marqué `PROVISOIRE`.
3. **Provider** : Groq confirmé (config `groq.*` déjà présente). Gemini seulement si demandé.

---

## Phase 1 — Moteur de fit score (calcul + upsert)

**But :** produire un score 0–100 par paire (candidat, offre) à partir de D1, précalculé (D2), via un port (D3).

### Contrat d'abord
- Aucun nouvel endpoint public obligatoire (le calcul est interne). Documenter le read-model dans le contrat si exposé.

### Domaine (`recruitment/domain`)
- Étendre `FitScore` : conserver `score` **+ sous-scores** optionnels (`softSkillScore`, `cvMatchScore`) pour la barre soft-skills et le chip « Good fit ». Facteur « Good fit » = seuil produit (ex. ≥ 70) — constante config `PROVISOIRE`.
- VO `FitScoreInputs{softSkills, cvText, jobDescription, companyDescription}` (application-level, pas domaine si couplage).

### Application (`recruitment/application`)
- **Port** `port/FitScoreCalculatorPort` : `FitScoreResult calculate(FitScoreInputs inputs)`.
- **Use case** `RecomputeFitScoresUseCase` :
  - déclenché par `JobOfferPublishedEvent` (score vs candidats connus) et par les projections `SoftSkillsUpdated` / `CandidateProfileUpdated`.
  - borne le batch (lazy/limité), upsert via `FitScoreRepository`.
- **Listeners** `application/listener` : `GameResultRecordedEvent` → maj projection soft-skills → replanifie rescore ; `ProfileUpdated` (identity, **si dispo**) → maj CV/profil → rescore.

### Infrastructure (`recruitment/infrastructure`)
- `infrastructure/ai/GroqFitScoreCalculator implements FitScoreCalculatorPort` (miroir `GroqCvParser` : RestTemplate, `groq.*`, JSON mode, fence-strip ; prompt = pondère soft-skills + adéquation CV/offre + entreprise → 0–100 + sous-scores).
- `infrastructure/ai/StubFitScoreCalculator` (déterministe, offline sans clé).
- `infrastructure/ai/FitScoreAiConfig` : bean = Groq si `groq.api-key` non vide, sinon Stub.
- **Projections read-model** : `SoftSkillsProjection` (alimentée par `GameResultRecordedEvent`), `CandidateProfileProjection` (déjà présente comme `CandidateProfile` seedée → à brancher sur l'event identity).
- **Migration V16** : colonnes `soft_skill_score`, `cv_match_score` sur `fit_scores` + table/colonnes projection soft-skills si besoin.

### Compat callback (D3)
- `POST /callbacks/fit-score` **reste** : écrivain alternatif (leur IA). Même upsert. Aucun changement cassant.

### Tests
- Use case (fake port) : upsert, borne du batch, idempotence.
- Adapter parse Groq (JSON enregistrés : sous-scores, bornes, fences).
- ArchUnit vert (adapters en infrastructure, domaine pur).

---

## Phase 2 — Exposition / consommation du fit score

**But :** afficher et ordonner par score (D4).

### Contrat
- Ajouter le champ `fitScore` (et sous-scores) aux réponses : deck (`GET /swipes/targets`), search, `GET /job-offers/{id}`, détail profil.
- `DELETE /fit-scores/{candidateId}?jobOfferId=` (ou `POST /fit-scores/dismiss`) pour **« Remove from Fit Scores »**.

### Domaine / Application
- `GetSwipeDeckUseCase` (bidirectionnel) : ordonne les cibles par `fitScore` desc pour la paire (viewer, cible).
  - candidat → offres ordonnées par son score ; recruteur → candidats ordonnés par score sur ses offres actives.
- `DismissFitScoreUseCase` : marque une paire comme rejetée (table `fit_score_dismissals` ou flag).
- Enrichir search + détail profil avec le score + chip « Good fit ».

### Infrastructure
- Requêtes ordonnées par `fit_scores.score` (join sur candidateId/jobOfferId).
- **Migration V17** : `fit_score_dismissals(recruiter_id, candidate_id, job_offer_id, dismissed_at)` (ou flag).

### Mobile
- Badge % + ranking sur les cartes deck (onglets « Job Offers | Professionnels »), badge search, chip « Good fit » + barre soft-skills sur le détail profil, action « Remove from Fit Scores ».

### Tests
- Ordre du deck par score ; dismiss retire la paire ; exposition du score dans chaque surface.

---

## Phase 3 — Candidature via assessment (le test EST la candidature)

**But :** D6 + D7 + D8.

### Contrat
- `POST /assessments/{id}/attempts` (ou `POST /assessment-attempts`) : **démarrer le test** ⇒ crée/rattache l'`Application` (PENDING) pour (candidat, offre) + exige `consent=true` (intégrité).
- `GET /job-offers/{id}/applications` : réponse **enrichie** (D8).
- Seuil : `passingScore` exposé sur l'offre (D7).

### Domaine
- `AssessmentAttempt` : ajouter `applicationId` (lien D6).
- `Application` : factory `openViaAssessment(candidateId, jobOfferId)` (statut PENDING, idempotent par paire).
- Seuil : `passed = scoreQCM ≥ passingScore(offre)` (règle **domaine**, pas contrôleur). `passingScore` défaut 60, override par offre.
- Intégrité : attempt FLAGGED (`NOT_VALIDATED`) reste visible mais **exclu du taux de réussite** (déjà fait Part 3 côté mobile ; ancrer côté agrégat de résultats).

### Application
- `SubmitAttemptUseCase` : calcule score, applique seuil, met à jour l'Application liée (ex. PENDING→SHORTLISTED si réussi — **selon décision statut**, voir Q-B10).
- `GetOfferApplicationsUseCase` : join applications × meilleur attempt + agrégats (count, success rate).

### Infrastructure
- **Migration V18** : `assessment_attempts.application_id`, `job_offers.passing_score` (défaut 60), index.
- Requête d'agrégation résultats recruteur.

### API
- `AssessmentAttemptController` : démarrage lié à l'Application ; `AssessmentController`/`ApplicationController` : endpoint résultats enrichi.
- Endpoint **public** de passage de test via `shareableLink` (D9) : `GET /tests/{token}` (résout l'assessment, hors JWT — permit-list).

### Mobile
- Page offre candidat : CTA « Start assessment » / « Continue assessment » + consentement → crée la candidature. Progress tab : suivi.
- Recruteur : écran « Hard Skills Scores » = liste enrichie (Successful/Failed, %, date, taux).

### Tests
- Démarrer un test crée l'Application (idempotent) ; seuil 60/override ; FLAGGED exclu du taux ; endpoint résultats.

---

## Phase 4 — Enrichissements offre & liens

1. **Applicant count** : exposer `COUNT(applications)` par offre (dérivé) dans `GET /job-offers/{id}` et la liste recruteur.
2. **Show/hide** : câbler mobile sur `PATCH /job-offers/{id}/status` (ACTIVE⇄HIDDEN) — domaine déjà OK.
3. **Shareable test link** : endpoint public de résolution (Phase 3) + affichage/partage mobile.
4. **Champs offre** : salaire + hiring contact déjà présents → exposer/afficher.

---

## Phase 5 — Tunnels séparés (documenter, pas de convergence)

- **Confirmer** `JobOpportunityOffer.send()` **sans précondition** (D5) : aucune modif domaine, **documenter** le choix produit dans `RECRUITMENT_MODULE.md` (contre la reco `notes` 1.2).
- Flux OTP `OTP_SENT` : déjà corrigé (Part 3). Rien à faire.
- (Optionnel) rename `JobOpportunityOffer → SalaryProposal` — refactor mécanique séparé.

---

## Phase 6 — Qualité, contrat, doc, vérif

- **Contract-first** : chaque endpoint modifie `recruitment.openapi.yaml` **en premier**.
- **ArchUnit** vert (domaine pur ; adapters IA en infrastructure).
- **Tests** : unitaires domaine + use cases (fakes) + adapters (JSON enregistrés).
- **Bruno** : nouvelles requêtes (recompute/dismiss/generate-attempt/results) + suite Demo verte.
- **Doc** : `RECRUITMENT_MODULE.md` (sections fit score, apply-via-assessment, tunnels) + changelog + date.
- **Flyway** V16→V18 (nouveaux fichiers uniquement).

---

## 7. Modifications HORS module recruitment → validation requise (AGENTS.md §11)

| Besoin | Impact externe | Reco |
|--------|----------------|------|
| Soft-skills en entrée du fit score | **games** doit exposer les scores → `GameResultRecordedEvent` existe ; brancher un listener recruitment (lecture event = OK, pas de modif games) | ✅ faisable sans modifier games |
| CV/profil en entrée | **identity** n'a **aucun `ProfileUpdated` event** → il faut qu'identity en publie un (ou une API/projection) | ⚠️ **externe — bloquant D1** : demander à l'équipe identity, sinon stub `PROVISOIRE` |
| Mapping 502 (adapter IA en échec) | `@RestControllerAdvice` **local recruitment** (0 modif `shared`) ou `shared/GlobalExceptionHandler` (externe) | Reco : advice local |
| `pom.xml` | Aucune dépendance nouvelle | — |

---

## 8. Ordre & dépendances

```
P0 (branches + inputs) → P1 (moteur) → P2 (exposition) ─┐
                                     P3 (apply-via-assessment) ─┼→ P4 (offre) → P6 (qualité)
                                                                P5 (doc tunnels) ┘
```
P1/P2 (fit score) et P3 (apply-via-assessment) sont **indépendants** → parallélisables.
