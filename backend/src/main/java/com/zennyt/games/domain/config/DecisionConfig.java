package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.DecisionDimension;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalInt;

/**
 * Configuration <b>MOTEUR</b> de « Je Décide » — <b>définitive</b>, issue de la
 * fiche « JE DÉCIDE ». Java pur, sans Spring.
 *
 * <p>Ce fichier ne contient QUE des valeurs fournies par la fiche : structure du
 * test, agrégation /18 → /90, mécanique de la règle DT, multiplicateurs
 * linguistiques <b>fournis</b> (en/fr/de) et imputation. Il ne code <b>aucune</b>
 * valeur provisoire : celles-ci vivent exclusivement dans
 * {@link com.zennyt.games.domain.config.DecisionProvisionalRules}, et le moteur les
 * lit depuis là. Remplacer le provisoire ne demande donc aucune modification ici.
 */
public final class DecisionConfig {

    private DecisionConfig() {
    }

    // ── Structure du test (fiche) ────────────────────────────────────────────

    /** {@code capabilities_count} — 5 dimensions (II, ER, DT, CS, RE). */
    public static final int CAPABILITIES_COUNT = 5;

    /** {@code items_per_dimension} — 6 items par dimension. */
    public static final int ITEMS_PER_DIMENSION = 6;

    /** {@code total_items} — 30 items notés (hors entraînement). */
    public static final int TOTAL_ITEMS = 30;

    /** {@code item_score_scale} — chaque item est noté sur 0..3. */
    public static final int ITEM_SCORE_MIN = 0;
    public static final int ITEM_SCORE_MAX = 3;

    /** {@code training_items_count} — 3 items d'entraînement (non notés). */
    public static final int TRAINING_ITEMS_COUNT = 3;

    // ── Formes parallèles ────────────────────────────────────────────────────
    // La banque compte 24 items par dimension pour 6 administrés : de quoi tirer
    // 4 formes de 30 items. Leur composition est une DONNÉE (table
    // games.decision_form_items, V59), jamais une règle positionnelle.

    /** Formes prévues par la banque (24 = 4 × 6). */
    public static final List<String> FORM_CODES = List.of("A", "B", "C", "D");

    /** Seule forme seedée à ce jour. */
    public static final String DEFAULT_FORM_CODE = "A";

    /**
     * Forme assignée à une nouvelle session « Je Décide ».
     *
     * <p><b>Toujours {@link #DEFAULT_FORM_CODE} pour l'instant, volontairement.</b>
     * Faire tourner les 4 formes suppose qu'elles soient équivalentes ; elles ne
     * peuvent pas l'être tant que ER-1..18, CS et RE sont en notation neutre
     * provisoire : la seule forme contenant les items ER réellement notés serait la
     * seule où ER discrimine, et deux candidats de formes différentes ne seraient
     * plus comparables — alors que le Fit Score les compare globalement.
     *
     * <p>Le mécanisme complet est en place (colonne de session, composition en base,
     * relecture à la notation) : activer la rotation ne demandera qu'une migration
     * de données seedant B/C/D, plus le remplacement de ce corps de méthode.
     */
    public static String assignFormCode() {
        return DEFAULT_FORM_CODE;
    }

    /** {@code block_order_randomized} — l'ordre des blocs est randomisé. */
    public static final boolean BLOCK_ORDER_RANDOMIZED = true;

    /** {@code evaluation_mode} — mode évaluation (pas d'indices). */
    public static final boolean EVALUATION_MODE = true;

    /** {@code score_visible_to_player} — le score n'est jamais montré au joueur. */
    public static final boolean SCORE_VISIBLE_TO_PLAYER = false;

    /** {@code max_vignette_read_time_s} — temps de lecture max d'une vignette. */
    public static final int MAX_VIGNETTE_READ_TIME_S = 45;

    /** {@code response_time_range_s} — plage attendue de temps de réponse (10–30 s). */
    public static final int RESPONSE_TIME_MIN_S = 10;
    public static final int RESPONSE_TIME_MAX_S = 30;

    /** {@code max_session_duration_min} — 20 à 30 min. */
    public static final int MAX_SESSION_DURATION_MIN_LOW = 20;
    public static final int MAX_SESSION_DURATION_MIN_HIGH = 30;

    // ── Agrégation (fiche) ───────────────────────────────────────────────────

    /** Score maximum d'une dimension (6 items × 3). */
    public static final int DIMENSION_MAX = ITEMS_PER_DIMENSION * ITEM_SCORE_MAX; // 18

