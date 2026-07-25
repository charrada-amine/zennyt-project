# Demo (full flow) — cheat sheet

**75 requests** (6 logins + 69 steps) exercising every current Recruitment
endpoint, in an order that chains itself (each request captures the IDs the
next one needs). Self-sufficient — creates its own job position, offer,
assessment, test attempt — and rerunnable without a reset: each full run
creates fresh entities (except the two proposal steps, which suffix their
name with a per-run timestamp to dodge the unique (name, sector) constraint).

This collection reflects the backend **after** the squad-web contract
reconciliation (Applications removed; Swipes/Matches redesigned; Assessment
Attempts replaced by Test Attempts/Results with per-attempt shuffling; the
uniform `{error, message, ...}` envelope). It replaces the earlier
REC-04-era collection entirely — nothing here talks to `/swipes` (flat),
`/applications`, `/assessment-attempts`, or `X-Dev-User`.

## Before running

1. Base + backend: bring-up block in `docs/DEMO_INTEGRATION.md` (root of the
   repo) — creates the 6 fixed-UUID demo accounts this collection logs in as.
2. Bruno → **Open Collection** → `tooling/bruno` → environment **Local**
   (top right).
3. Open the **Demo** folder.
   - **Narrated mode**: click **Send** on 00 → 00 → 01a → … → 12a.
   - **One-click mode**: hover **Demo** → **Run** icon → *Run Collection*.
   - **CLI mode**: `npx @usebruno/cli run Demo --env Local` from
     `tooling/bruno`.

## The steps (expected status · one-liner)

### Logins (00)
Real JWT for all 6 seeded accounts — everything downstream carries a real
Bearer token, no simulated header.
- **Rania** (REC), **Youssef** (REC2), **Aicha** (CAND), **Omar** (CAND2),
  **Lina** (CAND3), **Sami** (ADMIN) · 200 each.

### Job positions catalog (01)
- 01a List (CAND) · 200 · référentiel approuvé, ouvert à tout acteur authentifié.
- 01b Propose (REC) · 201 · métier absent → PENDING_APPROVAL.
- 01c Pending (ADMIN) · 200 · file d'attente d'approbation.
- 01d Approve (ADMIN) · 200 · → APPROVED, fixe le profil dominant (Fit Score).

### Job offers (02)
- 02a Create (REC) · 201 · publiée ACTIVE immédiatement, jamais de passingScore.
- 02b List mine (REC) · 200.
- 02c Detail (CAND) · 200 · recruiter{companyName,companyInfo} joint en lecture.
- 02d Search (CAND) · 200 · sans filtre → fil recommandé (fit score).
- 02e Search filtered (CAND) · 200 · avec filtre → recherche plein texte.
- 02f Replace PUT (REC) · 200 · remplacement complet.
- 02h Create throwaway (REC) · 201.
- 02i Patch → DRAFT (REC) · 200 · statut librement réversible, pas de machine à états.
- 02j Swipe on draft (CAND) · **409** · `JOB_NOT_ACTIVE`.
- 02k Delete draft (REC) · 204.

### Assessments (03)
- 03a Create (REC) · 201 · 4 questions, 4 options chacune.
- 03b List summary (REC) · 200 · `AssessmentSummaryResponse[]`.
- 03c Detail (REC) · 200 · questions + correctOptionIndex (recruteur only).
- 03d Update PUT (REC) · 200.
- 03e Generate from prompt (REC) · 201 · IA (Groq, stub hors ligne).
- 03f Generate from file (REC) · 201 · PDF uploadé (PDFBox).
- 03g Attach to offer (REC) · 200 · PATCH assessmentId.
- 03h Delete in use (REC) · **409** · `ASSESSMENT_IN_USE` + `linkedJobOfferIds`.

### Swipes & matches (04)
- 04a Candidate deck (CAND) · 200.
- 04b Candidate swipes (CAND) · 201 · matched:false.
- 04c Re-swipe (CAND) · **409** · `SWIPE_ALREADY_EXISTS`.
- 04d Recruiter deck (REC) · 200 · Aicha marquée candidateAlreadyInterested.
- 04e Recruiter swipes (REC) · 201 · matched:true, Match créé.
- 04f Re-swipe after match (CAND) · **409** · `ALREADY_MATCHED`.
- 04g Candidate matches (CAND) · 200.
- 04h Recruiter matches (REC) · 200.
- 04i Undo (CAND) · 204 · le Match est supprimé avec le swipe.
- 04j Re-swipe after undo (CAND) · 201 · matched:true immédiatement (swipe recruteur jamais touché).

