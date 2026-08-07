# Run the app & try the recruitment flow (Phase A — dev identity)

Backend = standalone Recruitment API (`dev` profile, `X-Dev-User` simulated identity).
The app switches between the seeded **candidate** and **recruiter** with the in-app mode
toggle — no login yet.

Seeded identities (header `X-Dev-User`):
- Recruiter `11111111-1111-1111-1111-111111111111`
- Candidate `22222222-2222-2222-2222-222222222222`

---

## 1. Start the backend (once)

```bash
# Postgres (port 5433, db zennyt, schema recruitment)
docker start zennyt-pg  ||  docker run -d --name zennyt-pg \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=zennyt -p 5433:5432 postgres:16
docker exec zennyt-pg psql -U postgres -d zennyt -c "CREATE SCHEMA IF NOT EXISTS recruitment;"

# API (Java 21) — from backend/
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev      # macOS/Linux/Git-Bash
# Windows PowerShell:  .\mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

Wait for `Started ZennytApplication`. Health: <http://localhost:8080/actuator/health> → `{"status":"UP"}`.
Demo data (3 ACTIVE offers + 1 assessment + fit score) is seeded automatically.

Flutter is at `C:\src\flutter\bin\flutter.bat` (add `C:\src\flutter\bin` to PATH, or call it fully).

---

## 2A. Try it on the **desktop / Chrome** (fastest)

```bash
cd mobile_preview
flutter run -d chrome      # default API base = http://localhost:8080/api/v1 (already correct)
```

---

## 2B. Try it on an **Android phone** — Option 1: web app in the phone's browser (NO Android SDK needed)

Works today. Phone and PC must be on the **same Wi-Fi**. This PC's LAN IP is **`192.168.1.14`**.

PowerShell — put it all on **one line** (no `\` continuation, that's bash):

```powershell
cd mobile_preview
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090 --dart-define=API_BASE_URL=http://192.168.1.14:8080/api/v1
```

Then on the phone open Chrome →  **http://192.168.1.14:8090**

If it doesn't load / can't reach the API:
- Allow inbound TCP **8090** and **8080** through Windows Defender Firewall (a first-run
  prompt may appear — click *Allow*). Quick one-off rules (PowerShell as admin):
  ```powershell
  New-NetFirewallRule -DisplayName "Flutter web 8090" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8090
  New-NetFirewallRule -DisplayName "Zennyt API 8080"  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080
  ```
- Confirm the IP is still `192.168.1.14` (`ipconfig` → Wi-Fi IPv4). If it changed, use the new one.

## 2B. Option 2: native APK (real app) — requires Android Studio / Android SDK

The Android project is already scaffolded (`android/`), with INTERNET permission and
`usesCleartextTraffic="true"` so it can call the `http://` dev API.

1. Install **Android Studio** (installs the Android SDK + accepts licenses):
   <https://developer.android.com/studio>. Then `flutter doctor --android-licenses`.
2. Build a debug APK pointing at this PC, and install it on the phone (one line):
   ```powershell
   cd mobile_preview
   flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.14:8080/api/v1
   # output: build/app/outputs/flutter-apk/app-debug.apk  → copy to phone & install
   ```
   Or, with the phone plugged in via USB (USB debugging on) and same Wi-Fi (one line):
   ```powershell
   flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.168.1.14:8080/api/v1
   ```
   (`flutter devices` lists the id.) Same firewall note as Option 1 for port 8080.

> **Android emulator** instead of a physical phone: the host is reached at `10.0.2.2`, so use
> `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.

---

## 3. What to click (the wired recruitment flow)

**Candidate mode** (default):
- **Fits → Job Offers**: live offers from `GET /job-offers`. Swipe ♥/✗ → real `POST /swipes`.
- Tap a card → **Job Detail** (real data) → **Start assessment** → submits `POST /applications`
  then opens the test → **Finish** → `POST /assessment-attempts` shows the real score.
- **♥ icon (top bar of Fits) → Matches**: `GET /candidates/me/matches`.
- **Chats → a conversation with a Job Opportunity card → Confirm offer** → enter the OTP →
  **Continue**: runs the real offer→confirm→verify-otp chain (status `CONFIRMED`).
  **Reject offer** → real reject.

**Recruiter mode** (flip the in-app candidate/recruiter toggle):
- **Careers**: your offers (`GET /recruiters/me/job-offers`) + tests (`GET /assessments/mine`).
- **Add a job offer → Post**: `POST /job-offers` then publish `PATCH …/status ACTIVE` — the new
  offer then appears for candidates.
- **Add assessment → Create a test** (title → 1 question + 4 answers + mark correct) →
  `POST /assessments`. ("Generate a test with AI" is intentionally **not** wired.)

## Known limits (no backend yet)
- **Fits → "Professionnels"** tab (recruiter swiping candidates): empty — no candidate-feed endpoint.
- **Assessment question text** is mock (the API stores questions but doesn't return them); the
  **answers** are submitted for real.
- **Payment / video-call** screens: not wired (left mock by request).
- Home feed, notifications, chat messages: Engagement context — no backend, still mock.
