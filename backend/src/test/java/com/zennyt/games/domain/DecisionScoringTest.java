package com.zennyt.games.domain;

import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.config.DecisionConfig;
import com.zennyt.games.domain.config.DecisionProvisionalRules;
import com.zennyt.games.domain.service.DecisionScoringService;
import com.zennyt.games.domain.vo.AdministrationMode;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.DecisionItemResponse;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.DecisionReport;
import com.zennyt.games.domain.vo.OptionQuality;
import com.zennyt.games.domain.vo.Score;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Barème « Je Décide ». Java pur, catalogue de test injecté (aucun contenu de
 * scénario de production). Vérifie le MOTEUR (agrégation, DT, imputation,
 * interprétations, validité) ET la séparation avec la couche PROVISOIRE.
 */
class DecisionScoringTest {

    // ── Catalogue de test (Map en mémoire) — jamais de contenu de prod ────────
    private static final class MapCatalog implements DecisionScenarioCatalog {
        final Map<String, Item> items = new HashMap<>();

        void put(String id, DecisionDimension dim, DecisionItemFormat fmt, OptionQuality q) {
            items.put(id, new Item(id, dim, fmt, Map.of("opt", q)));
        }

        @Override public Optional<Item> item(String itemId) { return Optional.ofNullable(items.get(itemId)); }
        @Override public boolean isEmpty() { return items.isEmpty(); }
    }

    /** Construit catalogue + métriques : 6 items STANDARD par dimension, qualité voulue. */
    private static Fixture fixture(Map<DecisionDimension, OptionQuality> perDim,
                                   int responseTimeMs, String lang, AdministrationMode mode) {
        MapCatalog catalog = new MapCatalog();
        List<DecisionItemResponse> responses = new ArrayList<>();
        for (Map.Entry<DecisionDimension, OptionQuality> e : perDim.entrySet()) {
            for (int i = 1; i <= DecisionConfig.ITEMS_PER_DIMENSION; i++) {
                String id = e.getKey().name() + "-" + i;
                catalog.put(id, e.getKey(), DecisionItemFormat.STANDARD, e.getValue());
                responses.add(new DecisionItemResponse(id, e.getKey(), "opt", responseTimeMs, true, 0));
            }
        }
        DecisionMetrics metrics = new DecisionMetrics(responses, lang, mode, null, null, null, null);
        return new Fixture(new DecisionScoringService(catalog), metrics);
    }

    private record Fixture(DecisionScoringService service, DecisionMetrics metrics) {}

    private static Map<DecisionDimension, OptionQuality> allDims(OptionQuality q) {
        Map<DecisionDimension, OptionQuality> m = new EnumMap<>(DecisionDimension.class);
        for (DecisionDimension d : DecisionDimension.values()) m.put(d, q);
        return m;
    }

    private static DecisionReport.DimensionScore dim(DecisionReport r, DecisionDimension d) {
        return r.dimensions().stream().filter(x -> x.dimension() == d).findFirst().orElseThrow();
    }

    // ── Agrégation ────────────────────────────────────────────────────────────

    @Test
    void six_optimal_items_score_full_dimension() {
        Fixture f = fixture(allDims(OptionQuality.OPTIMAL), 15000, "en", AdministrationMode.SUPERVISED);
        DecisionReport r = f.service.report(f.metrics, 0.0);
        assertEquals(18, dim(r, DecisionDimension.II).score());
        assertEquals(DecisionConfig.DIMENSION_MAX, dim(r, DecisionDimension.II).maxScore());
        assertEquals(90, r.rawScore());
        assertEquals(100, r.scwScore());
        assertEquals("Élevé", r.level());
    }

    @Test
    void sheet_validated_example_scores_scw_66_7_normal() {
        // Exemple validé de la fiche : II=12, ER=9, DT=15, CS=14, RE=10 → raw=60.
        Map<DecisionDimension, Integer> dims = Map.of(
            DecisionDimension.II, 12, DecisionDimension.ER, 9, DecisionDimension.DT, 15,
            DecisionDimension.CS, 14, DecisionDimension.RE, 10);
        double scw = DecisionProvisionalRules.scw(dims);
        assertEquals(66.7, scw, 0.1);
        assertEquals("Normal", DecisionProvisionalRules.levelForScw(scw));
    }

    // ── Règle DT (double ajustement) ──────────────────────────────────────────

