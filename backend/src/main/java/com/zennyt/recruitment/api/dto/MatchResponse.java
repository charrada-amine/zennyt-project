package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.vo.MatchStatus;
import java.time.Instant;
import java.util.UUID;

/**
 * DTO de réponse pour un match (noms alignés sur le contrat frontend :
 * {@code matchId}, {@code jobTitle}). {@code candidateName} sera renseigné
 * quand le contexte Identity exposera les profils ; null en attendant.
 */
public record MatchResponse(UUID matchId, UUID candidateId, UUID jobOfferId, UUID recruiterId,
                             String candidateName, String jobTitle, String companyName,
                             MatchStatus status, Instant matchedAt) {
    public static MatchResponse from(Match m) {
        return from(m, null);
    }

    public static MatchResponse from(Match m, String companyName) {
        return new MatchResponse(m.id(), m.candidateId(), m.jobOfferId(), m.recruiterId(),
            null, m.jobOfferTitle(), companyName, m.status(), m.matchedAt());
    }
}
