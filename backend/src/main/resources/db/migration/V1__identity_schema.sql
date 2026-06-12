CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone_number VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100),
    address VARCHAR(255),
    profile_image_url VARCHAR(500),
    terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_users_role CHECK (role IN ('CANDIDATE', 'STUDENT', 'RECRUITER', 'ADMIN'))
);

CREATE TABLE candidate_student_onboarding_infos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    school VARCHAR(150),
    education_level VARCHAR(150),
    field_of_work VARCHAR(150),
    last_position_held VARCHAR(150),
    years_of_experience INTEGER,
    cv_file_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_candidate_experience CHECK (years_of_experience IS NULL OR years_of_experience >= 0)
);

CREATE TABLE recruiter_onboarding_infos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    job_title VARCHAR(150) NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    company_size VARCHAR(100) NOT NULL,
    company_logo_url VARCHAR(500),
    field_of_work VARCHAR(150) NOT NULL,
    company_location VARCHAR(150) NOT NULL,
    company_registration_number VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    current_position VARCHAR(150),
    looking_for VARCHAR(150),
    type_of_workplace VARCHAR(20),
    type_of_job VARCHAR(20),
    target_job_location VARCHAR(150),
    years_of_experience INTEGER,
    soft_skills_score INTEGER NOT NULL DEFAULT 0,
    about_me TEXT,
    is_open_internationally BOOLEAN NOT NULL DEFAULT FALSE,
    availability_type VARCHAR(20),
    availability_date DATE,
    resume_ai_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_profile_experience CHECK (years_of_experience IS NULL OR years_of_experience >= 0),
    CONSTRAINT ck_soft_skills_score CHECK (soft_skills_score BETWEEN 0 AND 100)
);

CREATE TABLE skills (
    id BIGSERIAL PRIMARY KEY,
    profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    level INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_skill_type CHECK (type IN ('TECHNICAL', 'SOFT')),
    CONSTRAINT ck_skill_level CHECK (level IS NULL OR level BETWEEN 1 AND 5)
);

CREATE TABLE positions (
    id BIGSERIAL PRIMARY KEY,
    profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    company_name VARCHAR(150),
    location VARCHAR(150),
    description TEXT,
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE certifications (
    id BIGSERIAL PRIMARY KEY,
    profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    issuer VARCHAR(150),
    completion_date DATE,
    credential_id VARCHAR(150),
    credential_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE education (
    id BIGSERIAL PRIMARY KEY,
    profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    degree VARCHAR(150) NOT NULL,
    school VARCHAR(150),
    field_of_study VARCHAR(150),
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE refresh_sessions (
    id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_skills_name ON skills (LOWER(name));
CREATE INDEX idx_skills_type ON skills (type);
CREATE INDEX idx_refresh_sessions_user ON refresh_sessions (user_id);
