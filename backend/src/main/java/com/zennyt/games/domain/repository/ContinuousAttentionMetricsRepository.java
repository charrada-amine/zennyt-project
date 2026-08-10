package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionReport;

import java.util.UUID;

/** Port de persistance audit des 1 364 essais Long Rosvold. */
public interface ContinuousAttentionMetricsRepository {

    /**
     * Remplace atomiquement un run audit-only précédent de la même session.
     * Le use case interdit cet appel dès qu'un Attempt validé existe.
     */
    void replace(UUID sessionId,
                 ContinuousAttentionMetrics metrics,
                 ContinuousAttentionReport report);
}
