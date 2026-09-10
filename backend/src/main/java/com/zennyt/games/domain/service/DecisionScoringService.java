package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.config.DecisionConfig;
import com.zennyt.games.domain.config.DecisionProvisionalRules;
import com.zennyt.games.domain.vo.AdministrationMode;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.DecisionItemResponse;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.DecisionReport;
import com.zennyt.games.domain.vo.OptionQuality;
import com.zennyt.games.domain.vo.Score;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.OptionalInt;
import java.util.Set;
import java.util.UUID;

/**
 * Service de domaine : barème de « Je Décide » (prise de décision).
 *
 * <p><b>Deux couches strictement séparées.</b>
 * <ul>
 *   <li><b>MOTEUR (définitif, fiche)</b> — agrégation /18 → /90, règle DT à double
 *       ajustement (langue puis calibrage), imputation, textes d'interprétation,
 *       validité de session. Lit ses constantes dans {@link DecisionConfig}.</li>
 *   <li><b>PROVISOIRE (déduit)</b> — étiquetage qualité, poids SCW, bornes de
 *       niveau, dérivation CS, multiplicateurs es/it/pt/ar, seuils. Le moteur ne
 *       code AUCUNE de ces valeurs : il les lit dans {@link DecisionProvisionalRules}.</li>
 * </ul>
 * Java pur, sans Spring. Le contenu des scénarios provient d'un
 * {@link DecisionScenarioCatalog} injecté (port) — jamais codé ici.
 *
 * <p>⚠️ PARITÉ MOCK ⇄ BACKEND : {@code games_mock_repository.dart} reproduira ce
 * barème ET la couche provisoire à l'identique (câblage UI = lot séparé).
 */
public class DecisionScoringService {

    /** Le score agrégé du mini-jeu est le SCW, exprimé /100. */
    public static final int SCW_MAX = 100;

    private final DecisionScenarioCatalog catalog;

    public DecisionScoringService(DecisionScenarioCatalog catalog) {
        this.catalog = catalog;
    }

    /** Score agrégé du mini-jeu : SCW /100 + niveau. Le détail par dimension va dans le report. */
    public Score score(DecisionMetrics m, double calibrationOffsetMs) {
        return score(m, calibrationOffsetMs, null);
    }

    public Score score(DecisionMetrics m, double calibrationOffsetMs, UUID bankId) {
        Map<DecisionDimension, DimensionOutcome> dims = computeDimensions(m, calibrationOffsetMs, bankId);
        int scw = (int) Math.round(scw(dims));
        // Score agrégé = SCW /100 (le détail /18 par dimension vit dans le report/API).
        return new Score(scw, SCW_MAX, DecisionProvisionalRules.levelForScw(scw));
    }

    /** Indicateurs détaillés (dimensions, interprétations, validité, temporels). */
    public DecisionReport report(DecisionMetrics m, double calibrationOffsetMs) {
        return report(m, calibrationOffsetMs, null);
    }

    public DecisionReport report(DecisionMetrics m, double calibrationOffsetMs, UUID bankId) {
        Map<DecisionDimension, DimensionOutcome> dims = computeDimensions(m, calibrationOffsetMs, bankId);

        int raw = dims.values().stream()
            .filter(o -> o.score() != null)
            .mapToInt(o -> o.score())
            .sum();
        double scwRaw = scw(dims);
        int scw = (int) Math.round(scwRaw);

        List<DecisionReport.DimensionScore> dimScores = new ArrayList<>();
        for (DecisionDimension d : DecisionConfig.dimensions()) {
            DimensionOutcome o = dims.get(d);
            dimScores.add(new DecisionReport.DimensionScore(
                d, o == null ? null : o.score(), DecisionConfig.DIMENSION_MAX,
                o != null && o.score() != null, o == null ? 0 : o.answeredCount(),
                o != null && o.provisionalScoring()));
        }

        List<String> interpretations = interpretations(dims, scw);
        Timing timing = timing(m, calibrationOffsetMs);
        SessionQuality quality = sessionQuality(m, timing, calibrationOffsetMs);
        boolean calApplied = calibrationOffsetMs > 0.0;

        return new DecisionReport(
            raw, DecisionConfig.RAW_MAX, scw, DecisionProvisionalRules.levelForScw(scw),
            dimScores, interpretations,
            quality.avgTimePlausible(), quality.randomResponseRateOk(), quality.impulsiveRateOk(),
            quality.deviceLatencyWithinNorm(), quality.sessionUsable(),
            timing.averageMs(), timing.medianMs(), timing.stdDevMs(),
            timing.impulsivePercent(), timing.slowPercent(), timing.intraSessionVariability(),
            timing.decisionChangesCount(), timing.averageAdjustedMs(),
            calApplied, calApplied, true, calibrationOffsetMs);
    }

