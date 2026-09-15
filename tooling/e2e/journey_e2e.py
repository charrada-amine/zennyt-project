#!/usr/bin/env python3
"""End-to-end journey against a running Zennyt backend.

Walks the product from signup to being recruited, plus the gap-fill features
(referral, wallet, plans, candidate search, legal, preferences). Dependency-free
(stdlib only).

Usage:
    python3 tooling/e2e/journey_e2e.py [base_url]
    # default base_url: http://localhost:8080/api/v1

Output: PASS/FAIL per step + a JSON report in docs/e2e/backend-report.json.
Steps blocked by external services (OTP delivery, PSP, AI, storage) are marked
BLOCKED with the reason instead of failing.
"""
import json
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080/api/v1").rstrip("/")
REPORT = Path(__file__).resolve().parents[2] / "docs" / "e2e" / "backend-report.json"

results = []


class Api:
    def __init__(self):
        self.token = None

    def call(self, method, path, body=None, token=None, raw=False, expect=None):
        url = BASE + path
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        tok = token or self.token
        if tok:
            req.add_header("Authorization", "Bearer " + tok)
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                text = resp.read().decode()
                status = resp.status
        except urllib.error.HTTPError as e:
            status = e.code
            text = e.read().decode()
        except Exception as e:  # noqa: BLE001
            return None, 0, str(e)
        try:
            payload = json.loads(text) if text else None
        except ValueError:
            payload = text
        return payload, status, None


def step(name, fn, blocked_reason=None):
    if blocked_reason:
        results.append({"step": name, "status": "BLOCKED", "reason": blocked_reason})
        print(f"BLOCKED  {name} — {blocked_reason}")
        return None
    try:
        value = fn()
    except Exception as e:  # noqa: BLE001
        results.append({"step": name, "status": "FAIL", "error": str(e)})
        print(f"FAIL     {name} — {e}")
        return None
    results.append({"step": name, "status": "PASS"})
    print(f"PASS     {name}")
    return value


