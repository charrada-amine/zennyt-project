package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationReport;

import java.util.UUID;

/** Port de persistance audit des traces brutes de « Je coordonne ». */
public interface CoordinationMetricsRepository {

    /** Remplace atomiquement l'éventuel run audit-only de la session. */
    void replace(UUID sessionId, CoordinationMetrics metrics, CoordinationReport report);
}
