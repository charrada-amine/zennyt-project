# End-to-end journey — backend + Flutter app

Full E2E pass over the product: from account creation to being recruited, plus the
gap-fill features (referral, wallet, plans/store purchases, candidate search, legal
documents). Two layers, both reproducible:

1. **Backend HTTP E2E** — every mobile-facing endpoint in a realistic journey
   (`tooling/e2e/journey_e2e.py`).
2. **Flutter UI E2E** — the real app driven on an iOS simulator against the live
   backend, screenshot per screen (`mobile/integration_test/e2e_screenshot_journey_test.dart`
   + `mobile/test_driver/integration_test.dart`).

---

## 1. Environment

```bash
# Postgres (Homebrew, or `docker compose up -d postgres`)
brew services start postgresql@17
psql -d postgres -c "CREATE ROLE postgres LOGIN SUPERUSER PASSWORD 'postgres';"
psql -d postgres -c "CREATE DATABASE zennyt OWNER postgres;"

# Backend (dev profile seeds job positions + data)
cd backend
JAVA_HOME=/opt/homebrew/opt/openjdk@21 DB_USER=postgres DB_PASSWORD=postgres \
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# -> http://localhost:8080/actuator/health = {"status":"UP"}
```

> ⚠️ Run `./mvnw clean` first if `target/` holds migrations from another branch —
> stale copies make Flyway fail with “Found more than one migration with version …”.

Simulator: an iOS simulator booted (`xcrun simctl list devices booted`). The app targets
`http://localhost:8080/api/v1` by default on iOS.

---

## 2. Backend HTTP E2E

```bash
python3 tooling/e2e/journey_e2e.py
```

Result on this run — **61 PASS / 0 FAIL / 3 BLOCKED** (report: `docs/e2e/backend-report.json`).
It registers a candidate + recruiter, runs onboarding, creates a job offer, plays a game,
swipes to a mutual match, creates and takes a hard-skills test, reads results, sends an
opportunity offer, invites a referral, exercises the wallet, verifies a store purchase,
reads plans/subscription, updates preferences, fetches legal docs, and drives the social +
comms + help endpoints.

**BLOCKED (need external services/decisions, not failures):**
- `job-opportunity-offers.confirm` — OTP code delivery (SMS/e-mail) is not wired.
- `users.email` change → verify — code delivered by Resend (no API key configured).
- `calls.start` — call media requires Agora/WebRTC credentials.

---

## 3. Flutter UI E2E

```bash
cd mobile
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/e2e_screenshot_journey_test.dart -d <simulator-id>
```

The journey: onboarding → login (seeded `ui-e2e@example.test`) → Home → Fits → Progress →
Search → Notifications → Profile menu. Screenshots land in `docs/e2e/screenshots/`.

### Screens captured

All 14 screens are captured in `docs/e2e/screenshots/`:

| Splash | Onboarding | Login | Home (live feed) |
|---|---|---|---|
| ![splash](screenshots/01_splash.png) | ![ob](screenshots/02_onboarding_1.png) | ![login](screenshots/03_login.png) | ![home](screenshots/05_home.png) |

The **Home** feed shows the post created by the backend E2E run (`Hello from E2E`, poll A/B,
1 comment, 1 like) — real data flowing backend → app.

| Fits (Discover) | Progress | Search | Notifications |
|---|---|---|---|
| ![fits](screenshots/06_fits.png) | ![progress](screenshots/07_progress.png) | ![search](screenshots/08_search.png) | ![notifs](screenshots/09_notifications.png) |

**Fits** shows the offers returned by `GET /job-offers/matching-deck` (fixed — see findings).

| Profile & Settings | Wallet | Referral | Plans & Pricing |
|---|---|---|---|
| ![settings](screenshots/10_profile_settings.png) | ![wallet](screenshots/11_wallet.png) | ![referral](screenshots/12_referral.png) | ![plans](screenshots/13_plans.png) |

| Terms of Use | Language | Accessibility | Hired candidates |
|---|---|---|---|
| ![terms](screenshots/14_terms.png) | ![lang](screenshots/15_language.png) | ![a11y](screenshots/16_accessibility.png) | ![hired](screenshots/17_hired_candidates.png) |

The **Terms** screen content is fetched live from `GET /legal/terms-of-use`.

---

## 4. Findings

Found by this E2E run and **fixed in the same branch**:

1. **Fits could not load offers** — `fits_repository_impl.dart` called routes removed from the
   contract (`/swipes`, `/swipes/targets`, `/recruiters/me/matches`, and parsed the paginated
   `GET /job-offers` as a list). Rewired to `GET /job-offers/matching-deck`,
   `GET /job-offers/{id}/candidates/matching-deck`, `POST /job-offers/{id}/swipes` (+ recruiter
   variant) and `GET /job-offers/{id}/matches`. Fits now renders offers (screenshot `06_fits`).
2. **Duplicate Hero tag crash** — opening Profile & Settings threw *“multiple heroes share the
   same tag … Default Hero tag for Cupertino navigation bars”*. Fixed in
   `shared/widgets/platform_app_bar.dart`: unique `heroTag` with `transitionBetweenRoutes: false`.
3. **Stale `target/` migrations** — `./mvnw clean` needed before `spring-boot:run` (a stale
   `V27__games_continuous_attention.sql` shadowed the source set and broke Flyway).

Still open (documented, not fixed):

4. **Locale inconsistency** — onboarding renders in French while the bottom navigation renders in
   English in the same session.
5. **In-app purchases** use a provisional stub receipt verifier; real Apple/Google validation
   and store product setup remain.

## 5. Blocked / not covered

- OTP-gated flows (opportunity confirmation, e-mail/phone change) and store purchases with
  real Apple/Google validation (stub verifier).
- Agora/WebRTC call media.
- Admin console, callbacks, and analytics events beyond the read endpoints.

## 6. How to extend

- Add steps to `tooling/e2e/journey_e2e.py` as endpoints land; the report is regenerated each
  run (`docs/e2e/backend-report.json`).
- Add taps + `binding.takeScreenshot('NN_name')` in the integration test to capture more
  screens; screenshots are auto-saved by `test_driver/integration_test.dart`.
