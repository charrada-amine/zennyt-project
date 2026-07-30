package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.ReflectivePauseConfig;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseReport;
import com.zennyt.games.domain.vo.Score;

/**
 * Barème déterministe de « Reflective Pause ».
 *
 * <p>Temps contrôlé /3 + réponses non impulsives /4 + capacité à prendre du
 * recul /3. Les sous-scores restent décimaux pour le retour pédagogique ; leur
 * somme est arrondie une seule fois pour le {@link Score} entier /10.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : le mock Dart reproduit exactement ce calcul.
 */
public class ReflectivePauseScoringService {

    public Score score(ReflectivePauseMetrics metrics) {
        ReflectivePauseReport report = report(metrics);
        int total = ReflectivePauseConfig.totalScore(
            report.controlledReactionTimeScore(),
            report.nonImpulsiveResponsesScore(),
            report.abilityToStepBackScore());
        return new Score(
            total,
            ReflectivePauseConfig.TOTAL_MAX,
            ReflectivePauseConfig.interpret(total));
    }

    public ReflectivePauseReport report(ReflectivePauseMetrics metrics) {
        int total = metrics.moments().size();
        double controlled = ReflectivePauseConfig.criterionScore(
            metrics.controlledReactionCount(),
            total,
            ReflectivePauseConfig.CONTROLLED_REACTION_MAX);
        double nonImpulsive = ReflectivePauseConfig.criterionScore(
            metrics.nonImpulsiveCount(),
            total,
            ReflectivePauseConfig.NON_IMPULSIVE_MAX);
        double stepBack = ReflectivePauseConfig.criterionScore(
            metrics.stepBackCount(),
            total,
            ReflectivePauseConfig.STEP_BACK_MAX);
        int score = ReflectivePauseConfig.totalScore(
            controlled, nonImpulsive, stepBack);

        return new ReflectivePauseReport(
            total,
            controlled,
            nonImpulsive,
            stepBack,
            metrics.impulsiveChoiceCount(),
            metrics.averageResponseTimeMs(),
            ReflectivePauseConfig.interpret(score));
    }
}