    // ── Agrégation par dimension (moteur) ────────────────────────────────────

    /** Score /18 (ou non exploitable) de chaque dimension, imputation comprise. */
    private Map<DecisionDimension, DimensionOutcome> computeDimensions(
            DecisionMetrics m, double calibrationOffsetMs) {
        return computeDimensions(m, calibrationOffsetMs, null);
    }

    private Map<DecisionDimension, DimensionOutcome> computeDimensions(
            DecisionMetrics m, double calibrationOffsetMs, UUID bankId) {
        double languageMultiplier = resolveLanguageMultiplier(m.sessionLanguage());

        Map<DecisionDimension, List<Integer>> byDimension = new EnumMap<>(DecisionDimension.class);
        Map<DecisionDimension, Integer> answeredCount = new EnumMap<>(DecisionDimension.class);
        Set<DecisionDimension> scoredForReal = EnumSet.noneOf(DecisionDimension.class);
        for (DecisionDimension d : DecisionDimension.values()) {
            byDimension.put(d, new ArrayList<>());
            answeredCount.put(d, 0);
        }

        for (DecisionItemResponse r : m.items()) {
            if (!r.answered()) {
                continue; // item manquant → imputation par dimension
            }
            DecisionScenarioCatalog.Item item = catalog.item(r.itemId(), bankId)
                .orElseThrow(() -> new IllegalArgumentException(
                    "Item absent du catalogue « Je Décide » : " + r.itemId()));
            OptionQuality quality = item.qualityOf(r.selectedOptionId());
            int points = scoreItem(item.format(), quality, r.responseTimeMs(),
                languageMultiplier, calibrationOffsetMs);

            DecisionDimension dim = item.dimension(); // catalogue autoritaire
            byDimension.get(dim).add(points);
            answeredCount.merge(dim, 1, Integer::sum);
            // Une dimension n'est déclarée provisoire que si TOUS ses items le sont :
            // un seul item réellement noté suffit à la rendre (partiellement)
            // discriminante, et l'annoncer neutre serait faux.
            if (!item.provisionalScoring()) {
                scoredForReal.add(dim);
            }
        }

        Map<DecisionDimension, DimensionOutcome> out = new EnumMap<>(DecisionDimension.class);
        for (DecisionDimension d : DecisionDimension.values()) {
            OptionalInt imputed = DecisionConfig.imputedDimensionScore(byDimension.get(d));
            out.put(d, new DimensionOutcome(
                imputed.isPresent() ? imputed.getAsInt() : null, answeredCount.get(d),
                answeredCount.get(d) > 0 && !scoredForReal.contains(d)));
        }
        return out;
    }