    @Test
    void dt_correct_and_fast_scores_three_slow_scores_two() {
        DecisionScoringService svc = new DecisionScoringService(new MapCatalog());
        // limite en = 7000 ms, seuil 75 % = 5250 ms.
        assertEquals(3, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 1000, 1.0, 0));
        assertEquals(2, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 6000, 1.0, 0));
        // Incorrect (option non optimale) → score de qualité de l'option.
        assertEquals(1, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.PARTIAL, 500, 1.0, 0));
    }

    @Test
    void dt_language_multiplier_changes_time_budget() {
        DecisionScoringService svc = new DecisionScoringService(new MapCatalog());
        assertEquals(1.20, DecisionConfig.providedLanguageMultiplier("fr").orElseThrow(), 1e-9);
        // Même latence brute 6000 ms : lent en en (≥ 5250) → 2 ; rapide en fr (< 6300) → 3.
        assertEquals(2, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 6000, 1.00, 0));
        assertEquals(3, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 6000, 1.20, 0));
    }

    @Test
    void dt_slow_device_does_not_flip_three_to_two() {
        DecisionScoringService svc = new DecisionScoringService(new MapCatalog());
        // 5400 ms en en : ≥ 75 % (5250) → 2 sans calibrage.
        assertEquals(2, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 5400, 1.0, 0));
        // Offset 800 ms → limite 7800, seuil 5850 → 5400 < 5850 → reste 3.
        assertEquals(3, svc.scoreItem(DecisionItemFormat.TEMPORAL_DECISION, OptionQuality.OPTIMAL, 5400, 1.0, 800));
    }

    // ── Imputation ────────────────────────────────────────────────────────────

    @Test
    void imputation_up_to_two_missing_uses_block_mean_beyond_is_unusable() {
        // 4 items présents [3,3,3,3], 2 manquants → moyenne 3 × 6 = 18.
        assertEquals(18, DecisionConfig.imputedDimensionScore(List.of(3, 3, 3, 3)).getAsInt());
        // 4 items [2,2,3,1] → moyenne 2.0 × 6 = 12.
        assertEquals(12, DecisionConfig.imputedDimensionScore(List.of(2, 2, 3, 1)).getAsInt());
        // 3 items présents, 3 manquants (> 2) → bloc non exploitable.
        assertTrue(DecisionConfig.imputedDimensionScore(List.of(3, 3, 3)).isEmpty());
    }

    @Test
    void unexploitable_block_is_flagged_and_excluded_from_scw() {
        // II n'a que 3 items répondus → non exploitable ; les autres complètes (OPTIMAL).
        MapCatalog catalog = new MapCatalog();
        List<DecisionItemResponse> responses = new ArrayList<>();
        for (DecisionDimension d : DecisionDimension.values()) {
            int count = d == DecisionDimension.II ? 3 : DecisionConfig.ITEMS_PER_DIMENSION;
            for (int i = 1; i <= count; i++) {
                String id = d.name() + "-" + i;
                catalog.put(id, d, DecisionItemFormat.STANDARD, OptionQuality.OPTIMAL);
                responses.add(new DecisionItemResponse(id, d, "opt", 15000, true, 0));
            }
        }
        DecisionReport r = new DecisionScoringService(catalog)
            .report(new DecisionMetrics(responses, "en", AdministrationMode.SUPERVISED, null, null, null, null), 0.0);
        assertFalse(dim(r, DecisionDimension.II).exploitable());
        assertNull(dim(r, DecisionDimension.II).score());
        // 4 dimensions exploitables à 18 → SCW = 72/(18×4)×100 = 100.
        assertEquals(100, r.scwScore());
    }

    // ── Interprétations automatiques (textes fiche, seuils provisoires) ───────

    @Test
    void high_scw_yields_high_function_interpretation() {
        DecisionReport r = report(allDims(OptionQuality.OPTIMAL));
        assertTrue(r.interpretations().contains("Fonction décisionnelle élevée."));
    }

    @Test
    void low_ii_and_low_cs_yield_analysis_difficulty() {
        Map<DecisionDimension, OptionQuality> perDim = allDims(OptionQuality.SATISFACTORY);
        perDim.put(DecisionDimension.II, OptionQuality.DEFICIENT);
        perDim.put(DecisionDimension.CS, OptionQuality.DEFICIENT);
        assertTrue(report(perDim).interpretations().contains("Difficulté d'analyse et incohérence."));
    }

    @Test
    void high_er_and_low_re_yield_risk_under_emotion() {
        Map<DecisionDimension, OptionQuality> perDim = allDims(OptionQuality.PARTIAL);
        perDim.put(DecisionDimension.ER, OptionQuality.OPTIMAL);
        perDim.put(DecisionDimension.RE, OptionQuality.DEFICIENT);
        assertTrue(report(perDim).interpretations().contains("Prise de risque sous émotion."));
    }

    @Test
    void high_dt_yields_performance_under_pressure() {
        Map<DecisionDimension, OptionQuality> perDim = allDims(OptionQuality.PARTIAL);
        perDim.put(DecisionDimension.DT, OptionQuality.OPTIMAL);
        assertTrue(report(perDim).interpretations().contains("Bonne performance sous pression."));
    }

    private DecisionReport report(Map<DecisionDimension, OptionQuality> perDim) {
        Fixture f = fixture(perDim, 15000, "en", AdministrationMode.SUPERVISED);
        return f.service.report(f.metrics, 0.0);
    }

    // ── Qualité de session ────────────────────────────────────────────────────

    @Test
    void plausible_session_is_usable() {
        Fixture f = fixture(allDims(OptionQuality.SATISFACTORY), 15000, "en", AdministrationMode.SUPERVISED);
        DecisionReport r = f.service.report(f.metrics, 0.0);
        assertTrue(r.sessionUsable());
    }

    @Test
    void high_device_latency_invalidates_session() {
        Fixture f = fixture(allDims(OptionQuality.SATISFACTORY), 15000, "en", AdministrationMode.SUPERVISED);
        DecisionReport r = f.service.report(f.metrics, 150.0); // offset > 100 ms
        assertFalse(r.deviceLatencyWithinNorm());
        assertFalse(r.sessionUsable());
    }

    @Test
    void impulsive_responses_invalidate_session() {
        // 5000 ms < plancher 10 s → 100 % impulsif → impulsif/aléatoire KO.
        Fixture f = fixture(allDims(OptionQuality.SATISFACTORY), 5000, "en", AdministrationMode.SUPERVISED);
        DecisionReport r = f.service.report(f.metrics, 0.0);
        assertFalse(r.impulsiveRateOk());
        assertFalse(r.randomResponseRateOk());
        assertFalse(r.sessionUsable());
    }

    @Test
    void implausibly_fast_average_invalidates_session() {
        Fixture f = fixture(allDims(OptionQuality.SATISFACTORY), 800, "en", AdministrationMode.SUPERVISED);
        DecisionReport r = f.service.report(f.metrics, 0.0);
        assertFalse(r.avgTimePlausible());
        assertFalse(r.sessionUsable());
    }

    // ── Séparation moteur / provisoire (swappabilité) ─────────────────────────

    @Test
    void engine_delegates_score_and_level_to_provisional_layer() {
        // Le moteur ne code aucun poids ni borne : score() == SCW provisoire + niveau provisoire.
        Fixture f = fixture(allDims(OptionQuality.SATISFACTORY), 15000, "en", AdministrationMode.SUPERVISED);
        Score s = f.service.score(f.metrics, 0.0);

        Map<DecisionDimension, Integer> dims = new EnumMap<>(DecisionDimension.class);
        for (DecisionDimension d : DecisionDimension.values()) dims.put(d, 12); // SATISFACTORY×6
        int expectedScw = (int) Math.round(DecisionProvisionalRules.scw(dims));

        assertEquals(expectedScw, s.rawPoints());
        assertEquals(DecisionProvisionalRules.levelForScw(expectedScw), s.level());
        assertEquals(100, s.maxPoints());
    }

    @Test
    void equal_weights_reduce_scw_to_raw_over_ninety() {
        // Poids égaux (provisoire b) ⇒ SCW = raw/90 × 100. Changer un poids ici
        // suffirait à déplacer le résultat, sans toucher une ligne du moteur.
        Map<DecisionDimension, Integer> dims = Map.of(
            DecisionDimension.II, 18, DecisionDimension.ER, 18, DecisionDimension.DT, 18,
            DecisionDimension.CS, 18, DecisionDimension.RE, 0);
        assertEquals(72.0 / 90.0 * 100.0, DecisionProvisionalRules.scw(dims), 1e-9);
    }
}
