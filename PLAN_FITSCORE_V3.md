# Plan d'implémentation — Fit Score v3 (cahier des charges + matrice v4.1)

Aligne le backend intégré (`integration-recruitment-align`) sur le cahier des
charges Fit Score v3 (10 p.) et la matrice de pondération v4.1 (9 métiers
transverses + 133 sectoriels × 4 niveaux). Architecture hexagonale, guardrails
(`ArchitectureTest`, `ApiContractRouteParityTest`, `RecruitmentSecurityAnnotationTest`)
verts à chaque phase.

## ⚠️ Décisions préalables (réunion du 19/07) — bloquantes pour les phases 2+

| # | Question | Défaut proposé si non tranché |
|---|---|---|
| D1 | **Sort du `cvMatchScore`** : la formule v3 = soft×poids + hard×poids, sans composante CV. Le CV disparaît-il du score, ou devient-il une 3e composante pondérée ? | Le garder comme sous-composante du Score_Soft n'est pas prévu par le CdC — poser la question explicitement (l'omission ressemble à un oubli). Défaut : conserver `cvMatchScore` en **donnée affichée** (badge), hors formule. |
| D2 | **Hard skills réintégrés au score** : contredit le cadrage 16/07 (« le score précède le test »). Confirmer la sémantique v3 : Poids_Hard=0 tant qu'aucun QCM/tentative, recalcul à la soumission de tentative. | Oui — le score est « vivant » : soft-only avant candidature (mode standard, pas dégradé — CdC §10), blend après tentative. |
| D3 | **Moteur** : formule déterministe (CdC) vs Groq actuel. | Déterministe pour le score ; Groq conservé pour le résumé IA candidat (CdC §7) et la génération de QCM. |
| D4 | **Référentiel métiers** : qui le maintient ? Seed v1 depuis la matrice ? | Seed Flyway depuis la matrice, flag `calibrated=false` (« v1 — non calibrés », matrice p.31). |
| D5 | **Games** : contrat par module. Le `SoftSkillsProjection` actuel = 1 score agrégé ; le CdC exige 5 modules × (score, couverture). | Demander à l'équipe Games l'événement enrichi ; fallback : score agrégé recopié sur les 5 modules, couverture 100 %. |
| D6 | **Périmètre v1** : company_profile et Portfolio/Mixte (profil Artistique) inclus ? | Non — différés (le CdC lui-même recommande de démarrer company_profile « global » et la grille portfolio n'existe pas). |
| D7 | **Seuils de couverture** 60 % (avec QCM) / 70 % (sans). | Accepter tels quels (« à valider avec les RH »). |
| D8 | **Niveaux** : mapper `ExperienceLevel` existant (JUNIOR/…/EXECUTIVE) sur les 4 niveaux CdC (Junior/Senior/Lead/Manager). | JUNIOR→Junior, MID+SENIOR→Senior, LEAD→Lead, MANAGER+EXECUTIVE→Manager (vérifier l'enum réel). |

## Phase 0 — Dettes découvertes le 18/07 (indépendantes de la réunion) ✅/🔜

- [x] `V19__attempt_monitoring_consent.sql` — colonne jamais migrée, **toute base
  fraîche refusait de démarrer** (ddl-auto validate). *(fait, 18/07)*
- [x] `DevOtpDeliveryLogger` (@Profile dev) — l'`OtpRequestedEvent` n'avait **aucun
  consommateur** : code OTP indélivrable, tunnels invérifiables en dev. *(fait)*
- [x] `JacksonConfig` + `JsonNullableModule` — tout PATCH utilisant `JsonNullable`
  (ex. attacher un QCM à l'offre) partait en 500. *(fait)*
- [x] Recherche filtrée : paramètres enum typés dans `JpaJobOfferRepository.search`
  (comparaison String vs champ @Enumerated → 500 Hibernate 6). *(fait)*
- [x] `DevDataSeeder` : offre 3 → recruiter2 (tests négatifs 403), projections
  soft-skills des 3 candidats (sans elles, recompute = 0 paire). *(fait)*
- [ ] **Porter `POST /assessments/generate`** (génération QCM via Groq, REC-04
  phase existante) sur le backend intégré + entrée contrat OpenAPI + guardrails
  44→45. Le mobile et la démo l'utilisent.
- [ ] Canal OTP réel (email via Resend déjà configuré côté identity) — remplacer
  le logger dev par un listener d'envoi en profil prod.

## Phase 1 — Référentiel de pondération (données pures, sans changer le calcul)

Nouveau paquet `recruitment/domain` :

- [ ] VO `JobProfileType` (TECHNIQUE, ANALYTIQUE, RELATIONNEL, MANAGERIAL,
  CONVENTIONNEL, ARTISTIQUE) ; VO `SeniorityBand` (JUNIOR, SENIOR, LEAD, MANAGER)
  + mapping depuis `ExperienceLevel` (D8).
- [ ] Entité `JobRoleProfile` : métier (slug + libellé), profil (couche A), bande,
  `poidsSoft`/`poidsHard`, `poidsHardAttendu`, 5 `poidsModule` (somme 100),
  `typeEvaluationHard` (QCM/PORTFOLIO/MIXTE), `calibrated` (bool, défaut false).
  Invariants dans le domaine (sommes, bornes).
- [ ] Port `JobRoleProfileRepository` + adaptateur JPA + migration `V20` (table
  `recruitment.job_role_profiles`).
- [ ] **Seed Flyway `V21`** généré depuis la matrice v4.1 : script Python
  `tooling/matrice/extract.py` → CSV → SQL (9 transverses d'abord ; les 133
  sectoriels dans un 2e temps — D4). Conserver le CSV en source dans le repo.
- [ ] `JobOffer` : + `jobRoleProfileId` (nullable v1) + override optionnel
  `poidsSoft/poidsHard` (borné) — migration `V22`. PATCH offre (contrat + parité).
- [ ] Endpoint lecture `GET /job-role-profiles` (recruteur, pour pré-remplir les
  curseurs) — contrat OpenAPI + guardrail count.

## Phase 2 — Score soft par modules + couverture (dépend D5)

- [ ] Étendre la projection Games : `SoftSkillsProjection` → 5 modules × (score,
  couverture) — migration `V23`, listener `GameSoftSkillsListener` adapté au
  nouvel événement (ou fallback D5).
- [ ] `FitScoreCalculator` **déterministe** (`DeterministicFitScoreCalculator`,
  adaptateur du port existant `FitScoreCalculatorPort`) :
  `scoreModuleAjusté = score × couverture` (mécanisme 1), `Score_Soft = Σ
  module×poidsModule`, `Fit = soft×poidsSoft + hard×poidsHard`, poidsHard=0 si
  pas de QCM/tentative. Résolution des poids : offre → (company, différé D6) →
  job_role_profile → défauts par profil (tableau §4.3).
- [ ] `FitScore` : + `hardSkillScore`, `coverageRatio`, `partialData` (bool,
  mécanisme 2 : seuils 60/70 %) — migration `V24`. Exposer dans les réponses
  deck/feed/détail (`partialData` → badge « données partielles », masquage côté
  client si sans QCM sous 70 %).
- [ ] Recalcul déclenché **à la soumission de tentative** (D2) : listener sur
  l'événement de tentative → recompute de la paire.
- [ ] Groq relégué : conserver l'adaptateur pour A/B ou résumé IA (D3) ;
  sélection par propriété `recruitment.fitscore.engine=deterministic|groq`.

## Phase 3 — Alerte « hard skills manquant » + affichage (CdC §6-7)

- [ ] `GET /job-offers/{id}` (recruteur, DRAFT) : champ `hardSkillsAlert`
  (NONE/INFO/MODERATE/STRONG) dérivé de `poidsHardAttendu` de la bande — jamais
  utilisé dans le calcul. Profil ARTISTIQUE → message informatif portfolio,
  pas d'alerte (CdC §6).
- [ ] Étiquettes de liste candidats (CdC §7) : le feed expose déjà
  `fitScore`/`softSkillsScore` — ajouter `hardSuccessRate` quand un QCM existe ;
  jamais de doublon Fit=Soft (offre sans QCM → étiquette unique).
- [ ] Résumé IA candidat (profil Artistique, portfolio seul) : phrase dédiée dans
  le prompt Groq existant — différable (D6).

## Phase 4 — Tests & guardrails (transverse, à chaque phase)

- [ ] Tests unitaires domaine : invariants `JobRoleProfile`, résolution d'héritage
  des poids, calculateur déterministe (cas §3.3 : 90×1.0=90, 90×0.4=36 ;
  Poids_Hard=0 sans QCM ; seuils 60/70).
- [ ] Tests d'intégration : recompute à la tentative, badge partialData.
- [ ] `ApiContractRouteParityTest` + `RecruitmentSecurityAnnotationTest` : chaque
  nouvelle route entre au contrat `contracts/recruitment.openapi.yaml` + compte.
- [ ] **Leçon du 18/07** : ajouter un test CI qui boote le contexte JPA contre un
  Postgres Testcontainers **migré par Flyway seul** (ddl-auto validate) — aurait
  attrapé la colonne `monitoring_consent` manquante.
- [ ] Bruno : nouveaux dossiers Demo (référentiel, alerte, badge couverture).

## Hors périmètre v1 (différé, à re-planifier après l'atelier RH)

- `company_profile` (niveau 2 d'héritage) — D6.
- **`offer.overrides` (niveau 3 d'héritage) — décision D-E du 2026-08-04.**
  Ajouté rétroactivement : ce niveau ne figurait **dans aucune décision écrite**.
  Il n'avait pas été différé, il avait été oublié — l'audit
  (`FITSCORE_REMEDIATION.md` §5) l'a relevé. Le CdC §8.3 le prévoit explicitement
  (« offer — porte un champ optionnel overrides »), et §9 en fait un geste
  recruteur (« ajuster manuellement les curseurs de pondération avant
  publication »). Reporté au même titre que le niveau 2, et pour la même raison :
  le niveau 1 seul produit déjà un score cohérent.
  Point non tranché par le CdC lui-même, à régler avant de le planifier : quand un
  override ajoute « +5 % sur la Régulation émotionnelle », **d'où viennent ces 5
  points ?** Les deux sommes doivent rester à 100 % (contraintes `CHECK` en base) ;
  aucune règle de renormalisation n'est donnée.
- Évaluation Portfolio/Mixte du profil Artistique + grille structurée.
- ~~Versioning/audit des profils de pondération (CdC §10) — prévoir simplement
  `updated_at` + `calibrated` dès la V20~~ → **`updated_at` livré le 2026-08-04**
  (migration V52, tâche F11). L'engagement pris ici n'avait été tenu qu'à moitié :
  seul `calibrated` existait. C'est le prérequis du balayage de péremption (F12).
- QCM décliné par niveau (CdC §10, point ouvert).

## Ordre d'exécution & estimation

| Étape | Contenu | Volume |
|---|---|---|
| 1 | Phase 0 restante (generate + canal OTP prod) | ½ j |
| 2 | Phase 1 (référentiel + seed matrice) | 1,5 j |
| 3 | Phase 2 (modules + couverture + calcul déterministe) | 2 j |
| 4 | Phase 3 (alertes + affichage) | 1 j |
| 5 | Phase 4 (tests, contrat, Bruno) | en continu |

Total ≈ 5 j homme backend, **après** les décisions D1-D8 du 19/07.
