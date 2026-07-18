## **Zennyt — Backend Data Model Documentation** 

## **1. Purpose** 

This document describes the backend data model for the **Zennyt** application. 

The application supports account creation and onboarding for three user roles: 

- Candidate 

- Student Recruiter 

Each user starts by creating a base account. After account creation, the user completes rolespecific onboarding: 

- Candidates and students provide education, work field, experience, and CV information. Recruiters provide job title, company details, company logo, company location, and company registration number. 

Candidates and students also have a professional profile containing work preferences, skills, positions, certifications, education, availability, and personal description. 

## **2. Main Backend Entities** 

The recommended entities are: 

|**Entity**|**Purpose**|
|---|---|
|`User`|Stores common account, authentication, and identity<br>information|
|`CandidateStudentOnboardingInfo`|Stores candidate/student onboarding information|
|`RecruiterOnboardingInfo`|Stores recruiter onboarding information|
|`Profile`|Stores candidate/student professional profile<br>information|
|`Skill`|Stores profile skills as individual records|
|`Position`|Stores professional work experience|
|`Certification`|Stores certifications|



**Entity** 

**Purpose** 

Stores education history 

`Education` 

## **3. Entity Relationship Diagram** 

## **4. Database Design Overview** 

The database should be normalized so that repeated or searchable information is stored in separate tables. 

The most important design decisions are: 

1. All users are stored in a single `users` table. 

2. The `role` field determines whether the user is a candidate, student, recruiter, or admin. 

3. Candidate and student onboarding can share the same table because the form fields are very similar. 

4. Recruiter onboarding has its own table because it contains company-specific fields. 

5. Skills should be stored in a separate `skills` table, not as comma-separated text. 

6. Positions, certifications, and education should each have their own table because a profile can have many of each. 

## **5. User Entity** 

## **5.1 Description** 

The `User` entity stores the base account information for every user in the system. 

This includes: 

Name 

- Email 

- Phone number 

- Password 

- City and country 

- Role 

- Account status 

- Terms acceptance 

The `User` entity should not store role-specific onboarding information directly. 

## **5.2 Fields** 

|**Field**|**Type**|**Required**|**Description**|
|---|---|---|---|
|`id`|`BIGINT`|Yes|Primary key|
|`first_name`|`VARCHAR(100)`|Yes|User first name|
|`last_name`|`VARCHAR(100)`|Yes|User last name|



|**Field**|**Type**|**Required**|**Description**|
|---|---|---|---|
|`email`|`VARCHAR(150)`|Yes|Unique user email|
|`phone_number`|`VARCHAR(30)`|No|User phone number|
|`password_hash`|`VARCHAR(255)`|Yes|Hashed password|
|`role`|`ENUM`|Yes|User role|
|`city`|`VARCHAR(100)`|No|User city|
|`country`|`VARCHAR(100)`|No|User country|
|`address`|`VARCHAR(255)`|No|Optional full address|
|`profile_image_url`|`VARCHAR(500)`|No|User profile image URL|
|`terms_accepted`|`BOOLEAN`|Yes|Whether user accepted terms and<br>conditions|
|`email_verified`|`BOOLEAN`|Yes|Whether user email is verified|
|`is_active`|`BOOLEAN`|Yes|Whether account is active|
|`created_at`|`DATETIME`|Yes|Creation timestamp|
|`updated_at`|`DATETIME`|Yes|Last update timestamp|



## **5.3 SQL Table** 

```
CREATETABLE users (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
```

```
    first_name VARCHAR(100)NOTNULL,
    last_name VARCHAR(100)NOTNULL,
    email VARCHAR(150)NOTNULLUNIQUE,
    phone_number VARCHAR(30),
```

```
    password_hash VARCHAR(255)NOTNULL,
```

```
    role ENUM('CANDIDATE','STUDENT','RECRUITER','ADMIN')NOTNULL,
```

```
    city VARCHAR(100),
    country VARCHAR(100),
    address VARCHAR(255),
```

```
    profile_image_url VARCHAR(500),
```

```
    terms_accepted BOOLEANNOTNULLDEFAULTFALSE,
```

```
    email_verified BOOLEANNOTNULLDEFAULTFALSE,
    is_active BOOLEANNOTNULLDEFAULTTRUE,
```

