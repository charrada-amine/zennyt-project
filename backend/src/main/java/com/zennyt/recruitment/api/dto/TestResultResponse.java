package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.vo.TestResultStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO de réponse pour un résultat de test — vue candidat (contrat squad web
 * §7.3). Ni {@code answers} ni le détail de correction : un test peut être
 * réutilisé sur d'autres offres, révéler les bonnes réponses ici les
 * exposerait aux tentatives futures d'autres candidats.
 */
public record TestResultResponse(
    UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
    int score, int percentage, boolean passed,
    Instant startedAt, Instant completedAt, int duration, TestResultStatus status
) {
    public static TestResultResponse from(TestResult r) {
        return new TestResultResponse(r.id(), r.jobOfferId(), r.hardSkillTestId(), r.candidateId(),
            r.score(), r.percentage(), r.passed(), r.startedAt(), r.completedAt(), r.duration(), r.status());
    }
}
