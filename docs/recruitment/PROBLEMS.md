# Recruitment — Registre des problèmes, risques & questions ouvertes

> Consolidé depuis `notes (1).md` (critique), les décisions de réunion et l'audit du code.
> Statuts : `RÉSOLU (réunion)` · `CORRIGÉ (code)` · `OUVERT` · `BLOQUANT` · `RISQUE`.

---

## P0 — Bloquants avant de coder

### P0.1 — Écart de branche `integration` vs `REC-04` — 🟡 CONTOURNÉ
`notes` et le récap décrivent `feature/REC-04-mobile-integration` (JWT Phase 1 + IA assessments Phase 2 + correctifs sécu). **Le repo courant est sur `integration`, où la Phase 2 IA est absente** (pas de `GroqAssessmentGenerator`, pas de `POST /assessments/generate`).
**Décision exécutée :** travail réalisé sur `integration` avec les assessments manuels
existants. La génération IA d'assessment reste hors du brief exécutable et n'a pas été inventée.

### P0.2 — Entrée CV/profil du fit score sans canal — 🟡 INTERIM ACTIF (D1)
Le fit score exige le **CV/profil candidat** (équipe identity). Or **identity ne publie aucun `ProfileUpdated` event** (vérifié : 0 fichier). Sans canal, le calcul n'a pas ses entrées.
**Interim exécuté :** stub CV `PROVISOIRE`; Games alimente la projection soft-skills.
Identity devra toujours publier `ProfileUpdated` pour remplacer le stub.

---

## 1. Problèmes issus de la critique `notes` — statut post-réunion

| Réf | Problème | Statut | Détail |
|-----|----------|--------|--------|
| 1.1 | **Fit score orphelin** (rien ne calcule/consomme) | **RÉSOLU (réunion) → à implémenter** | Design tranché : précalcul par paire, Groq derrière un port, consommé par decks/search/profil. Voir plan P1–P2. |
| 1.2 | **Deux tunnels disjoints** | **RÉSOLU (réunion)** — *contre la reco `notes`* | Décision : **rester séparés, aucune précondition** (D5). La reco de convergence est abandonnée. |
| 1.3 | **Le test ne garde rien** (attempt non lié à l'Application) | **RÉSOLU (réunion) → à implémenter** — *nouvelle sémantique* | Décision : **le test EST la candidature** (le démarrer crée l'Application). Voir P3. |
| 1.4 | **Trou d'autorisation** `PATCH /applications/{id}/status` | **CORRIGÉ (code, Part 3)** | Contrôle propriétaire + `@PreAuthorize` ~20 endpoints + 5 tests négatifs. |
| 1.5 | **`JobOpportunityOffer` invariants de façade** (`confirm()`/`verifyOtp()` vides) | **CORRIGÉ partiel (code)** | `OTP_SENT` réel ajouté. **Reste** : rename `→ SalaryProposal` (optionnel, P5.2). |
| 1.6 | **Deck recruteur = profils fantômes** (`CandidateProfile` seedé) | **OUVERT / dépend P0.2** | À alimenter par une **projection** des profils identity (event). Même canal manquant que P0.2. |
| 1.7a | **VideoConferencePayment** sans contrepartie (Engagement stub) | **OUVERT — question C** | Geler paiement+visio tant qu'Engagement n'a pas de propriétaire ? |
| 1.7b | **IdentityVerification** doublonne avec identity | **OUVERT — question C** | Céder la vérif *de la personne* à identity ; ne garder que le besoin métier via event. |

---

## 2. Questions produit **encore ouvertes** (non tranchées par les maquettes)

| Réf | Question | Défaut proposé (à valider) |
|-----|----------|----------------------------|
| Q-B10 | **Statuts manquants** : motif de rejet visible candidat ? statut « entretien » ? statut **HIRED** terminal ? | Ajouter `rejectionReason` + `HIRED` terminal (position `notes`), marqué `à valider` tant que non confirmé. |
| Q-C11 | Propriété **Fits/opportunity/paiement** : Recruitment ou futur Engagement ? | Recruitment garde swipes/matches/opportunités. |
| Q-C13 | **IdentityVerification** : qui garde quoi ? | Vérif personne → identity ; besoin métier → recruitment via event. |
| Q-C14 | **Engagement/Analytics** : propriétaire ? Paiement 9,99 € maintenu ? | Geler visio+paiement sans propriétaire Engagement. |
| Q-A2 | **Calculateur** au runtime : leur IA ou notre Groq ? | Groq maintenant derrière le port (D3), swap plus tard. |
| Q-B-preco | Le match crée-t-il quelque chose (invitation) ? | **Non** (D5 : tunnels séparés, le match sert au sourcing/opportunity). |

---

## 3. Risques techniques

| Réf | Risque | Mitigation |
|-----|--------|-----------|
| R1 | **Coût du précalcul N×M** (candidats × offres) via Groq | Calcul **paresseux/borné** (à la publication + on-view + batch limité), upsert ; cache par paire. |
| R2 | **Dépendance Groq** (429/5xx/timeout) | Port + `StubFitScoreCalculator` offline + 502 `UpstreamServiceException`. |
| R3 | **Seuil « Good fit » / passingScore** arbitraires | Constantes config nommées + `PROVISOIRE — à valider` (défaut 60 % / ≥70). |
| R4 | **Sémantique dismiss** (« Remove from Fit Scores ») : masque global ou par recruteur ? | Par (recruteur, candidat, offre) — table `fit_score_dismissals`. À confirmer. |
| R5 | **ddl-auto: validate** — migrations V16–V18 doivent matcher exactement les entités | Dériver le DDL des entités JPA ; vérifier boot dev (comme fait pour V13). |
| R6 | **Idempotence apply-via-assessment** — plusieurs starts = 1 seule Application | Factory `openViaAssessment` idempotente par paire (contrainte unique). |
| R7 | **Couplage cross-module** (games/identity) dans le domaine | Rester en **projections/read-models** alimentées par events ; jamais d'appel direct inter-BC (ArchUnit). |

---

## 4. Bug opérationnel connu (récap) — exonéré

**Progress tab (`/candidates/me/applications`) échoue depuis l'app, `curl` = 200.** → **Non-bug** : coïncidait avec les **redémarrages backend** (nouvelles clés JWT en mémoire + refresh sessions effacées → token mort en session → retry infini). Preuve : parcours piloté sur émulateur contre backend stable = 200 partout.
**Règle opérationnelle :** tout redémarrage backend = tous les tokens app meurent → **se re-logger** (2 s). Inhérent aux clés en mémoire jusqu'à la fusion identity.
**Reste :** un commit `chore(mobile): log status code` **local-only** à `git push` (le shell n'a pas pu ouvrir la fenêtre de credentials).

---

## 5. Synthèse « ce qui bloque le démarrage »

1. **P0.1** est contourné sur `integration`; **P0.2** fonctionne avec un stub CV provisoire.
2. Games (soft-skills) est **prêt** via event ✅.
3. Les blocages restants sont le permit public Shared pour `/tests/{token}`, l'événement
   `ProfileUpdated`, les maquettes mobile absentes et l'absence de collection Bruno.
