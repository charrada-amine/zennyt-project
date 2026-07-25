CREATE TABLE recruitment.cv_profile_projection (
    candidate_id UUID PRIMARY KEY,
    cv_text TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);
