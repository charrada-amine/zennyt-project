# Backend demo — speaker notes (Recruitment API + Bruno)

Talking points for the meeting. Show **Bruno** on screen, follow the order in §4, and use
§3 to explain *where each parameter lives and why*. Full reference: `PARAMETERS.md`.

---

## 1. 30-second pitch

> "My part is the **Recruitment** backend — the matching engine behind Progress Careers.
> It's a Spring Boot 3 / Java 21 service, one **bounded context** in the DDD monolith. It
> exposes a REST API under `/api/v1` for everything in the hiring flow: job offers,
> swipes & matches, applications, skill assessments, AI fit-scores, recruiter→candidate
> offers with OTP, identity verification, and the video-call payment. Data is in
> PostgreSQL, schema `recruitment`."

Key design point to mention:
- **No cross-context foreign keys.** Recruitment references users **only by UUID**. The
  actual user accounts live in the **Identity** context (another squad). Clean DDD boundary —
  the two schemas stay independent.

---

## 2. How auth works in the demo (important to say up front)

- In production, a request carries a **JWT** and the backend reads *who you are* from the
  token (`sub` claim = the user's UUID).
- Identity isn't merged yet, so for the demo I **simulate** the logged-in user with a header:
  **`X-Dev-User: <uuid>`**. That's the only difference between demo and prod — same endpoints.
- So in Bruno every request has an `X-Dev-User` header = the candidate's or recruiter's UUID.

---

## 3. The parameter model — *where data lives and why* (the core explanation)

Every request puts its data in one of **4 places**:

| Where | Looks like | Means | Example |
|---|---|---|---|
| **Path param** | `/job-offers/{id}` | *which* resource | the offer's id |
| **Query param** | `?status=ACTIVE&page=0` | filters / options | search & pagination |
| **Body (JSON)** | POST/PATCH payload | the data to create/change | a new offer's fields |
| **Header** | `X-Dev-User: <uuid>` | metadata / *who I am* | the authenticated actor |

**The golden rule (say this clearly):**
> "The **actor** — the candidate or recruiter performing the action — **always comes from the
> `X-Dev-User` header, never from the body.** The body only carries *the other party* and the
> *context* (which offer, which candidate). The API never trusts the client to say 'I am user X'."

Concrete example — a candidate swipes right on an offer:
- Header `X-Dev-User` = **the candidate** (who is swiping).
- Body = `{ targetId: <offerId>, targetType: "JOB_OFFER", direction: "LIKE" }` (what they swiped).
- The backend fills `candidateId` from the header, not the body.

---

## 4. Suggested live demo order (the happy path)

Run these in Bruno in order — it tells a story end-to-end. Call out the params per step.

| # | Request | Who (`X-Dev-User`) | Params to point at |
|---|---|---|---|
| 1 | `POST /job-offers` | recruiter | **Body**: `title, description, contractType, workplaceType, experienceLevel, city, country, remote`. Returns the new offer **id**. |
| 2 | `PATCH /job-offers/{id}/status` | recruiter | **Path** `id` + **Body** `status: ACTIVE` (DRAFT→ACTIVE makes it public). |
| 3 | `GET /job-offers?q=&contractType=&page=0` | candidate | **Query** filters + pagination — no body. |
| 4 | `GET /job-offers/{id}` | candidate | **Path** `id` only — fetch one offer. |
| 5 | `POST /applications` | candidate | **Body** `jobOfferId`. The candidateId comes from the header. |
| 6 | `POST /swipes` | candidate | **Body** `targetId(=offerId), targetType:"JOB_OFFER", direction:"LIKE"`. |
| 7 | `POST /swipes` | recruiter | **Body** `targetId(=candidateId), targetType:"CANDIDATE", jobOfferId, direction:"LIKE"` → now both liked. |
| 8 | `GET /candidates/me/matches` | candidate | The two-sided LIKE produced a **match**. |
| 9 | `POST /assessments` | recruiter | **Body** `title, questions:[{text, options[4], correctOptionIndex}]`. |
| 10 | `POST /assessment-attempts` | candidate | **Body** `assessmentId, jobOfferId, answers:[int]` → returns `score, passed`. |
| 11 | `GET /fit-scores?candidateId=&jobOfferId=` | — | The AI **fit %** (both ids are required **query** params). |
| 12 | `POST /job-opportunity-offers` | recruiter | **Body** `candidateId, jobOfferId` — recruiter sends an offer. |
| 13 | `POST /job-opportunity-offers/{id}/confirm` | candidate | **Path** `id` — candidate accepts. |
| 14 | `POST /job-opportunity-offers/{id}/verify-otp` | candidate | **Path** `id` + **Body** `otpCode` (the SMS step). |

> If time is short, demo **1 → 3 → 6 → 7 → 8** (offer → search → mutual swipe → match). That's
> the core "Tinder-for-jobs" loop in under a minute.

---

## 5. Things to highlight while clicking

- **Pagination everywhere**: list endpoints take `page` / `size` and return a page object.
- **Enums are strict**: sending a value outside the allowed set returns a clean **400**, not a
  500. Show one on purpose if asked:
  - ContractType: `FULL_TIME, PART_TIME, CONTRACT, TEMPORARY, APPRENTICESHIP, VOLUNTEER`
  - WorkplaceType: `ON_SITE, REMOTE, HYBRID, FLEXIBLE`
  - ExperienceLevel: `JUNIOR, MID, SENIOR, EXECUTIVE`
  - Status (offer): `DRAFT, ACTIVE, HIDDEN, CLOSED`
- **Callbacks** (`/callbacks/...`) are how external services report back (fit-score computed,
  integrity check, identity verification). They don't use `X-Dev-User` — they use a shared
  secret header `X-Callback-Secret`. (Mention only if asked.)
- **Idempotency on swipes**: a candidate can't double-swipe the same (actor, candidate, offer) —
  enforced by a unique constraint.

---

## 6. Likely questions — quick answers

- **"Why no login in the demo?"** Identity (auth) is a separate context built by another squad;
  not merged yet. I simulate the user with `X-Dev-User`; swapping to real JWT is a one-line
  change because the controllers already read the caller the same way (`principal.getName()`).
- **"Where do candidate/recruiter accounts live?"** In the Identity schema. Recruitment only
  stores their UUIDs — no FK across contexts (DDD boundary).
- **"How is the fit score computed?"** An external AI service computes it and posts it back via
  `POST /callbacks/fit-score`; the API just stores and serves it.
- **"Is it tested?"** Yes — the full happy path runs green in this Bruno collection
  (every request has assertions), plus unit tests on the backend.

---

## 7. Cheat-sheet to keep open beside Bruno

- Actor = **header** `X-Dev-User`. Other party + context = **body**. Which resource = **path**.
  Filters/paging = **query**.
- Full table of every endpoint and its params: **`PARAMETERS.md`** (same folder).
