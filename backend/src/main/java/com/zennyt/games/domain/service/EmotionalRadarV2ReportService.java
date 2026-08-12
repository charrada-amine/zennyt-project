package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.EmotionalRadarV2Report;
import com.zennyt.games.domain.vo.RadarSceneOutcome;
import com.zennyt.games.domain.vo.RadarThetaEstimate;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Agrège les scènes notées serveur en indicateurs de session « Emotional Radar v2 »
 * (brief §2), et attache les deux scores (jeu + theta). Java pur, déterministe.
 *
 * <p>Les libellés de bande de distance sémantique sont les mêmes que ceux visés par
 * les niveaux (Élevée/Moyenne/Faible), pour croiser directement réussite et finesse.
 */
public final class EmotionalRadarV2ReportService {

    private final EmotionReferential referential;
    private final RadarGameScoreService gameScore;
    private final ThetaIrtService theta;

    public EmotionalRadarV2ReportService(EmotionReferential referential,
                                         RadarGameScoreService gameScore,
                                         ThetaIrtService theta) {
        this.referential = referential;
        this.gameScore = gameScore;
        this.theta = theta;
    }

    public EmotionalRadarV2Report report(List<RadarSceneOutcome> outcomes,
                                         int startingLevel,
                                         List<String> levelTransitions) {
        if (outcomes == null || outcomes.isEmpty()) {
            throw new IllegalArgumentException("aucune scène notée");
        }
        int total = outcomes.size();
        int correct = (int) outcomes.stream().filter(RadarSceneOutcome::correct).count();
        int finalLevel = outcomes.get(outcomes.size() - 1).level();

        Score game = gameScore.score(outcomes, finalLevel);
        RadarThetaEstimate thetaEstimate = theta.estimate(outcomes);

        return new EmotionalRadarV2Report(
            total,
            startingLevel,
            finalLevel,
            levelTransitions == null ? List.of() : List.copyOf(levelTransitions),
            correct,
            pct(correct, total),
            accuracyBy(outcomes, o -> o.level()),
            accuracyBy(outcomes, o -> o.choicesCount()),
            accuracyBySemanticBand(outcomes),
            semanticProximityErrorScore(outcomes),
            intensityMatchPercent(outcomes),
            intensityErrorDirection(outcomes),
            accuracyByStimulusIntensity(outcomes),
            stimulusTypePerformance(outcomes),
            averageJustification(outcomes),
            averageResponseTime(outcomes),
            impulsivePercent(outcomes),
            game.rawPoints(),
            game.level(),
            thetaEstimate);
    }

    // ── Agrégats ─────────────────────────────────────────────────────────────

    private interface IntKey {
        int of(RadarSceneOutcome o);
    }

    private static Map<Integer, Double> accuracyBy(List<RadarSceneOutcome> outcomes, IntKey key) {
        Map<Integer, int[]> buckets = new TreeMap<>();
        for (RadarSceneOutcome o : outcomes) {
            int[] agg = buckets.computeIfAbsent(key.of(o), k -> new int[2]);
            agg[0] += o.correct() ? 1 : 0;
            agg[1] += 1;
        }
        Map<Integer, Double> out = new LinkedHashMap<>();
        buckets.forEach((k, agg) -> out.put(k, pct(agg[0], agg[1])));
        return out;
    }

    private static Map<String, Double> accuracyBySemanticBand(List<RadarSceneOutcome> outcomes) {
        Map<String, int[]> buckets = new LinkedHashMap<>();
        buckets.put("Élevée", new int[2]);
        buckets.put("Moyenne", new int[2]);
        buckets.put("Faible", new int[2]);
        for (RadarSceneOutcome o : outcomes) {
            int[] agg = buckets.get(band(o.sceneDifficulty()));
            agg[0] += o.correct() ? 1 : 0;
            agg[1] += 1;
        }
        Map<String, Double> out = new LinkedHashMap<>();
        buckets.forEach((k, agg) -> out.put(k, pct(agg[0], agg[1])));
        return out;
    }

    /** Distance élevée = émotions différentes (facile) ; faible = proches (difficile). */
    private static String band(double distance) {
        if (distance >= 0.55) return "Élevée";
        if (distance >= 0.33) return "Moyenne";
        return "Faible";
    }