### Hard skill test results (05)
- 05a Start attempt (CAND) · 201 · questions/options mélangées par tentative.
- 05b Submit (CAND) · 200 · percentage 100, passed:true (seuil fixe 70%).
- 05c My result (CAND) · 200.
- 05d List for job (REC) · 200 · joint aux données candidat.
- 05e Summary (REC) · 200 · candidateCount/passedCount/successRate.
- 05f Detail with breakdown (REC) · 200 · seule vue avec la correction.
- 05g Start again (CAND) · **409** · `ATTEMPT_ALREADY_CONSUMED`.
- 05h Create offer w/o test (REC) · 201.
- 05i Start on it (CAND) · **404** · `NO_ASSESSMENT_LINKED`.
- 05j Start as Omar (CAND2) · 201 · tentative indépendante de celle d'Aicha.
- 05k Abandon (CAND2) · 200 · TestResult ABANDONED, score 0.
- 05l Submit after abandon (CAND2) · **409** · `ATTEMPT_ALREADY_SUBMITTED`.

### Candidate resume — AI (06)
- 06a Get resume (REC) · 200 · soft skills + hard skills bilingues ; hardSkills
  peut afficher `available:false` juste après 05b (génération asynchrone).

### Fit scores (07)
- 07a Callback (AI) · **409** · un score a déjà été précalculé de façon
  asynchrone à l'activation de l'offre (`JobOfferFitScoreListener`) —
  le callback refuse un score différent pour une paire déjà scorée.
- 07b Get score (CAND) · 200 · lit le score réellement précalculé, pas la
  valeur postée (et rejetée) en 07a.
- 07c Recompute (REC) · 200 · synchrone (levier démo).
- 07d Candidate feed (REC) · 200.
- 07e Dismiss (REC) · 204.
- 07f Deck after dismiss (REC) · 200 · Aicha n'apparaît plus.

### Identity verification (08)
- 08a Request (REC) · 201 · PENDING.
- 08b Status (·) · 200 · PENDING.
- 08c Callback facial (AI) · 200.
- 08d Status (·) · 200 · COMPLETED_SUCCESS.

### Job opportunity offers (09)
- 09a Send (REC) · 201 · exige un Match ACTIVE (plus de candidature/présélection).
- 09b Detail (CAND) · 200.
- 09c Confirm (CAND) · 200 · OTP_SENT (vrai OTP, code en clair uniquement dans le log serveur).
- 09d Verify wrong code (CAND) · **401**.
- 09e Send 2nd (REC) · 201.
- 09f Reject (CAND) · 200 · REJECTED.
- 09g Ghost candidate (REC) · **404**.
- 09h Foreign offer (REC2) · **403**.

### Payments (10)
- 10a Initiate (REC) · 201 · 9.99 EUR + 2.00 EUR taxe, OTP_SENT.
- 10b Detail (REC) · 200.
- 10c Verify wrong code (REC) · **401**.

### Backend defends itself (11)
- 11a Callback wrong secret (AI) · **401**.

### Shared error envelope (12)
- 12a Bad login (AUTH) · **401** · même `{error, message}` que Recruitment —
  `GlobalExceptionHandler` est partagé avec Identity, pas dupliqué.
- 12b Bad register (AUTH) · **400** · `VALIDATION_ERROR` + `fieldErrors` —
  la démonstration `VALIDATION_ERROR` vit ici plutôt que sur Job Offers :
  `CreateJobOfferRequest` n'a actuellement aucune validation bean (`@Valid`
  absent de `JobOfferController.create`), découvert en vérifiant cette
  collection en direct — signalé séparément, pas corrigé dans ce lot.

## If it stalls

- **409 "already consumed / already exists / already matched"**: you
  replayed a request already played against the same entity in a prior
  partial run. The collection creates fresh entities each full run, so
  rerun from **00**. To start completely clean: the reset block in
  `docs/DEMO_INTEGRATION.md`.
- **500 / empty page**: the backend isn't running →
  `docker start zennyt-project-db-1` (or your Postgres container), boot the
  jar, health-check `http://localhost:8080/actuator/health`.
- **Real OTP codes**: not returned by the API by design — read
  `backend-int.log` for `[DEV OTP]` lines (see `docs/DEMO_INTEGRATION.md` §B).
  This collection only demonstrates the deterministic wrong-code rejection.
- **03f slow / Groq-dependent steps**: normal with a real Groq key
  configured (`GROQ_API_KEY` in `.env`); the stub responds instantly without one.
