# Identity Module Audit (Auth, Profile, Onboarding)

This checklist covers ONLY the Identity module scope (Authentication, Profiles, Media Uploads, and Account Management for all roles).

---

## 1. Backend: Missing Identity Endpoints
Your backend team has done great work on basic auth, profiles, and the CV upload. However, the following endpoints are missing to complete the Identity module:

### 🔴 Media Uploads (Cloudinary)
While the CV upload (`POST /api/v1/profiles/me/cv`) is fully working, the avatar and company logo are missing file upload endpoints.
*   **Upload Avatar:** `POST /api/v1/users/me/avatar` (Needs to accept `multipart/form-data`)
*   **Upload Recruiter Logo:** `POST /api/v1/onboarding/recruiter/logo` (Needs to accept `multipart/form-data`)

### 🔴 Account Security & Lifecycle
*   **Change Password:** `PUT /api/v1/auth/password` (For logged-in users)
*   **Forgot/Reset Password:** `POST /api/v1/auth/forgot-password` and `reset-password`
*   **Delete Account:** `DELETE /api/v1/users/me`

### 🟡 Onboarding Data Management
Users can `POST` onboarding data, but they cannot retrieve or edit it later.
*   **Get/Update Candidate Onboarding:** `GET` and `PUT` for `/api/v1/onboarding/candidate-student/me`
*   **Get/Update Recruiter Onboarding:** `GET` and `PUT` for `/api/v1/onboarding/recruiter/me`

---

## 2. Frontend: Missing Identity UI & Integrations
The mobile app has the basic screens built, but we are missing the API wiring for file uploads and the UI for managing profile lists.

### 🔴 File Upload Integrations
*   **CV Upload (Onboarding):** We need to replace the fake `NoopUploadService` in the Onboarding screen with a real service that calls your working `POST /api/v1/profiles/me/cv` backend endpoint.
*   **CV Management UI:** We need to add a section in the Profile Settings for Candidates to View, Replace, or Delete their CV (using the `DELETE` endpoint).
*   **Avatar Picker UI:** The Avatar in `PersonalInformationsScreen` needs to be clickable to open the phone's gallery/camera, ready to wire up to the backend once they build the avatar endpoint.

### 🔴 Profile Management UI (Skills, Education, etc.)
The backend has endpoints for Skills, Positions, Certifications, and Education, but the mobile app is missing the UI to manage them.
*   **Missing Screens:** We need screens for Candidates to Add, Edit, and Delete their Skills, Work Experience, and Education.

### 🔴 Account Security Wiring
*   **Modals are built, but unconnected:** The "Change Password" and "Delete Account" UI exists in the Account Center, but we need to wire them to the API once the backend endpoints are created.
*   **Forgot Password UI:** We need to build a "Forgot Password" screen linked from the Login page.
