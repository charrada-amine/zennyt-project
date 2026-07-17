# Recruitment — Tâches d'implémentation (post-réunion)

> Découpage exécutable du plan `IMPLEMENTATION_PLAN.md`. Cocher au fur et à mesure.
> Convention : `[ ]` à faire · `[~]` en cours · `[x]` fait · `[!]` bloqué (voir `PROBLEMS.md`).
> Chemins relatifs à `backend/src/main/java/com/zennyt/recruitment/` sauf mention.

---

## P0 — Prérequis (bloquants)

- [!] **P0.1** Réconcilier les branches : porter la Phase 2 IA (assessments Groq) présente sur `feature/REC-04-mobile-integration` mais **absente d'`integration`**, ou décider de la branche cible. → `PROBLEMS.md` P0.
- [!] **P0.2** Confirmer canal CV/profil identity (aucun `ProfileUpdated` event) → équipe identity. Interim : stub `PROVISOIRE`.
- [x] **P0.3** Provider = Groq derrière un port, stub déterministe sans clé.
- [x] **P0.4** 502 géré par un advice local Recruitment (aucune modif `shared`).

---

## P1 — Moteur de fit score

### Domaine
- [x] **P1.1** `domain/model/FitScore` : ajouter sous-scores `softSkillScore`, `cvMatchScore` (+ factories `rehydrate`/`compute`).
- [x] **P1.2** `FitScorePolicy.GOOD_FIT_MIN_SCORE=70`, marqué `PROVISOIRE`.

### Application
- [x] **P1.3** `application/port/FitScoreCalculatorPort` : `FitScoreResult calculate(FitScoreInputs)`.
- [x] **P1.4** `application/usecase/RecomputeFitScoresUseCase` : upsert par paire, batch borné, idempotent.
- [x] **P1.5** `application/GameSoftSkillsListener` : `GameResultRecordedEvent` → projection → rescore.
- [!] **P1.6** Event `ProfileUpdated` absent ; entrée CV stubée `PROVISOIRE` sans toucher Identity.

### Infrastructure
- [x] **P1.7** `infrastructure/ai/GroqFitScoreCalculator implements FitScoreCalculatorPort`.
- [x] **P1.8** `infrastructure/ai/StubFitScoreCalculator` (déterministe offline).
- [x] **P1.9** `infrastructure/ai/FitScoreAiConfig` (`@Bean` Groq si clé, sinon Stub).
- [x] **P1.10** `infrastructure/persistence/SoftSkillsProjection*`.
- [x] **P1.11** Réalisé en `V17__fit_scores_subscores.sql` selon l'ordre A→C du brief exécutable.

### Erreur / qualité
- [x] **P1.12** `UpstreamServiceException` + advice local → 502.
- [x] **P1.13** Tests use case + parsing Groq + ArchUnit verts.

**DoD P1 :** un rescore produit/upsert des `FitScore` (Groq ou stub) sans casser ArchUnit ni le callback existant.

---

## P2 — Exposition / consommation

### Contrat
- [x] **P2.1** Contrat : scores sur offres/decks + `DELETE /fit-scores`; profil Identity hors périmètre.

### Application / Infra
- [x] **P2.2** `GetSwipeDeckUseCase` bidirectionnel + feed recruteur minimal.
- [x] **P2.3** `DismissFitScoreUseCase`.
- [~] **P2.4** Offre/search enrichis ; détail profil Identity et UI bloqués hors périmètre/maquettes.
- [x] **P2.5** Feed offres trié par `fit_scores.score` ; feed recruteur trié et filtré.
- [x] **P2.6** Réalisé en `V18__fit_score_dismissals.sql` selon l'ordre du brief.

### API / Mobile
- [x] **P2.7** API score, feed recruteur et endpoint dismiss exposés.
- [!] **P2.8** Mobile bloqué : les 13 maquettes Recruitment sont absentes du dépôt.
- [x] **P2.9** Tests ordre deck, dismiss et exposition score.

**DoD P2 :** decks/search/profil affichent et **trient** par fit score ; dismiss retire la paire.

---

## P3 — Candidature via assessment

### Contrat
- [x] **P3.1** Contrat attempt/Application/consent/résultats/passingScore/test public ajouté.

### Domaine
- [x] **P3.2** `AssessmentAttempt.applicationId` ajouté.
- [x] **P3.3** Réutilisation idempotente de `Application.submit` par paire.
- [x] **P3.4** Seuil domaine 60/override offre.
- [x] **P3.5** `NOT_VALIDATED` visible et exclu du taux.

### Application / Infra
- [x] **P3.6** `SubmitAttemptUseCase` créé ; auto-SHORTLISTED laissé provisoirement désactivé (Q-B10).
- [x] **P3.7** `GetOfferApplicationsUseCase` créé.
- [x] **P3.8** Réalisé en `V16__attempt_application_link.sql` selon l'ordre A du brief.

### API / Mobile
- [x] **P3.9** Contrôleur lié à l'Application + consentement obligatoire.
- [!] **P3.10** Contrôleur/projection prêts ; permit-list `shared/SecurityConfig` non autorisée (runtime 401 vérifié).
- [!] **P3.11** Mobile candidat bloqué par l'absence des maquettes.
- [!] **P3.12** Mobile recruteur bloqué par l'absence des maquettes.
- [x] **P3.13** Tests lien/idempotence/seuil/flagged/projection publique.

**DoD P3 :** démarrer un test crée une candidature ; le recruteur voit la liste enrichie avec pass/fail au seuil.

---

## P4 — Enrichissements offre

- [x] **P4.1** `applicantCount` exposé sur détail/liste.
- [!] **P4.2** Endpoint prêt ; câblage mobile bloqué sans écran/maquette Recruitment.
- [~] **P4.3** `shareableLink` exposé ; affichage mobile et permit public bloqués.
- [x] **P4.4** Salaire + `hiringContactId` exposés.

**DoD P4 :** offre affiche salaire/contact/applicant count ; show/hide fonctionne depuis l'app.

---

## P5 — Tunnels séparés (doc)

- [x] **P5.1** Deux tunnels séparés et absence de précondition documentés.
- [ ] **P5.2** (Optionnel) rename `JobOpportunityOffer → SalaryProposal` (refactor mécanique séparé, avant fusion repos).

---

## P6 — Qualité / clôture

- [x] **P6.1** Documentation, changelog et date mis à jour.
- [!] **P6.2** Aucune collection Bruno n'existe dans ce dépôt ; aucun format existant à étendre.
- [x] **P6.3** Maven/ArchUnit verts ; `flutter analyze` propre ; 27 tests Flutter verts.
- [x] **P6.4** Boot PostgreSQL 16, Flyway V18, Hibernate validate et health vérifiés.
- [ ] **P6.5** Commits par section, **sans co-author Claude** (préférence utilisateur du récap).

---

## Récap migrations à créer (jamais éditer V1–V15)

| Fichier | Contenu |
|---------|---------|
| `V16__attempt_application_link.sql` | `application_id` + `passing_score` (60) |
| `V17__fit_scores_subscores.sql` | sous-scores fit + projection soft-skills |
| `V18__fit_score_dismissals.sql` | « Remove from Fit Scores » |