```
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP
);
```

## **6. Candidate / Student Onboarding Entity** 

## **6.1 Description** 

The `CandidateStudentOnboardingInfo` entity stores the information collected after a candidate or student creates an account. 

This corresponds to the onboarding screen where the user selects either: 

- Candidate 

- Student 

The fields include school, education level, field of work, last position held, years of experience, and uploaded CV. 

## **6.2 UI Fields** 

|**UI Field**|**Backend Field**|**Example**|
|---|---|---|
|School|`school`|`Design University`|
|Education level|`education_level`|`Masters of UX/UI Design`|
|Field of work|`field_of_work`|`Design`|
|Last position held|`last_position_held`|`UX/UI Designer`|
|Years of experience|`years_of_experience`|`2`|
|Upload your CV|`cv_file_url`|`/uploads/cv/millie-brown.pdf`|



**6.3 Fields** 

**==> picture [500 x 247] intentionally omitted <==**

**----- Start of picture text -----**<br>
Field Type Required Description<br>id BIGINT Yes Primary key<br>user_id BIGINT Yes Foreign key referencing  users.id<br>school VARCHAR(150) No School or university name<br>education_level VARCHAR(150) No Current or highest education level<br>field_of_work VARCHAR(150) No Career or study field<br>last_position_held VARCHAR(150) No Last professional position<br>years_of_experience INT No Years of professional experience<br>cv_file_url VARCHAR(500) No Uploaded CV file URL<br>created_at DATETIME Yes Creation timestamp<br>updated_at DATETIME Yes Last update timestamp<br>**----- End of picture text -----**<br>


## **6.4 SQL Table** 

```
CREATETABLE candidate_student_onboarding_infos (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
```

```
    user_id BIGINTNOTNULLUNIQUE,
    school VARCHAR(150),
    education_level VARCHAR(150),
    field_of_work VARCHAR(150),
    last_position_held VARCHAR(150),
    years_of_experience INT,
    cv_file_url VARCHAR(500),
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
CONSTRAINT fk_candidate_student_onboarding_user
FOREIGNKEY(user_id)REFERENCES users(id)
ONDELETECASCADE
);
```

## **7. Recruiter Onboarding Entity** 

## **7.1 Description** 

The `RecruiterOnboardingInfo` entity stores recruiter-specific onboarding data. 

This entity is based directly on the recruiter onboarding screen. 

A recruiter provides: 

Job title 

- Company name 

- Company size 

- Company logo 

- Field of work 

- Company location 

- Company registration number 

This information should be stored separately from the base `User` entity because it describes the recruiter’s company and professional role, not the basic account identity. 

## **7.2 UI Fields** 

|**UI Field**|**Backend Field**|**Example**|
|---|---|---|
|Job title|`job_title`|`HR`|
|Company name|`company_name`|`Google inc`|
|Company size|`company_size`|`100-200 employees`|
|Company logo|`company_logo_url`|`/uploads/logos/google.png`|
|Field of work|`field_of_work`|`IT, AI & Fintech`|
|Company location|`company_location`|`California, USA`|
|Company Registration<br>Number|`company_registration_number`|`12-3456789`|



## **7.3 Fields** 

|**Field**|**Type**|**Required**|**Description**|
|---|---|---|---|
|`id`|`BIGINT`|Yes|Primary key|
|`user_id`|`BIGINT`|Yes|Foreign key referencing<br>`users.id`|
|`job_title`|`VARCHAR(150)`|Yes|Recruiter’s professional<br>title|
|`company_name`|`VARCHAR(150)`|Yes|Company name|
|`company_size`|`VARCHAR(100)`|Yes|Company size range|
|`company_logo_url`|`VARCHAR(500)`|No|Uploaded company logo<br>URL|
|`field_of_work`|`VARCHAR(150)`|Yes|Company field or industry<br>area|
|`company_location`|`VARCHAR(150)`|Yes|Company location|
|`company_registration_number`|`VARCHAR(100)`|Yes|Company EIN or legal<br>registration number|
|`created_at`|`DATETIME`|Yes|Creation timestamp|
|`updated_at`|`DATETIME`|Yes|Last update timestamp|



## **7.4 SQL Table** 

```
CREATETABLE recruiter_onboarding_infos (
```

