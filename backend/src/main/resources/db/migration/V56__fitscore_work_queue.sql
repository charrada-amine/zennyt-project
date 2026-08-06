-- File de travail du Fit Score.
--
-- Remplace la soumission directe à un exécuteur en mémoire, qui perdait tout travail en
-- attente au redémarrage et dont la file bornée rejetait les rafales. Ici le travail est
-- durable, dédupliqué et priorisé.

CREATE TABLE recruitment.fitscore_work_queue (
    id            BIGSERIAL PRIMARY KEY,
    candidate_id  UUID        NOT NULL,
    job_offer_id  UUID        NOT NULL,
    priority      SMALLINT    NOT NULL,   -- 0 = urgent (événement), 1 = normal (rattrapage)
    status        VARCHAR(16) NOT NULL,   -- PENDING | DONE | FAILED
    attempts      SMALLINT    NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error    TEXT,
    CONSTRAINT ck_fitscore_queue_priority CHECK (priority IN (0, 1)),
    CONSTRAINT ck_fitscore_queue_status CHECK (status IN ('PENDING', 'DONE', 'FAILED'))
);

-- Déduplication : une seule ligne EN ATTENTE par paire. C'est cet index qui fait le vrai
-- travail — republier une offre dix fois n'insère pas dix lignes, l'insertion se faisant
-- en ON CONFLICT DO NOTHING. Partiel à dessein : une paire déjà traitée (DONE) peut être
-- réenfilée plus tard sans conflit.
CREATE UNIQUE INDEX uq_fitscore_queue_pending
    ON recruitment.fitscore_work_queue (candidate_id, job_offer_id)
    WHERE status = 'PENDING';

-- Consommation : priorité d'abord, puis ancienneté. Partiel également — l'index ne porte
-- que sur ce que le worker lit réellement, donc il ne grossit pas avec l'historique.
CREATE INDEX idx_fitscore_queue_claim
    ON recruitment.fitscore_work_queue (priority, created_at)
    WHERE status = 'PENDING';
