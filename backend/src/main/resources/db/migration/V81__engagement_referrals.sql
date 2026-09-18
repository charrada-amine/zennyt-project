-- Programme Ambassadeur (parrainage) : un utilisateur invite une personne par
-- e-mail. Le bonus n'est dû qu'après la période d'essai du recrutement du
-- filleul (§12 des Conditions d'utilisation).
CREATE TABLE engagement.referrals (
    id UUID PRIMARY KEY,
    referrer_user_id UUID NOT NULL,
    invitee_email VARCHAR(150) NOT NULL,
    invitee_user_id UUID,
    status VARCHAR(20) NOT NULL,
    hired_at TIMESTAMP WITH TIME ZONE,
    probation_ends_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_referrals_referrer_email UNIQUE (referrer_user_id, invitee_email),
    CONSTRAINT ck_referrals_status
        CHECK (status IN ('INVITED', 'REGISTERED', 'HIRED', 'CANCELLED'))
);

CREATE INDEX idx_referrals_referrer ON engagement.referrals(referrer_user_id);