    private static double semanticProximityErrorScore(List<RadarSceneOutcome> outcomes) {
        double[] errs = outcomes.stream()
            .filter(o -> !o.correct())
            .mapToDouble(RadarSceneOutcome::semanticErrorDist)
            .toArray();
        if (errs.length == 0) return 0.0;
        double sum = 0;
        for (double e : errs) sum += e;
        return round1(sum / errs.length);
    }

    private static double intensityMatchPercent(List<RadarSceneOutcome> outcomes) {
        long ok = outcomes.stream().filter(RadarSceneOutcome::intensityMatches).count();
        return pct((int) ok, outcomes.size());
    }

    private static Map<String, Integer> intensityErrorDirection(List<RadarSceneOutcome> outcomes) {
        Map<String, Integer> out = new LinkedHashMap<>();
        out.put("Sous-estimée", 0);
        out.put("Correcte", 0);
        out.put("Sur-estimée", 0);
        for (RadarSceneOutcome o : outcomes) {
            String k = switch (Integer.signum(o.intensityErrorDirection())) {
                case -1 -> "Sous-estimée";
                case 1 -> "Sur-estimée";
                default -> "Correcte";
            };
            out.merge(k, 1, Integer::sum);
        }
        return out;
    }

    private static Map<String, Double> accuracyByStimulusIntensity(List<RadarSceneOutcome> outcomes) {
        List<String> labels = EmotionalRadarV2Config.STIMULUS_INTENSITY_LEVELS;
        Map<String, int[]> buckets = new LinkedHashMap<>();
        for (String l : labels) buckets.put(l, new int[2]);
        for (RadarSceneOutcome o : outcomes) {
            int idx = Math.max(0, Math.min(labels.size() - 1, o.stimulusIntensity()));
            int[] agg = buckets.get(labels.get(idx));
            agg[0] += o.correct() ? 1 : 0;
            agg[1] += 1;
        }
        Map<String, Double> out = new LinkedHashMap<>();
        buckets.forEach((k, agg) -> out.put(k, pct(agg[0], agg[1])));
        return out;
    }

    private Map<String, Double> stimulusTypePerformance(List<RadarSceneOutcome> outcomes) {
        Map<String, int[]> buckets = new LinkedHashMap<>();
        for (RadarSceneOutcome o : outcomes) {
            String type = referential.byKey(o.correctKey())
                .map(EmotionDefinition::stimulusType)
                .map(Enum::name)
                .orElse("UNKNOWN");
            int[] agg = buckets.computeIfAbsent(type, k -> new int[2]);
            agg[0] += o.correct() ? 1 : 0;
            agg[1] += 1;
        }
        Map<String, Double> out = new LinkedHashMap<>();
        buckets.forEach((k, agg) -> out.put(k, pct(agg[0], agg[1])));
        return out;
    }

    private static double averageJustification(List<RadarSceneOutcome> outcomes) {
        double[] scores = outcomes.stream()
            .mapToInt(RadarSceneOutcome::justificationScore)
            .filter(s -> s >= 0)
            .asDoubleStream()
            .toArray();
        if (scores.length == 0) return 0.0;
        double sum = 0;
        for (double s : scores) sum += s;
        return round1(sum / scores.length);
    }

    private static int averageResponseTime(List<RadarSceneOutcome> outcomes) {
        return (int) Math.round(outcomes.stream()
            .mapToInt(RadarSceneOutcome::responseTimeMs).average().orElse(0));
    }

    private static double impulsivePercent(List<RadarSceneOutcome> outcomes) {
        long impulsive = outcomes.stream().filter(RadarSceneOutcome::impulsive).count();
        return pct((int) impulsive, outcomes.size());
    }

    private static double pct(int numerator, int denominator) {
        if (denominator <= 0) return 0.0;
        return round1(numerator * 100.0 / denominator);
    }

    private static double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    /** Utilitaire local — expose la liste des transitions comme historique lisible. */
    public static List<String> transitionsAsText(List<Integer> levels) {
        List<String> out = new ArrayList<>();
        for (int i = 1; i < levels.size(); i++) {
            int delta = levels.get(i) - levels.get(i - 1);
            if (delta > 0) out.add("↑ " + levels.get(i - 1) + "→" + levels.get(i));
            else if (delta < 0) out.add("↓ " + levels.get(i - 1) + "→" + levels.get(i));
        }
        return out;
    }
}
