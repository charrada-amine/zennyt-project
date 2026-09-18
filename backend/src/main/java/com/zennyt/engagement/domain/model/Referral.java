package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.ReferralStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Parrainage (programme Ambassadeur, §12 des Conditions d'utilisation) :
 * un utilisateur invite une personne par e-mail ; le bonus n'est dû qu'après
 * la validation de la période d'essai du recrutement du filleul.
 */
public record Referral(UUID id, UUID referrerUserId, String inviteeEmail, UUID inviteeUserId,
                       ReferralStatus status, Instant hiredAt, Instant probationEndsAt,
                       Instant createdAt, Instant updatedAt) {

    public static Referral invite(UUID referrerUserId, String inviteeEmail) {
        Instant now = Instant.now();
        return new Referral(UUID.randomUUID(), referrerUserId, inviteeEmail, null,
            ReferralStatus.INVITED, null, null, now, now);
    }

    /** Filleul inscrit : statut REGISTERED, on mémorise son identité. */
    public Referral markRegistered(UUID inviteeUserId) {
        return new Referral(id, referrerUserId, inviteeEmail, inviteeUserId,
            ReferralStatus.REGISTERED, hiredAt, probationEndsAt, createdAt, Instant.now());
    }

    /** Filleul recruté : la période d'essai démarre à {@code hiredAt}. */
    public Referral markHired(Instant hiredAt, Instant probationEndsAt) {
        return new Referral(id, referrerUserId, inviteeEmail, inviteeUserId,
            ReferralStatus.HIRED, hiredAt, probationEndsAt, createdAt, Instant.now());
    }

    public Referral cancel() {
        return new Referral(id, referrerUserId, inviteeEmail, inviteeUserId,
            ReferralStatus.CANCELLED, hiredAt, probationEndsAt, createdAt, Instant.now());
    }
}