    /**
     * Note d'UN item /3 (échelle 0..3).
     * <ul>
     *   <li><b>DT</b> : correct (option OPTIMALE) + latence &lt; 75 % du temps
     *       imparti effectif → 3 ; correct mais ≥ 75 % → 2 ; incorrect → score de
     *       qualité de l'option. Le temps imparti applique le double ajustement
     *       (langue puis calibrage).</li>
     *   <li><b>STANDARD / CS</b> : score de qualité de l'option (pour CS, la qualité
     *       encode la cohérence de la paire — dérivation provisoire du catalogue).</li>
     * </ul>
     */
    public int scoreItem(DecisionItemFormat format, OptionQuality quality, int responseTimeMs,
                         double languageMultiplier, double calibrationOffsetMs) {
        if (format == DecisionItemFormat.TEMPORAL_DECISION) {
            boolean correct = quality == OptionQuality.OPTIMAL;
            if (!correct) {
                return DecisionProvisionalRules.optionScore(quality);
            }
            double limitMs = DecisionConfig.dtEffectiveLimitMs(languageMultiplier, calibrationOffsetMs);
            boolean fast = responseTimeMs < DecisionConfig.DT_FAST_THRESHOLD_RATIO * limitMs;
            return fast ? DecisionConfig.DT_FAST_POINTS : DecisionConfig.DT_SLOW_POINTS;
        }
        return DecisionProvisionalRules.optionScore(quality);
    }

    /** SCW /100 sur les dimensions exploitables (délégué à la couche provisoire). */
    private double scw(Map<DecisionDimension, DimensionOutcome> dims) {
        Map<DecisionDimension, Integer> exploitable = new EnumMap<>(DecisionDimension.class);
        dims.forEach((d, o) -> {
            if (o.score() != null) {
                exploitable.put(d, o.score());
            }
        });
        return DecisionProvisionalRules.scw(exploitable);
    }

    /** Multiplicateur linguistique : fourni (fiche) → provisoire → fallback tracé. */
    private double resolveLanguageMultiplier(String languageCode) {
        return DecisionConfig.providedLanguageMultiplier(languageCode)
            .or(() -> DecisionProvisionalRules.provisionalLanguageMultiplier(languageCode))
            .orElseGet(() -> {
                // Langue sans multiplicateur défini (ex. « ar ») → fallback documenté + tracé.
                System.getLogger(DecisionScoringService.class.getName()).log(
                    System.Logger.Level.INFO,
                    "Multiplicateur linguistique DT indisponible pour « {0} » → fallback {1} (PROVISOIRE)",
                    languageCode, DecisionProvisionalRules.LANGUAGE_FALLBACK_MULTIPLIER);
                return DecisionProvisionalRules.LANGUAGE_FALLBACK_MULTIPLIER;
            });
    }

    // ── Interprétations automatiques (textes fiche, seuils provisoires) ──────

    private List<String> interpretations(Map<DecisionDimension, DimensionOutcome> dims, int scw) {
        List<String> out = new ArrayList<>();
        if (scw >= DecisionProvisionalRules.LEVEL_HIGH_MIN) {
            out.add("Fonction décisionnelle élevée.");
        }
        Integer ii = scoreOf(dims, DecisionDimension.II);
        Integer cs = scoreOf(dims, DecisionDimension.CS);
        Integer er = scoreOf(dims, DecisionDimension.ER);
        Integer re = scoreOf(dims, DecisionDimension.RE);
        Integer dt = scoreOf(dims, DecisionDimension.DT);
        if (ii != null && cs != null
            && DecisionProvisionalRules.isDimensionLow(ii)
            && DecisionProvisionalRules.isDimensionLow(cs)) {
            out.add("Difficulté d'analyse et incohérence.");
        }
        if (er != null && re != null
            && DecisionProvisionalRules.isDimensionHigh(er)
            && DecisionProvisionalRules.isDimensionLow(re)) {
            out.add("Prise de risque sous émotion.");
        }
        if (dt != null && DecisionProvisionalRules.isDimensionHigh(dt)) {
            out.add("Bonne performance sous pression.");
        }
        return out;
    }

    private Integer scoreOf(Map<DecisionDimension, DimensionOutcome> dims, DecisionDimension d) {
        DimensionOutcome o = dims.get(d);
        return o == null ? null : o.score();
    }

    // ── Indicateurs temporels & comportementaux ──────────────────────────────

