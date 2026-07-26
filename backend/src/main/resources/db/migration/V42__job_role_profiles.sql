-- Référentiel de pondération Fit Score v3 (CdC §4.3 + matrice v4.1,
-- fit_score/01-methodologie.md) — 24 lignes (6 profils × 4 niveaux), jamais
-- par métier individuel : la matrice confirme que tous les métiers d'un même
-- profil partagent la même pondération, quel que soit leur secteur.
-- calibrated=false partout ("v1 — non calibrés", matrice p.31, à valider en
-- atelier RH avant mise en production).

CREATE TABLE recruitment.job_role_profiles (
    id UUID PRIMARY KEY,
    profile_type VARCHAR(20) NOT NULL,
    level VARCHAR(20) NOT NULL,
    soft_weight INT NOT NULL,
    hard_weight INT NOT NULL,
    expected_hard_weight INT NOT NULL,
    cognitive_flexibility_weight INT NOT NULL,
    working_memory_weight INT NOT NULL,
    decision_making_weight INT NOT NULL,
    executive_planning_weight INT NOT NULL,
    emotional_regulation_weight INT NOT NULL,
    type_evaluation_hard VARCHAR(20) NOT NULL,
    calibrated BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_job_role_profiles_type_level UNIQUE (profile_type, level),
    CONSTRAINT ck_job_role_profiles_soft_hard CHECK (soft_weight + hard_weight = 100),
    CONSTRAINT ck_job_role_profiles_modules CHECK (
        cognitive_flexibility_weight + working_memory_weight + decision_making_weight
        + executive_planning_weight + emotional_regulation_weight = 100)
);

-- TECHNIQUE — modules 30/20/30/15/5, courbe hard 35/65/55/30
INSERT INTO recruitment.job_role_profiles
    (id, profile_type, level, soft_weight, hard_weight, expected_hard_weight,
     cognitive_flexibility_weight, working_memory_weight, decision_making_weight,
     executive_planning_weight, emotional_regulation_weight, type_evaluation_hard, calibrated)
VALUES
    (gen_random_uuid(), 'TECHNIQUE', 'JUNIOR',    65, 35, 35, 30, 20, 30, 15, 5, 'QCM', false),
    (gen_random_uuid(), 'TECHNIQUE', 'MID',       35, 65, 65, 30, 20, 30, 15, 5, 'QCM', false),
    (gen_random_uuid(), 'TECHNIQUE', 'SENIOR',    45, 55, 55, 30, 20, 30, 15, 5, 'QCM', false),
    (gen_random_uuid(), 'TECHNIQUE', 'EXECUTIVE', 70, 30, 30, 30, 20, 30, 15, 5, 'QCM', false),

-- ANALYTIQUE — modules 25/20/30/15/10, courbe hard 30/60/50/25
    (gen_random_uuid(), 'ANALYTIQUE', 'JUNIOR',    70, 30, 30, 25, 20, 30, 15, 10, 'QCM', false),
    (gen_random_uuid(), 'ANALYTIQUE', 'MID',       40, 60, 60, 25, 20, 30, 15, 10, 'QCM', false),
    (gen_random_uuid(), 'ANALYTIQUE', 'SENIOR',    50, 50, 50, 25, 20, 30, 15, 10, 'QCM', false),
    (gen_random_uuid(), 'ANALYTIQUE', 'EXECUTIVE', 75, 25, 25, 25, 20, 30, 15, 10, 'QCM', false),

-- RELATIONNEL — modules 10/10/20/15/45, courbe hard 10/25/20/10
    (gen_random_uuid(), 'RELATIONNEL', 'JUNIOR',    90, 10, 10, 10, 10, 20, 15, 45, 'QCM', false),
    (gen_random_uuid(), 'RELATIONNEL', 'MID',       75, 25, 25, 10, 10, 20, 15, 45, 'QCM', false),
    (gen_random_uuid(), 'RELATIONNEL', 'SENIOR',    80, 20, 20, 10, 10, 20, 15, 45, 'QCM', false),
    (gen_random_uuid(), 'RELATIONNEL', 'EXECUTIVE', 90, 10, 10, 10, 10, 20, 15, 45, 'QCM', false),

-- MANAGERIAL — modules 10/10/20/30/30, courbe hard 20/40/35/20
    (gen_random_uuid(), 'MANAGERIAL', 'JUNIOR',    80, 20, 20, 10, 10, 20, 30, 30, 'QCM', false),
    (gen_random_uuid(), 'MANAGERIAL', 'MID',       60, 40, 40, 10, 10, 20, 30, 30, 'QCM', false),
    (gen_random_uuid(), 'MANAGERIAL', 'SENIOR',    65, 35, 35, 10, 10, 20, 30, 30, 'QCM', false),
    (gen_random_uuid(), 'MANAGERIAL', 'EXECUTIVE', 80, 20, 20, 10, 10, 20, 30, 30, 'QCM', false),

-- CONVENTIONNEL — modules 15/30/15/30/10, courbe hard 25/40/35/20
    (gen_random_uuid(), 'CONVENTIONNEL', 'JUNIOR',    75, 25, 25, 15, 30, 15, 30, 10, 'QCM', false),
    (gen_random_uuid(), 'CONVENTIONNEL', 'MID',       60, 40, 40, 15, 30, 15, 30, 10, 'QCM', false),
    (gen_random_uuid(), 'CONVENTIONNEL', 'SENIOR',    65, 35, 35, 15, 30, 15, 30, 10, 'QCM', false),
    (gen_random_uuid(), 'CONVENTIONNEL', 'EXECUTIVE', 80, 20, 20, 15, 30, 15, 30, 10, 'QCM', false),

-- ARTISTIQUE — modules 40/15/15/15/15, courbe hard 30/55/45/25, évaluation Portfolio par défaut
    (gen_random_uuid(), 'ARTISTIQUE', 'JUNIOR',    70, 30, 30, 40, 15, 15, 15, 15, 'PORTFOLIO', false),
    (gen_random_uuid(), 'ARTISTIQUE', 'MID',       45, 55, 55, 40, 15, 15, 15, 15, 'PORTFOLIO', false),
    (gen_random_uuid(), 'ARTISTIQUE', 'SENIOR',    55, 45, 45, 40, 15, 15, 15, 15, 'PORTFOLIO', false),
    (gen_random_uuid(), 'ARTISTIQUE', 'EXECUTIVE', 75, 25, 25, 40, 15, 15, 15, 15, 'PORTFOLIO', false);
