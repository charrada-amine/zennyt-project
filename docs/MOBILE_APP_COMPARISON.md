# Mobile app comparison — current branch vs. REC-04 (`mobile/zennyt`)

Deep dive requested after porting Fits and Search: is "Careers" (and the
candidate side generally) really the same feature in both apps? **No.** The
two apps diverged much further than tab styling — one tab in particular
("Careers") points to a completely different, much larger feature in each.

Scope: `mobile/` on `integration-recruitment-align` (current, package
`com.example.zenny`) vs. `mobile/zennyt/` on `feature/REC-04-mobile-integration`
(package `com.example.zennyt`, the one with the "Dev Login" screen from
earlier in this session).

## Tab-by-tab

| Tab | Current app (`mobile/`) | REC-04 (`mobile/zennyt`) |
|---|---|---|
| **Home** | Fully built: static social-feed mock (`HomeRepository` returns 3 hardcoded `FeedPost`s — "Anna Mary", "Millie Brown" — no backend call at all). Same for both roles. | `_PlaceholderPage(label: 'Home')`. Literally one `Center(Text(...))` widget. Not started. |
| **Fits** | ✅ Now real — ported from REC-04 this session (`FitsPage`, `TinderCard`, swipe deck, matches). | Real: swipe deck (candidate ↔ job offers, recruiter ↔ candidates), tinder-card UI, match celebration dialog. Source of what's now in the current app. |
| **"Careers"** *(3rd tab)* | **Always** shows the cognitive-games hub (`GamesHubScreen`: Planifik, Move Fast, Predictive Puzzle, Task Scheduling, Investigate) — same content for candidate and recruiter. Label is hardcoded `'Careers'` (`AppStrings.tabProgress`) regardless of role. **No games feature exists anywhere in REC-04** — this is a separate initiative bolted onto the current branch, unrelated to REC-04's scope. | **Role-branched**, and it's a different *feature* per role, not just a label swap: <br>• **Recruiter → `RecruiterHomePage`**: their operational hub — a "Tests" section (assessments they created, "+" to create a new one, results/stats) and a "Job Offers" section (their postings, "+" to create, each pushing into a full detail page with tabs: description, company, assessment). Backs onto a ~40-file `jobs` feature: multi-step job-creation wizard, assessment CRUD (create/edit/list/detail, AI generation, shareable link), `HardSkillsScoresPage` (per-offer candidate results). <br>• **Candidate → `CandidateProgressPage`**: their application tracker — `GET /candidates/me/applications` resolved against job titles, status badges (En attente / Présélectionné / Approuvé / Refusé), pull-to-refresh. |
| **Search** | ✅ Now real — ported from REC-04 this session (`SearchCandidatePage`, filters, `FitScoresGrid`). | Real: same search + filter UI, source of what's now in the current app. |
| **Notifications** | `PlaceholderScreen` (generic "coming soon" widget). | `_PlaceholderPage(label: 'Notifications')`. Also unbuilt — `features/notifications/` is only `.gitkeep` files, no implementation exists to port. **Nothing to do here**; both apps are equally unbuilt on this tab. |

## What this means concretely

**"Careers" is the single biggest gap.** In REC-04 it's the recruiter's entire
day-to-day workspace — create a job offer, attach/create an assessment,
publish, watch applicants come in, see hard-skill results — and the
candidate's application-status tracker. In the current app, that same tab
slot was repurposed for an unrelated cognitive-games feature, and none of the
job/assessment-management or application-tracking screens exist at all
outside `profile_settings` (which only covers editing the recruiter's *own*
profile, not managing offers).

Concretely, **recruiters currently have no way to create a job offer or an
assessment from the app**, and **candidates have no way to see their
application status** — both of these are core to the recruitment flows this
whole integration effort is about, and both already exist, fully built, in
REC-04.

**Home and Notifications are placeholders in both apps** — no regression
there, just two features neither app has gotten to yet. Home's mock feed in
the current app looks like unrelated scaffolding (maybe copied from a
different template) rather than a first pass at a real feature.

**Games has no REC-04 counterpart at all.** It's not a port gap — it's new
work done directly on this branch, sitting in a tab slot that collides with
"Careers" ' label and (for recruiters) hides the actual job-management
feature entirely.

## Suggested next step

Porting "Careers" properly means bringing over the `jobs` feature (job CRUD,
assessment CRUD, `HardSkillsScoresPage`) and the `applications` feature
(`CandidateProgressPage`) — the same verbatim-UI + re-wired-data-layer
approach used for Fits and Search, but roughly 4-5x the file count (~40 files
in `jobs` alone) and a wider backend-contract surface (job creation,
assessment creation/AI-generation, applications list, results). This is a
substantially bigger job than Fits/Search and deserves its own scoping pass
(job creation first? results page first? both roles at once or recruiter
first?) rather than starting blind.

Where does the Games hub go? It's real, working functionality — worth
deciding whether it keeps the "Careers" tab label/slot (conflicting with
REC-04's meaning) or moves to its own slot once the real Careers content
lands, rather than deciding that silently mid-port.