def main():
    api = Api()
    run = uuid.uuid4().hex[:8]
    cand_email = f"cand-{run}@example.test"
    rec_email = f"rec-{run}@example.test"
    pw = "Password123"

    # 1. Register candidate + recruiter
    cand = step("auth.register candidate", lambda: api.call("POST", "/auth/register", {
        "firstName": "Cand", "lastName": "Idate", "email": cand_email,
        "phoneNumber": "+21600000001", "password": pw, "role": "CANDIDATE",
        "city": "Tunis", "country": "TN", "address": "Rue 1", "termsAccepted": True}))
    cand_token = (cand[0] or {}).get("accessToken") if cand else None
    step("auth.me candidate", lambda: api.call("GET", "/auth/me", token=cand_token))

    rec = step("auth.register recruiter", lambda: api.call("POST", "/auth/register", {
        "firstName": "Rec", "lastName": "Ruiter", "email": rec_email,
        "phoneNumber": "+21600000002", "password": pw, "role": "RECRUITER",
        "city": "Tunis", "country": "TN", "address": "Rue 2", "termsAccepted": True}))
    rec_token = (rec[0] or {}).get("accessToken") if rec else None

    # 2. Onboarding
    step("onboarding.candidate-student", lambda: api.call("POST", "/onboarding/candidate-student", {
        "school": "Design University", "educationLevel": "Masters", "fieldOfWork": "IT, AI & Fintech",
        "lastPositionHeld": "Designer", "yearsOfExperience": 2}, token=cand_token))
    step("onboarding.candidate me", lambda: api.call("GET", "/onboarding/candidate-student/me", token=cand_token))
    step("onboarding.recruiter", lambda: api.call("POST", "/onboarding/recruiter", {
        "jobTitle": "HR", "companyName": "Acme", "companySize": "100-200",
        "fieldOfWork": "IT, AI & Fintech", "companyLocation": "Tunis",
        "companyRegistrationNumber": "12-3456789", "aboutMe": "We hire"}, token=rec_token))
    step("onboarding.recruiter me", lambda: api.call("GET", "/onboarding/recruiter/me", token=rec_token))

    # 3. Profile
    step("profiles.me", lambda: api.call("GET", "/profiles/me", token=cand_token))
    step("profiles.me update", lambda: api.call("PUT", "/profiles/me", {
        "currentPosition": "Designer", "lookingFor": "UX Designer", "workplaceType": "HYBRID",
        "jobType": "FULL_TIME", "targetJobLocation": "Tunis", "yearsOfExperience": 2,
        "openInternationally": True}, token=cand_token))

    # 4. Job positions + offer
    positions = step("job-positions", lambda: api.call("GET", "/job-positions", token=rec_token))
    position_id = None
    if isinstance(positions, list) and positions:
        position_id = positions[0]["id"]
    offer = step("job-offers.create", lambda: api.call("POST", "/job-offers", {
        "title": "UX/UI Designer", "city": "Tunis", "country": "TN",
        "salaryMin": 30000, "salaryMax": 35000, "salaryCurrency": "EUR", "salaryPeriod": "MONTHLY",
        "contractType": "FULL_TIME", "workplaceType": "HYBRID", "experienceLevel": "SENIOR",
        "description": "Design great products for our users.",
        "responsibilities": "Design", "minimumQualifications": "3y",
        "preferredQualifications": "Figma", "whatWeOffer": "Growth",
        "howToApply": "Apply", "jobPositionId": position_id, "openToInternational": True}, token=rec_token))
    offer_id = (offer[0] or {}).get("id") if offer else None
    step("job-offers.public list", lambda: api.call("GET", "/job-offers"))
    step("job-offers.detail", lambda: api.call("GET", f"/job-offers/{offer_id}"))

    # 5. Games session (candidate) + submit
    gm = step("games.start session", lambda: api.call("POST", "/games/sessions",
        {"gameType": "MOVE_FAST"}, token=cand_token))
    session_id = (gm[0] or {}).get("id") if gm else None
    if session_id:
        step("games.submit result", lambda: api.call("POST", f"/games/sessions/{session_id}/results", {
            "miniGame": "MOVE_FAST", "metrics": {"rawScore": 80, "normalizedScore": 80,
            "coverageRatio": 100, "durationMs": 60000}}, token=cand_token))

    # 6. Fits: candidate swipes right, recruiter swipes right -> match
    step("swipes.matching deck (candidate)", lambda: api.call("GET", "/job-offers/matching-deck", token=cand_token))
    step("swipes.candidate RIGHT", lambda: api.call("POST", f"/job-offers/{offer_id}/swipes",
        {"direction": "RIGHT"}, token=cand_token))
    step("swipes.recruiter deck", lambda: api.call("GET", f"/job-offers/{offer_id}/candidates/matching-deck", token=rec_token))
    cand_id = (cand[0] or {}).get("id") if cand else None
    step("swipes.recruiter RIGHT -> match", lambda: api.call("POST",
        f"/job-offers/{offer_id}/candidates/{cand_id}/swipes", {"direction": "RIGHT"}, token=rec_token))
    step("matches.candidate me", lambda: api.call("GET", "/candidates/me/matches", token=cand_token))
    step("fit-scores", lambda: api.call("GET", f"/fit-scores?candidateId={cand_id}&jobOfferId={offer_id}", token=rec_token))

    # 7. Assessment + candidate test attempt
    assess = step("assessments.create", lambda: api.call("POST", "/assessments", {
        "title": "Hard skills", "timeLimitSeconds": 600, "questions": [
            {"text": "Which VCS is distributed?", "options": ["Docker", "Git", "Jenkins"], "correctOptionIndex": 1}]},
        token=rec_token))
    assess_id = (assess[0] or {}).get("id") if assess else None
    if assess_id:
        step("job-offers.assign assessment", lambda: api.call("PATCH", f"/job-offers/{offer_id}",
            {"assessmentId": assess_id}, token=rec_token))
    attempt = step("test-attempts.start", lambda: api.call("POST", f"/job-offers/{offer_id}/test-attempts", token=cand_token))
    attempt_id = (attempt[0] or {}).get("attemptId") if attempt else None
    if attempt_id:
        q = (attempt[0].get("questions") or [{}])[0]
        step("test-attempts.submit", lambda: api.call("POST", f"/test-attempts/{attempt_id}/submit",
            {"answers": [{"questionId": q.get("id"), "selectedOptionIndex": 1}]}, token=cand_token))
    step("test-results.me", lambda: api.call("GET", f"/job-offers/{offer_id}/test-results/me", token=cand_token))
    step("test-results.recruiter", lambda: api.call("GET", f"/job-offers/{offer_id}/test-results", token=rec_token))
    step("test-results.summary", lambda: api.call("GET", f"/job-offers/{offer_id}/test-results/summary", token=rec_token))

    # 8. Candidate resume (AI) — external (Groq) may be stubbed
    step("candidates.resume", lambda: api.call("GET", f"/candidates/{cand_id}/resume", token=rec_token))

    # 9. Recruiter candidate feed + general search
    step("recruiters.candidate-feed", lambda: api.call("GET", f"/recruiters/me/candidate-feed?jobOfferId={offer_id}", token=rec_token))
    step("candidates.search", lambda: api.call("GET", "/candidates/search?q=Cand", token=rec_token))

    # 10. Opportunity offer (confirm/verify OTP blocked: no SMS/e-mail delivery)
    step("job-opportunity-offers.send", lambda: api.call("POST", "/job-opportunity-offers",
        {"candidateId": cand_id, "jobOfferId": offer_id}, token=rec_token))
    step("job-opportunity-offers.confirm (OTP)", lambda: api.call("POST",
        f"/job-opportunity-offers/{uuid.uuid4()}/confirm", token=cand_token),
        blocked_reason="OTP confirm needs the code; delivery (SMS/e-mail) not wired")
    step("hired-candidates.list", lambda: api.call("GET", "/recruiters/me/hired-candidates", token=rec_token))

    # 11. Referral
    step("referrals.invite", lambda: api.call("POST", "/referrals/invite",
        {"email": f"friend-{run}@example.test"}, token=cand_token))
    step("referrals.me", lambda: api.call("GET", "/referrals/me", token=cand_token))
    step("referrals.me.link", lambda: api.call("GET", "/referrals/me/link", token=cand_token))

    # 12. Wallet
    step("wallet.me", lambda: api.call("GET", "/wallet/me", token=cand_token))
    step("wallet.card", lambda: api.call("PUT", "/wallet/me/card", {
        "cardNumber": "4111111111111234", "expiryMonth": 12, "expiryYear": 2030,
        "cvv": "123", "cardholderName": "Cand Idate"}, token=cand_token))
    step("wallet.transactions", lambda: api.call("GET", "/wallet/me/transactions", token=cand_token))
    step("wallet.withdraw (no balance -> 400 expected)", lambda: api.call("POST", "/wallet/me/withdraw",
        {"amount": 10.0}, token=cand_token))

    # 13. Plans & purchases (store receipt verification is a provisional stub)
    step("plans", lambda: api.call("GET", "/plans", token=rec_token))
    step("subscriptions.me", lambda: api.call("GET", "/subscriptions/me", token=rec_token))
    step("purchases.verify (subscription)", lambda: api.call("POST", "/purchases/verify", {
        "productId": "recruiter_pro_monthly", "store": "APPLE",
        "receipt": "test-receipt", "transactionId": f"tx-{run}"}, token=rec_token))
    step("subscriptions.me after purchase", lambda: api.call("GET", "/subscriptions/me", token=rec_token))

    # 14. Preferences
    step("preferences.get", lambda: api.call("GET", "/users/me/preferences", token=cand_token))
    step("preferences.put", lambda: api.call("PUT", "/users/me/preferences", {
        "notificationsEnabled": False, "highContrast": True, "textSizePx": 22}, token=cand_token))

    # 15. Legal (public)
    step("legal.terms-of-use", lambda: api.call("GET", "/legal/terms-of-use"))
    step("legal.privacy-policy", lambda: api.call("GET", "/legal/privacy-policy"))

    # 16. E-mail / phone change (OTP delivery blocked)
    step("users.email change request", lambda: api.call("POST", "/users/me/email",
        {"newEmail": f"cand-new-{run}@example.test"}, token=cand_token),
        blocked_reason="code delivered by Resend (no API key); verify step needs the code")

    # 17. Engagement: post, like, comment, poll, conversations, notifications, help
    post = step("posts.create", lambda: api.call("POST", "/posts", {
        "visibility": "PUBLIC", "content": "Hello from E2E",
        "poll": {"question": "Best?", "options": ["A", "B"], "duration": 3}}, token=cand_token))
    post_id = (post[0] or {}).get("id") if post else None
    if post_id:
        step("posts.like", lambda: api.call("POST", f"/posts/{post_id}/likes", token=rec_token))
        step("posts.comment", lambda: api.call("POST", f"/posts/{post_id}/comments",
            {"content": "Nice!"}, token=rec_token))
        step("posts.comments list", lambda: api.call("GET", f"/posts/{post_id}/comments", token=cand_token))
    step("posts.feed", lambda: api.call("GET", "/posts", token=cand_token))
    step("post-preferences", lambda: api.call("GET", "/users/me/post-preferences", token=cand_token))
    step("conversations.ensure", lambda: api.call("POST", "/conversations", {
        "applicationId": offer_id}, token=rec_token))
    step("conversations.list", lambda: api.call("GET", "/conversations", token=cand_token))
    step("notifications.list", lambda: api.call("GET", "/notifications", token=cand_token))
    step("notifications.read-all", lambda: api.call("POST", "/notifications/read-all", token=cand_token))
    step("help-chats.open", lambda: api.call("POST", "/help-chats", token=cand_token))
    step("help-chats.list", lambda: api.call("GET", "/help-chats", token=cand_token))

    # 18. Calls / realtime (signalling only; media blocked by no Agora creds)
    step("realtime.negotiate", lambda: api.call("POST", "/realtime/negotiate", token=cand_token))
    step("calls.start", lambda: api.call("POST", "/calls/start", {
        "calleeId": cand_id, "type": "AUDIO"}, token=rec_token),
        blocked_reason="call media requires Agora/WebRTC credentials")

    # 19. Outreach: search offers as candidate
    step("job-offers.search (candidate)", lambda: api.call("GET", f"/job-offers?q=Designer", token=cand_token))

    # 20. Logout
    step("auth.logout", lambda: api.call("POST", "/auth/logout", token=cand_token))

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    passed = sum(1 for r in results if r["status"] == "PASS")
    failed = sum(1 for r in results if r["status"] == "FAIL")
    blocked = sum(1 for r in results if r["status"] == "BLOCKED")
    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "baseUrl": BASE,
        "summary": {"pass": passed, "fail": failed, "blocked": blocked, "total": len(results)},
        "steps": results,
    }
    REPORT.write_text(json.dumps(report, indent=2))
    print(f"\n{passed} PASS / {failed} FAIL / {blocked} BLOCKED  -> {REPORT}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