```
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
```

```
    user_id BIGINTNOTNULLUNIQUE,
```

```
    job_title VARCHAR(150)NOTNULL,
    company_name VARCHAR(150)NOTNULL,
    company_size VARCHAR(100)NOTNULL,
    company_logo_url VARCHAR(500),
    field_of_work VARCHAR(150)NOTNULL,
    company_location VARCHAR(150)NOTNULL,
    company_registration_number VARCHAR(100)NOTNULL,
```

```
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
```

```
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
```

```
CONSTRAINT fk_recruiter_onboarding_user
FOREIGNKEY(user_id)REFERENCES users(id)
```

```
ONDELETECASCADE
```

```
);
```

## **8. Profile Entity** 

## **8.1 Description** 

The `Profile` entity represents the professional profile for candidates and students. 

It contains information shown on the profile screen and edit profile screen. 

This includes: 

- Current position 

- Desired job position Workplace type 

- Job type 

- Target job location 

- Years of experience 

- Soft skills score 

- Availability 

- International work preference 

- About me 

- Portfolio URL 

- Resume AI URL 

## **8.2 UI Fields** 

|**UI Field**|**Backend Field**|**Example**|
|---|---|---|
|Position|`current_position`|`UX/UI Designer`|
|Looking for|`looking_for`|`UX/UI Designer`|
|Type of workplace|`type_of_workplace`|`HYBRID`|
|Type of job|`type_of_job`|`FULL_TIME`|
|Target job location|`target_job_location`|`New York, USA`|



|**UI Field**|**Backend Field**|**Example**|
|---|---|---|
|Open to work<br>internationally|`is_open_internationally`|`true`|
|Available|`availability_type`|`IMMEDIATELY`|
|Selected availability<br>date|`availability_date`|`2025-12-06`|
|Soft skills score|`soft_skills_score`|`85`|
|About me|`about_me`|`Hello. My name is Millie...`|
|Resume AI|`resume_ai_url`|`/resume-ai/user-1`|
|Portfolio|`portfolio_url`|`https://portfolio.example.com`|



## **8.3 Fields** 

|**Field**|**Type**|**Required**|**Description**|
|---|---|---|---|
|`id`|`BIGINT`|Yes|Primary key|
|`user_id`|`BIGINT`|Yes|Foreign key referencing<br>`users.id`|
|`current_position`|`VARCHAR(150)`|No|Current job or professional title|
|`looking_for`|`VARCHAR(150)`|No|Desired job position|
|`type_of_workplace`|`ENUM`|No|Workplace preference|
|`type_of_job`|`ENUM`|No|Job contract type|
|`target_job_location`|`VARCHAR(150)`|No|Desired work location|
|`years_of_experience`|`INT`|No|Total years of experience|
|`soft_skills_score`|`INT`|No|Soft skills score from 0 to 100|
|`about_me`|`TEXT`|No|User biography|
|`is_open_internationally`|`BOOLEAN`|Yes|Whether user accepts<br>international opportunities|
|`availability_type`|`ENUM`|No|Availability type|
|`availability_date`|`DATE`|No|Selected availability date|
|`resume_ai_url`|`VARCHAR(500)`|No|Resume AI URL or generated<br>resume file|
|`portfolio_url`|`VARCHAR(500)`|No|Portfolio URL|



|**Field**|**Type**|**Required**|**Description**|
|---|---|---|---|
|`created_at`|`DATETIME`|Yes|Creation timestamp|
|`updated_at`|`DATETIME`|Yes|Last update timestamp|



## **8.4 SQL Table** 

```
CREATETABLE profiles (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
    user_id BIGINTNOTNULLUNIQUE,
    current_position VARCHAR(150),
    looking_for VARCHAR(150),
```

```
    type_of_workplace ENUM('ONSITE','REMOTE','HYBRID','FLEXIBLE'),
    type_of_job ENUM('FULL_TIME','PART_TIME','INTERNSHIP','FREELANCE',
'CONTRACT'),
```

