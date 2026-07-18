# Référence des paramètres — API Recruitment

Où peuvent vivre les données d'une requête :
- **Path param** — le `{id}` dans l'URL (ex. `/job-offers/{id}`) : *quelle* ressource.
- **Query param** — après le `?` (ex. `?status=ACTIVE&page=0`) : filtres/options.
- **Body (JSON)** — les données envoyées en POST/PATCH.
- **Header** — métadonnées. Surtout **`X-Dev-User`** = *qui je suis* (l'utilisateur
  authentifié). L'API ne met JAMAIS "qui je suis" dans le body — elle le lit dans ce header.
  Les callbacks utilisent **`X-Callback-Secret`** à la place.

> Règle d'or : l'**acteur** (le candidat OU le recruteur qui fait l'action) vient
> toujours du header `X-Dev-User`, jamais du body. Le body ne contient que *l'autre
> partie* et le contexte (offre, etc.).

---

## Job offers
| Méthode + chemin | Path | Query | Body | Qui (X-Dev-User) |
|---|---|---|---|---|
| `POST /job-offers` | — | — | `title, description, contractType, workplaceType, experienceLevel, city, country, remote` + optionnels `companyName, salaryMin, salaryMax, currency, fieldOfWork, responsibilities, minimumQualifications, preferredQualifications, whatWeOffer, howToApply, companyInfo, assessmentId, openToInternational` (créée ACTIVE) | recruteur |
| `GET /job-offers/{id}` | `id` | — | — | candidat/public |
| `GET /job-offers` | — | `recruiterId?, status?, q?, location?, contractType?, experienceLevel?, page?, size?` | — | candidat/public |
| `GET /recruiters/me/job-offers` | — | `status?, page?, size?` | — | recruteur |
| `PATCH /job-offers/{id}` | `id` | — | tout champ de l'offre (partiel : champs absents inchangés ; `assessmentId: null` désassigne) | recruteur |
| `PATCH /job-offers/{id}/status` | `id` | — | `status` (DRAFT→ACTIVE→HIDDEN→CLOSED) | recruteur |
| `DELETE /job-offers/{id}` | `id` | — | — | recruteur |

## Applications (candidatures)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /applications` | — | — | `jobOfferId` | candidat |
| `GET /candidates/me/applications` | — | `status?, page?, size?` | — | candidat |
| `GET /job-offers/{jobOfferId}/applications` | `jobOfferId` | `status?, page?, size?` | — | recruteur |
| `GET /applications/{id}` | `id` | — | — | — |
| `PATCH /applications/{id}/status` | `id` | — | `status` (PENDING→SHORTLISTED→APPROVED/REJECTED) | recruteur |

## Swipes
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /swipes` | — | — | `targetId, targetType ("JOB_OFFER"\|"CANDIDATE"), jobOfferId?, direction ("LIKE"\|"PASS")` | candidat OU recruteur |

- **Candidat → offre** : header = candidat ; body `targetId = offerId`, `targetType = "JOB_OFFER"`, `jobOfferId` inutile.
- **Recruteur → candidat** : header = recruteur ; body `targetId = candidatId`, `targetType = "CANDIDATE"`, `jobOfferId` **obligatoire**.
- Le candidatId/recruteurId de l'acteur = le header, pas le body.

## Matches
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `GET /candidates/me/matches` | — | `page?, size?` | — | candidat |
| `GET /recruiters/me/matches` | — | `jobOfferId?, page?, size?` | — | recruteur |

## Assessments (tests)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /assessments` | — | — | `title, questions:[{ text, options[4], correctOptionIndex(0-3) }]` | recruteur |
| `GET /assessments/{id}` | `id` | — | — | — |
| `GET /assessments/mine` | — | `page?, size?` | — | recruteur |
| `DELETE /assessments/{id}` | `id` | — | — | recruteur |

## Assessment attempts (passage de test)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /assessment-attempts` | — | — | `assessmentId, jobOfferId, answers:[int]` | candidat |
| `GET /assessment-attempts/{id}` | `id` | — | — | — |
| `GET /assessment-attempts` | — | `jobOfferId` (**requis**), `page?, size?` | — | recruteur |

## Fit score (score IA)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `GET /fit-scores` | — | `candidateId` (**requis**), `jobOfferId` (**requis**) | — | — |

## Job opportunity offers (offre recruteur → candidat)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /job-opportunity-offers` | — | — | `candidateId, jobOfferId` | recruteur |
| `GET /job-opportunity-offers/{id}` | `id` | — | — | — |
| `POST /job-opportunity-offers/{id}/confirm` | `id` | — | — | candidat |
| `POST /job-opportunity-offers/{id}/verify-otp` | `id` | — | `otpCode` | candidat |
| `POST /job-opportunity-offers/{id}/reject` | `id` | — | — | candidat |

## Identity verification (anti-fraude facial)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /identity-verifications` | — | — | `candidateId, jobOfferId` | recruteur |
| `GET /identity-verifications/{id}` | `id` | — | — | — |

## Payments (visioconférence)
| Méthode + chemin | Path | Query | Body | Qui |
|---|---|---|---|---|
| `POST /payments` | — | — | `candidateId, matchId, cardLast4, cardType` | recruteur |
| `POST /payments/{id}/verify-otp` | `id` | — | `otpCode` | recruteur |
| `GET /payments/{id}` | `id` | — | — | recruteur |

## Callbacks (services externes — pas de X-Dev-User, mais X-Callback-Secret)
| Méthode + chemin | Header | Body |
|---|---|---|
| `POST /callbacks/fit-score` | `X-Callback-Secret` | `candidateId, jobOfferId, score (0-100)` |
| `POST /callbacks/integrity` | `X-Callback-Secret` | `attemptId, status (PENDING\|VALIDATED\|NOT_VALIDATED)` |
| `POST /callbacks/identity-verification` | `X-Callback-Secret` | `verificationId, status (PENDING\|COMPLETED_SUCCESS\|COMPLETED_FAILURE)` |

---

## Valeurs d'énumération autorisées
- **ContractType** : FULL_TIME, PART_TIME, CONTRACT, TEMPORARY, APPRENTICESHIP, VOLUNTEER
- **WorkplaceType** : ON_SITE, REMOTE, HYBRID, FLEXIBLE
- **ExperienceLevel** : JUNIOR, MID, SENIOR, EXECUTIVE
- **JobOfferStatus** : DRAFT, ACTIVE, HIDDEN, CLOSED
- **ApplicationStatus** : PENDING, SHORTLISTED, APPROVED, REJECTED
- **SwipeDirection** : LIKE, PASS

> Envoyer une valeur hors de ces listes (ou un body mal formé) renvoie **400**, pas 500.