    private Timing timing(DecisionMetrics m, double calibrationOffsetMs) {
        List<DecisionItemResponse> answered = m.answeredItems();
        int decisionChanges = m.items().stream()
            .mapToInt(DecisionItemResponse::decisionChangesCount).sum();
        if (answered.isEmpty()) {
            return new Timing(0, 0, 0, 0, 0, 0, decisionChanges, 0);
        }
        double[] times = answered.stream()
            .mapToDouble(DecisionItemResponse::responseTimeMs).sorted().toArray();
        double avg = mean(times);
        double median = median(times);
        double std = stdDev(times, avg);
        double impulsiveFloorMs = DecisionConfig.RESPONSE_TIME_MIN_S * 1000.0;
        double slowCeilMs = DecisionConfig.RESPONSE_TIME_MAX_S * 1000.0;
        double impulsivePct = 100.0 * count(times, t -> t < impulsiveFloorMs) / times.length;
        double slowPct = 100.0 * count(times, t -> t > slowCeilMs) / times.length;
        double intraVar = avg == 0 ? 0 : std / avg; // coefficient de variation
        double avgAdjusted = Math.max(0.0, avg - Math.max(0.0, calibrationOffsetMs));
        return new Timing(avg, median, std, impulsivePct, slowPct, intraVar, decisionChanges, avgAdjusted);
    }

    // ── Qualité de session (fiche ; seuils provisoires, renforcés si autonome) ──

    private SessionQuality sessionQuality(DecisionMetrics m, Timing timing, double calibrationOffsetMs) {
        boolean unsupervised = m.administrationMode() == AdministrationMode.UNSUPERVISED;
        double strict = unsupervised ? DecisionProvisionalRules.UNSUPERVISED_STRICTNESS_FACTOR : 1.0;

        boolean avgTimePlausible =
            timing.averageMs() >= DecisionProvisionalRules.MIN_PLAUSIBLE_AVG_TIME_MS * strict;
        boolean impulsiveOk =
            timing.impulsivePercent() / 100.0 <= DecisionProvisionalRules.MAX_IMPULSIVE_RATE / strict;
        double randomRate = timing.impulsivePercent() / 100.0; // proxy : réponses hâtives ≈ aléatoire
        boolean randomOk = randomRate <= DecisionProvisionalRules.MAX_RANDOM_RESPONSE_RATE / strict;
        boolean latencyOk =
            calibrationOffsetMs <= DecisionProvisionalRules.MAX_DEVICE_LATENCY_OFFSET_MS;

        boolean usable = avgTimePlausible && impulsiveOk && randomOk && latencyOk;
        return new SessionQuality(avgTimePlausible, randomOk, impulsiveOk, latencyOk, usable);
    }

    // ── Petits utilitaires numériques ────────────────────────────────────────

    private static double mean(double[] xs) {
        double s = 0;
        for (double x : xs) s += x;
        return xs.length == 0 ? 0 : s / xs.length;
    }

    private static double median(double[] sorted) {
        int n = sorted.length;
        if (n == 0) return 0;
        return n % 2 == 1 ? sorted[n / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0;
    }

    private static double stdDev(double[] xs, double mean) {
        if (xs.length == 0) return 0;
        double s = 0;
        for (double x : xs) s += (x - mean) * (x - mean);
        return Math.sqrt(s / xs.length);
    }

    private interface DoublePredicate {
        boolean test(double v);
    }

    private static long count(double[] xs, DoublePredicate p) {
        long c = 0;
        for (double x : xs) if (p.test(x)) c++;
        return c;
    }

    // ── Structures internes ──────────────────────────────────────────────────

    private record DimensionOutcome(Integer score, int answeredCount,
                                    boolean provisionalScoring) {
    }

    private record Timing(double averageMs, double medianMs, double stdDevMs,
                          double impulsivePercent, double slowPercent, double intraSessionVariability,
                          int decisionChangesCount, double averageAdjustedMs) {
    }

    private record SessionQuality(boolean avgTimePlausible, boolean randomResponseRateOk,
                                  boolean impulsiveRateOk, boolean deviceLatencyWithinNorm,
                                  boolean sessionUsable) {
    }
}