```
    target_job_location VARCHAR(150),
    years_of_experience INT,
    soft_skills_score INTDEFAULT0,
    about_me TEXT,
    is_open_internationally BOOLEANNOTNULLDEFAULTFALSE,
    availability_type ENUM('IMMEDIATELY','SELECT_DATE'),
    availability_date DATE,
    resume_ai_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
CONSTRAINT fk_profile_user
FOREIGNKEY(user_id)REFERENCES users(id)
ONDELETECASCADE
);
```

## **9. Skill Entity** 

## **9.1 Description** 

The `Skill` entity stores skills as separate records. 

Skills must not be stored as comma-separated text because the app will likely need to: 

- Search candidates by skill 

- Filter candidates by skill Match users with jobs 

- Separate technical skills from soft skills 

- Rank skills using a level field Avoid formatting problems 

A profile can have many skills. 

## **9.2 Fields** 

**==> picture [462 x 181] intentionally omitted <==**

**----- Start of picture text -----**<br>
Field Type Required Description<br>id BIGINT Yes Primary key<br>profile_id BIGINT Yes Foreign key referencing  profiles.id<br>name VARCHAR(100) Yes Skill name<br>type ENUM Yes Skill type:  TECHNICAL   or  SOFT<br>level INT No Optional skill level from 1 to 5<br>created_at DATETIME Yes Creation timestamp<br>updated_at DATETIME Yes Last update timestamp<br>**----- End of picture text -----**<br>


## **9.3 SQL Table** 

```
CREATETABLE skills (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
```

```
    profile_id BIGINTNOTNULL,
```

```
    name VARCHAR(100)NOTNULL,
typeENUM('TECHNICAL','SOFT')NOTNULL,
levelINT,
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
```

```
CONSTRAINT fk_skill_profile
FOREIGNKEY(profile_id)REFERENCES profiles(id)
ONDELETECASCADE
);
```

## **9.4 Example Skill Table Data** 

|**id**|**profile_id**|**name**|**type**|**level**|
|---|---|---|---|---|
|1|1|Figma|TECHNICAL|5|
|2|1|Adobe XD|TECHNICAL|4|
|3|1|Sketch|TECHNICAL|4|
|4|1|HTML/CSS|TECHNICAL|3|
|5|1|React|TECHNICAL|3|
|6|1|Communication|SOFT|5|
|7|1|Teamwork|SOFT|4|
|8|1|Problem Solving|SOFT|4|



## **10. Position Entity** 

## **10.1 Description** 

The `Position` entity stores professional work experience. 

A profile can have multiple positions. 

Examples from the UI: 

## Senior UX/UI Designer 

## X Agency 

2024 - Present 

## **10.2 Fields** 

**==> picture [474 x 270] intentionally omitted <==**

**----- Start of picture text -----**<br>
Field Type Required Description<br>id BIGINT Yes Primary key<br>profile_id BIGINT Yes Foreign key referencing  profiles.id<br>title VARCHAR(150) Yes Position title<br>company_name VARCHAR(150) No Company name<br>location VARCHAR(150) No Job location<br>description TEXT No Position description<br>start_date DATE No Start date<br>end_date DATE No End date<br>is_current BOOLEAN Yes Whether this is the current position<br>created_at DATETIME Yes Creation timestamp<br>updated_at DATETIME Yes Last update timestamp<br>**----- End of picture text -----**<br>


## **10.3 SQL Table** 

```
CREATETABLE positions (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
```

```
    profile_id BIGINTNOTNULL,
    title VARCHAR(150)NOTNULL,
    company_name VARCHAR(150),
    location VARCHAR(150),
    description TEXT,
```

```
    start_date DATE,
    end_date DATE,
    is_current BOOLEANNOTNULLDEFAULTFALSE,
```

```
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
```

```
CONSTRAINT fk_position_profile
```

```
FOREIGNKEY(profile_id)REFERENCES profiles(id)
ONDELETECASCADE
);
```

## **11. Certification Entity** 

## **11.1 Description** 

The `Certification` entity stores certificates attached to a profile. 

A profile can have multiple certifications. 

Examples from the UI: 

- Certified UX Designer UX Design Group 2023 

## **11.2 Fields** 

**==> picture [493 x 225] intentionally omitted <==**

