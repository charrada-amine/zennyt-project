package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.StrategicChoicesCatalog;
import com.zennyt.games.domain.config.StrategicChoicesConfig;
import com.zennyt.games.domain.vo.CopingFamily;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.StrategicChoiceAnswerMetric;
import com.zennyt.games.domain.vo.StrategicChoiceStrategy;
import com.zennyt.games.domain.vo.StrategicChoicesMetrics;
import com.zennyt.games.domain.vo.StrategicChoicesReport;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * Barème déterministe de « Choix Stratégiques ».
 *
 * <p>Le score est la somme des cotations retenues, sur {@code situations × 3}.
 * Le client n'envoie que la situation et la stratégie : la cotation vient du
 * catalogue serveur, jamais du payload.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : le mock Dart reproduit exactement ce calcul.
 */
public class StrategicChoicesScoringService {

    private final StrategicChoicesCatalog catalog;

    public StrategicChoicesScoringService(StrategicChoicesCatalog catalog) {
        this.catalog = catalog;
    }

    public Score score(StrategicChoicesMetrics metrics) {
        StrategicChoicesReport report = report(metrics);
        return new Score(report.rawPoints(), report.maxPoints(), report.level());
    }

    public StrategicChoicesReport report(StrategicChoicesMetrics metrics) {
        int raw = 0;
        int optimal = 0;
        int counterProductive = 0;
        double chance = 0.0;
        Map<CopingFamily, Integer> profile = new EnumMap<>(CopingFamily.class);
        Map<StrategicChoiceStrategy, Integer> uses =
            new EnumMap<>(StrategicChoiceStrategy.class);
        List<String> awaitingReview = new ArrayList<>();

        for (StrategicChoiceAnswerMetric answer : metrics.answers()) {
            int points = catalog.score(answer.situationId(), answer.selectedStrategy());
            raw += points;
            if (points == catalog.bestScore(answer.situationId())) {
                optimal++;
            }
            if (points == 0) {
                counterProductive++;
            }
            chance += catalog.chanceBaseline(answer.situationId());
            profile.merge(
                StrategicChoicesConfig.familyOf(answer.selectedStrategy()),
                1, Integer::sum);
            uses.merge(answer.selectedStrategy(), 1, Integer::sum);
            if (catalog.needsPsychologistValidation(answer.situationId())) {
                awaitingReview.add(answer.situationId());
            }
        }

        int max = StrategicChoicesConfig.maxPointsFor(metrics.answers().size());
        double corrected =
            StrategicChoicesConfig.chanceCorrectedPercent(raw, max, chance);
        StrategicChoiceStrategy mostUsed = uses.entrySet().stream()
            // À égalité, l'ordre de l'énumération tranche : il faut un résultat
            // reproductible, et non celui que le parcours d'une table donne.
            .max(Map.Entry.<StrategicChoiceStrategy, Integer>comparingByValue()
                .thenComparing(e -> -e.getKey().ordinal()))
            .map(Map.Entry::getKey)
            .orElse(null);

        return new StrategicChoicesReport(
            metrics.answers().size(),
            raw,
            max,
            optimal,
            counterProductive,
            mostUsed,
            uses.size(),
            metrics.averageResponseTimeMs(),
            chance,
            corrected,
            profile,
            // Le barème est reconstruit par inférence et trois fiches attendent
            // une validation : le rapport le dit, plutôt que de laisser un score
            // provisoire passer pour définitif.
            true,
            awaitingReview,
            // L'interprétation porte sur l'indice CORRIGÉ, pas sur le
            // pourcentage brut : celui-ci part de 40 % pour une réponse au
            // hasard, et ne veut donc rien dire tel quel.
            StrategicChoicesConfig.interpret(corrected));
    }
}
