package com.zennyt.recruitment.domain.vo;

import java.time.Instant;
import java.util.UUID;

/**
 * Un test de compétences noté, vu depuis l'historique métier d'un candidat.
 *
 * <p>Projection volontairement plus étroite que l'agrégat {@code TestResult} : l'historique
 * se lit par lots de plusieurs dizaines de lignes et n'a aucun usage des réponses détaillées.
 *
 * @param jobOfferId      l'offre pour laquelle le test a été passé — sert à reconnaître le
 *                        test de l'offre consultée (décision D3), pas à filtrer
 * @param experienceLevel niveau de l'offre <b>source</b>. La difficulté d'un QCM n'est
 *                        modélisée nulle part : ce niveau est conservé pour être affiché
 *                        à côté d'un score emprunté (décision D5), jamais pour filtrer.
 */
public record HardSkillHistoryEntry(UUID candidateId, UUID jobPositionId, UUID jobOfferId,
                                    int percentage, boolean passed, Instant completedAt,
                                    String experienceLevel) {
}
