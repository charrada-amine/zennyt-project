package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.vo.MatchStatus;
import java.time.Instant;
import java.util.UUID;

/**
 * DTO de réponse pour un match (noms alignés sur le contrat frontend :
 * {@code matchId}, {@code jobTitle}). {@code candidateName}/{@code candidateAvatarUrl}
 * proviennent de la projection {@code recruitment.actors} (voir
 * {@code RecruitmentActorRepository}), alimentée par Identity via
 * {@code UserAccessStateChangedEvent} — null si l'acteur n'a encore aucun événement.
 */
public record MatchResponse(UUID matchId, UUID candidateId, UUID jobOfferId, UUID recruiterId,
                             String candidateName, String candidateAvatarUrl,
                             String jobTitle, String companyName,
                             MatchStatus status, Instant matchedAt) {
    public static MatchResponse from(Match m) {
        return from(m, null, null, null);
    }

    public static MatchResponse from(Match m, String companyName, String candidateName,
                                     String candidateAvatarUrl) {
        return new MatchResponse(m.id(), m.candidateId(), m.jobOfferId(), m.recruiterId(),
            candidateName, candidateAvatarUrl, m.jobOfferTitle(), companyName,
            m.status(), m.matchedAt());
    }
}
