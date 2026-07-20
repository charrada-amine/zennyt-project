-- Un candidat peut désormais avoir un score par module joué (avant : une
-- seule ligne écrasée à chaque partie terminée, quel que soit le module).
DROP TABLE recruitment.soft_skills_projection;

CREATE TABLE recruitment.soft_skills_projection (
    id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL,
    module VARCHAR(50) NOT NULL,
    score INTEGER NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_soft_skills_projection_score CHECK (score BETWEEN 0 AND 100),
    CONSTRAINT uq_soft_skills_projection_candidate_module UNIQUE (candidate_id, module)
);
