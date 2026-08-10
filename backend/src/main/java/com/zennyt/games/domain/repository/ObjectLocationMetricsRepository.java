package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationReport;

import java.util.UUID;

/** Port de persistance audit des actions brutes de « Je place ». */
public interface ObjectLocationMetricsRepository {

    /** Remplace atomiquement l'éventuel run audit-only de la session. */
    void replace(UUID sessionId,
                 ObjectLocationMetrics metrics,
                 ObjectLocationReport report);
}