    /** Score brut maximum (5 dimensions × 18). */
    public static final int RAW_MAX = CAPABILITIES_COUNT * DIMENSION_MAX; // 90

    // ── Règle DT (fiche — seule dimension dont le score dépend du temps) ──────

    /** {@code dt_time_limit_base_s} — temps imparti de base d'un item DT (avant multiplicateur langue). */
    public static final int DT_TIME_LIMIT_BASE_S = 7;

    /** Seuil de rapidité DT : latence &lt; 75 % du temps imparti effectif → réponse « rapide ». */
    public static final double DT_FAST_THRESHOLD_RATIO = 0.75;

    /** Points d'un item DT correct ET rapide (&lt; 75 %). */
    public static final int DT_FAST_POINTS = 3;

    /** Points d'un item DT correct MAIS lent (≥ 75 %). */
    public static final int DT_SLOW_POINTS = 2;

    /**
     * Multiplicateurs linguistiques <b>FOURNIS</b> par la fiche (définitifs).
     * Les autres langues (es/it/pt/ar) relèvent de la couche provisoire.
     */
    public static final Map<String, Double> LANGUAGE_MULTIPLIERS = Map.of(
        "en", 1.00,
        "fr", 1.20,
        "de", 1.25
    );

    /** Multiplicateur linguistique fourni (définitif) pour un code langue, si connu. */
    public static Optional<Double> providedLanguageMultiplier(String languageCode) {
        if (languageCode == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(LANGUAGE_MULTIPLIERS.get(languageCode.trim().toLowerCase(Locale.ROOT)));
    }

    /**
     * Temps imparti EFFECTIF d'un item DT, en millisecondes :
     * {@code dt_time_limit_base_s × 1000 × multiplicateur_langue + calibration_offset_ms}.
     *
     * <p>Double ajustement de la fiche : d'abord la langue (allongement du temps
     * de lecture), puis le calibrage appareil (latence machine). Un appareil lent
     * voit donc son seuil remonté et ne bascule pas artificiellement 3 → 2.
     *
     * @param languageMultiplier multiplicateur linguistique (fourni ou provisoire)
     * @param calibrationOffsetMs offset technique appareil (0 si aucun calibrage)
     */
    public static double dtEffectiveLimitMs(double languageMultiplier, double calibrationOffsetMs) {
        double offset = Math.max(0.0, calibrationOffsetMs);
        return DT_TIME_LIMIT_BASE_S * 1000.0 * languageMultiplier + offset;
    }

    // ── Imputation des items manquants (fiche) ───────────────────────────────

    /**
     * {@code max_imputable_missing} — au plus 2 items manquants dans un bloc sont
     * imputés par la moyenne du bloc ; au-delà, le bloc est <b>non exploitable</b>.
     */
    public static final int MAX_IMPUTABLE_MISSING = 2;

    /**
     * Score d'une dimension /18 après imputation, ou {@code empty} si le bloc est
     * non exploitable (&gt; 2 items manquants) :
     * <ul>
     *   <li>0 manquant → somme des 6 items ;</li>
     *   <li>≤ 2 manquants → chaque item manquant est imputé par la <b>moyenne du
     *       bloc</b> (⇔ moyenne des items présents × 6), arrondie ;</li>
     *   <li>&gt; 2 manquants → bloc non exploitable.</li>
     * </ul>
     *
     * @param answeredItemScores scores /3 des items RÉPONDUS de la dimension
     */
    public static OptionalInt imputedDimensionScore(List<Integer> answeredItemScores) {
        int answered = answeredItemScores.size();
        int missing = ITEMS_PER_DIMENSION - answered;
        if (missing < 0) {
            throw new IllegalArgumentException(
                "Trop d'items pour une dimension : " + answered + " > " + ITEMS_PER_DIMENSION);
        }
        if (missing > MAX_IMPUTABLE_MISSING) {
            return OptionalInt.empty(); // bloc non exploitable
        }
        if (answered == 0) {
            return OptionalInt.empty(); // aucun item : rien à imputer
        }
        double mean = answeredItemScores.stream().mapToInt(Integer::intValue).average().orElse(0.0);
        return OptionalInt.of((int) Math.round(mean * ITEMS_PER_DIMENSION));
    }

    /** Dimensions attendues (ordre stable). */
    public static List<DecisionDimension> dimensions() {
        return List.of(DecisionDimension.values());
    }
}
