package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.BartReport;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.IstReport;

import java.util.UUID;

/**
 * Port de persistance audit des traces brutes BART et IST.
 *
 * <p>Un seul port pour les deux mini-jeux du type {@code DECISION_BEHAVIORAL} :
 * chaque méthode remplace atomiquement l'éventuel run audit-only de SON jeu.
 */
public interface DecisionBehavioralMetricsRepository {

    void replaceBart(UUID sessionId, BartMetrics metrics, BartReport report);

    void replaceIst(UUID sessionId, IstMetrics metrics, IstReport report);
}