**----- Start of picture text -----**<br>
Field Type Required Description<br>id BIGINT Yes Primary key<br>profile_id BIGINT Yes Foreign key referencing  profiles.id<br>title VARCHAR(150) Yes Certification title<br>issuer VARCHAR(150) No Organization that issued the certificate<br>completion_date DATE No Completion date<br>credential_id VARCHAR(150) No Credential ID<br>credential_url VARCHAR(500) No Credential verification URL<br>created_at DATETIME Yes Creation timestamp<br>updated_at DATETIME Yes Last update timestamp<br>**----- End of picture text -----**<br>


## **11.3 SQL Table** 

```
CREATETABLE certifications (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
    profile_id BIGINTNOTNULL,
    title VARCHAR(150)NOTNULL,
    issuer VARCHAR(150),
    completion_date DATE,
    credential_id VARCHAR(150),
    credential_url VARCHAR(500),
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
CONSTRAINT fk_certification_profile
FOREIGNKEY(profile_id)REFERENCES profiles(id)
ONDELETECASCADE
);
```

## **12. Education Entity** 

## **12.1 Description** 

The `Education` entity stores academic records attached to a profile. 

A profile can have multiple education records. 

Examples from the UI: 

Masters of UX/UI Design 

Design Institute of Technology 2020 - 2022 

## **12.2 Fields** 

**==> picture [487 x 247] intentionally omitted <==**

**----- Start of picture text -----**<br>
Field Type Required Description<br>id BIGINT Yes Primary key<br>profile_id BIGINT Yes Foreign key referencing  profiles.id<br>degree VARCHAR(150) Yes Degree or program name<br>school VARCHAR(150) No School or institution name<br>field_of_study VARCHAR(150) No Field of study<br>description TEXT No Optional education description<br>start_date DATE No Start date<br>end_date DATE No End date<br>created_at DATETIME Yes Creation timestamp<br>updated_at DATETIME Yes Last update timestamp<br>**----- End of picture text -----**<br>


## **12.3 SQL Table** 

```
CREATETABLE education (
    id BIGINTPRIMARYKEYAUTO_INCREMENT,
    profile_id BIGINTNOTNULL,
    degree VARCHAR(150)NOTNULL,
    school VARCHAR(150),
    field_of_study VARCHAR(150),
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPDEFAULTCURRENT_TIMESTAMP,
    updated_at TIMESTAMPDEFAULTCURRENT_TIMESTAMPONUPDATE
CURRENT_TIMESTAMP,
CONSTRAINT fk_education_profile
FOREIGNKEY(profile_id)REFERENCES profiles(id)
ONDELETECASCADE
);
```

## **17. Suggested API Endpoints** 

## **17.1 Authentication** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/auth/register`|Create a base user account|
|`POST`|`/api/auth/login`|Authenticate user|
|`POST`|`/api/auth/logout`|Logout user|
|`GET`|`/api/auth/me`|Get authenticated user|



## **17.2 Candidate / Student Onboarding** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/onboarding/candidate-`<br>`student`|Create candidate/student onboarding<br>info|
|`GET`|`/api/onboarding/candidate-`<br>`student/me`|Get current user candidate/student<br>onboarding info|
|`PUT`|`/api/onboarding/candidate-`<br>`student/me`|Update current user candidate/student<br>onboarding info|



## **17.3 Recruiter Onboarding** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/onboarding/recruiter`|Create recruiter onboarding info|
|`GET`|`/api/onboarding/recruiter/me`|Get current recruiter onboarding info|
|`PUT`|`/api/onboarding/recruiter/me`|Update current recruiter onboarding info|



## **17.4 Profile** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/profiles`|Create professional profile|
|`GET`|`/api/profiles/me`|Get current user profile|
|`PUT`|`/api/profiles/me`|Update current user profile|
|`GET`|`/api/profiles/{profileId}`|Get public profile by ID|



## **17.5 Skills** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/profiles/me/skills`|Add a skill|
|`GET`|`/api/profiles/me/skills`|Get all skills for current profile|
|`GET`|`/api/profiles/me/skills/technical`|Get technical skills|
|`GET`|`/api/profiles/me/skills/soft`|Get soft skills|
|`PUT`|`/api/profiles/me/skills/{skillId}`|Update a skill|
|`DELETE`|`/api/profiles/me/skills/{skillId}`|Delete a skill|



## **17.6 Positions** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/profiles/me/positions`|Add a position|
|`GET`|`/api/profiles/me/positions`|Get profile positions|
|`PUT`|`/api/profiles/me/positions/{positionId}`|Update a position|
|`DELETE`|`/api/profiles/me/positions/{positionId}`|Delete a position|



## **17.7 Certifications** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/profiles/me/certifications`|Add a certification|
|`GET`|`/api/profiles/me/certifications`|Get certifications|
|`PUT`|`/api/profiles/me/certifications/{certificationId}`|Update a<br>certification|
|`DELETE`|`/api/profiles/me/certifications/{certificationId}`|Delete a certification|



## **17.8 Education** 

|**Method**|**Endpoint**|**Description**|
|---|---|---|
|`POST`|`/api/profiles/me/education`|Add education|
|`GET`|`/api/profiles/me/education`|Get education history|
|`PUT`|`/api/profiles/me/education/{educationId}`|Update education|
|`DELETE`|`/api/profiles/me/education/{educationId}`|Delete education|



## **18. Final Entity List** 

The final recommended backend entities are: 

**==> picture [444 x 187] intentionally omitted <==**

**----- Start of picture text -----**<br>
Entity Table Name<br>User users<br>CandidateStudentOnboardingInfo candidate_student_onboarding_infos<br>RecruiterOnboardingInfo recruiter_onboarding_infos<br>Profile profiles<br>Skill skills<br>Position positions<br>Certification certifications<br>Education education<br>**----- End of picture text -----**<br>


This structure is clean, scalable, and matches the current UI screens. 

## 19. Mobile CV handling

The mobile candidate profile supports CV upload, replacement, deletion, and profile autofill.

- Upload endpoint: `POST /api/v1/profiles/me/cv` with `file` as multipart data.
- Supported upload formats: PDF, DOC and DOCX, maximum 5 MB.
- Deletion endpoint: `DELETE /api/v1/profiles/me/cv`.
- Autofill accepts PDF and image documents. Text-based PDFs are read locally; scanned PDFs are rendered page by page and processed with Apple Vision (iOS) or ML Kit (Android), then the extracted text is sent to `POST /api/v1/profiles/me/cv/parse`.

### Décisions à valider

- The mobile scanned-PDF OCR guardrail is currently 10 pages at 150 DPI, capped to 2048 pixels on the longest side. This is provisional and protects device memory and processing time.
- The Groq-backed CV parser remains the selected provider. Production must define `GROQ_API_KEY`; a missing key now fails explicitly with HTTP 503 instead of an internal error.

### Identity → Recruitment access events

- Identity publishes `identity.user.access-state-changed.v1` after registration, login,
  social login, name/avatar update, role change, deactivation and deletion.
- The event shares the public UUID, role, active state, public display name and avatar URL so
  Engagement can render local projections without calling Identity.
- A startup snapshot republishes existing users so Recruitment can initialize its local
  authorization projection without a direct cross-module call.
- Inactive accounts are rejected by `/auth/me`, password changes and Recruitment access.

### Backend CV and OCR safeguards

- CV and image uploads validate both the declared MIME type and the binary signature.
- The 5 MB limit is enforced before storage; invalid or empty files return a client error.
- CV documents are uploaded, replaced and deleted consistently as `RAW` resources.
- Public professional profiles are hidden as soon as the owning account is inactive.
- OCR parsing is behind the `CvParserPort`; the Groq adapter has bounded connect/read
  timeouts and translates provider unavailability to HTTP 503 and quotas to HTTP 429.
- CV deletion targets the correct raw Cloudinary resource type.

### Changelog

- 1. 2026-07-12 — Mobile CV upload now validates the 5 MB API limit, reports upload failures, reads `cvUrl`, supports CV deletion, and adds scanned-PDF OCR fallback.
- 2. 2026-07-14 — Backend CV/image signature validation, OCR port/timeouts/error mapping,
  inactive-account enforcement and Identity access-state events for Recruitment added;
  Identity contract now has 46 unique operation IDs and route-parity coverage. Claude review
  follow-up aligned CV storage to `RAW` and hid profiles owned by inactive accounts.
- 3. 2026-07-18 — Identity access-state events now include public display name/avatar and are
  republished after identity or avatar changes for the Engagement local projection.

**Dernière mise à jour :** 2026-07-18
