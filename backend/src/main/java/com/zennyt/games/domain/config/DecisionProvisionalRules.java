package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.OptionQuality;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * <b>COUCHE PROVISOIRE — un seul fichier.</b> Toutes les règles de « Je Décide »
 * qui ne sont PAS fournies par le psychologue et ont été <b>déduites logiquement</b>
 * sont isolées ici. Chaque constante est commentée {@code // PROVISOIRE — non fourni
 * par le psychologue}. Le moteur ({@code DecisionScoringService} / {@code DecisionConfig})
 * ne code jamais ces valeurs en dur : il les lit d'ici. <b>Remplacer le provisoire
 * ne demande aucune modification du moteur.</b>
 *
 * <p>Les 5 points à faire valider / remplacer (voir GAMES_MODULE.md) :
 * <ol>
 *   <li><b>a</b> — mapping option → score par QUALITÉ (pas par scénario) ;</li>
 *   <li><b>b</b> — poids SCW égaux (1.0) faute de poids fournis ;</li>
 *   <li><b>c</b> — bornes de niveau (seul ≥ 75 vient de la fiche) ;</li>
 *   <li><b>d</b> — dérivation de la note CS depuis la cohérence de la paire ;</li>
 *   <li><b>e</b> — multiplicateurs linguistiques es/it/pt + fallback ar.</li>
 * </ol>
 */
public final class DecisionProvisionalRules {

    private DecisionProvisionalRules() {
    }

    // ═══ a) Mapping option → score, par QUALITÉ (pas par scénario) ═══════════
    // PROVISOIRE — non fourni par le psychologue.
    // La fiche donne l'échelle 0..3 et le vocabulaire (optimal/satisfaisant/
    // partiel/déficitaire) ; on INVERSE la logique : chaque option porte une
    // OptionQuality (voir enum), et non un score par scénario. Le psychologue
    // n'aura qu'à étiqueter chaque option avec l'un de ces 4 mots.
    //
    // Le barème quality → points vit sur l'enum OptionQuality (échelle de la fiche).
    // Aucune constante à dupliquer ici : on documente que l'ÉTIQUETAGE est provisoire.

    /** Score /3 d'une option depuis sa qualité (délégué à l'échelle de la fiche). */
    public static int optionScore(OptionQuality quality) {
        return quality.points(); // PROVISOIRE (étiquetage) — barème 0..3 = fiche
    }

    // ═══ b) Poids SCW — égaux (1.0) ═════════════════════════════════════════
    // PROVISOIRE — non fourni par le psychologue.
    // La fiche dit « score composite standardisé pondéré » SANS donner les poids.
    // Poids égaux 1.0 pour les 5 dimensions ⇒ scw = raw/90 × 100. Le jour où les
    // vrais poids arrivent, changer ces 5 nombres suffit (le moteur ne bouge pas).

    /** Poids SCW par dimension. PROVISOIRE — poids égaux faute de valeurs fournies. */
    public static final Map<DecisionDimension, Double> SCW_WEIGHTS = buildEqualWeights();

    private static Map<DecisionDimension, Double> buildEqualWeights() {
        Map<DecisionDimension, Double> w = new LinkedHashMap<>();
        for (DecisionDimension d : DecisionDimension.values()) {
            w.put(d, 1.0); // PROVISOIRE
        }
        return Map.copyOf(w);
    }

    /**
     * Score Composite Standardisé Pondéré (SCW) /100 :
     * {@code scw = (Σ dim_i × poids_i) / (18 × Σ poids_i) × 100}.
     *
     * <p>Seules les dimensions <b>exploitables</b> (présentes dans la map) entrent
     * au numérateur ET au dénominateur. Avec poids égaux et 5 dimensions, cela
     * revient à {@code raw/90 × 100} — vérifié par test (raw=60 → 66,7).
     *
     * @param dimensionScores scores /18 des dimensions exploitables
     */
    public static double scw(Map<DecisionDimension, Integer> dimensionScores) {
        double numerator = 0.0;
        double weightSum = 0.0;
        for (Map.Entry<DecisionDimension, Integer> e : dimensionScores.entrySet()) {
            double weight = SCW_WEIGHTS.getOrDefault(e.getKey(), 1.0);
            numerator += e.getValue() * weight;
            weightSum += weight;
        }
        if (weightSum == 0.0) {
            return 0.0;
        }
        return numerator / (DecisionConfig.DIMENSION_MAX * weightSum) * 100.0;
    }

    // ═══ c) Bornes de niveau — seul ≥ 75 vient de la fiche ══════════════════
    // La fiche ne donne QUE : SCW ≥ 75 → Élevé. Les bornes inférieures sont
    // régulières et PROVISOIRES.

    /** Seuil « Élevé » — SEUL seuil fourni par la fiche (≥ 75). Non provisoire. */
    public static final int LEVEL_HIGH_MIN = 75;

    /** Borne basse « Normal ». PROVISOIRE — non fourni par le psychologue. */
    public static final int LEVEL_NORMAL_MIN = 60;

    /** Borne basse « Borderline ». PROVISOIRE — non fourni par le psychologue. */
    public static final int LEVEL_BORDERLINE_MIN = 45;

    /** Niveau décisionnel à partir du SCW /100. */
    public static String levelForScw(double scw) {
        if (scw >= LEVEL_HIGH_MIN) return "Élevé";           // ← fiche
        if (scw >= LEVEL_NORMAL_MIN) return "Normal";        // PROVISOIRE
        if (scw >= LEVEL_BORDERLINE_MIN) return "Borderline"; // PROVISOIRE
        return "Fragile";                                     // PROVISOIRE
    }

    // ═══ d) Règle CS — note dérivée de la cohérence de la paire ═════════════
    // PROVISOIRE — non fourni par le psychologue.
    // Format en paire liée : la note dérive de la cohérence entre les deux
    // réponses. C'est la définition même de la dimension « Cohérence & stabilité ».

    /** Niveau de cohérence observé entre les deux réponses d'une paire CS. */
    public enum CoherenceLevel {
        /** Réponses cohérentes entre elles. */
        COHERENT,
        /** Réponses partiellement cohérentes. */
        PARTIAL,
        /** Réponses contradictoires. */
        CONTRADICTORY
    }

    /**
     * Qualité d'un item CS dérivée du niveau de cohérence de la paire.
     * PROVISOIRE : cohérentes → OPTIMAL · partielles → SATISFACTORY · contradictoires → DEFICIENT.
     */
    public static OptionQuality coherenceQuality(CoherenceLevel level) {
        return switch (level) {
            case COHERENT -> OptionQuality.OPTIMAL;        // PROVISOIRE
            case PARTIAL -> OptionQuality.SATISFACTORY;    // PROVISOIRE (SATISFACTORY/PARTIAL)
            case CONTRADICTORY -> OptionQuality.DEFICIENT; // PROVISOIRE
        };
    }

    // ═══ e) Multiplicateurs linguistiques es/it/pt + fallback ar ════════════
    // PROVISOIRE — estimations sectorielles ; en/fr/de sont fournis (DecisionConfig).

    /** Multiplicateurs PROVISOIRES (estimations) pour les langues non fournies. */
    public static final Map<String, Double> PROVISIONAL_LANGUAGE_MULTIPLIERS = Map.of(
        "es", 1.22, // PROVISOIRE — estimation sectorielle
        "it", 1.18, // PROVISOIRE — estimation sectorielle
        "pt", 1.22  // PROVISOIRE — estimation sectorielle
        // ar → aucune estimation : fallback documenté ci-dessous.
    );

    /**
     * Fallback si la langue n'a aucun multiplicateur (ex. « ar »).
     * PROVISOIRE — on retient une valeur médiane (fr) plutôt que d'échouer.
     */
    public static final double LANGUAGE_FALLBACK_MULTIPLIER = 1.20;

    /**
     * Multiplicateur provisoire pour une langue non fournie par la fiche.
     * Retourne {@code empty} si la langue a bien un multiplicateur provisoire connu ;
     * sinon le fallback est appliqué par {@code DecisionScoringService} (et tracé).
     */
    public static Optional<Double> provisionalLanguageMultiplier(String languageCode) {
        if (languageCode == null) {
            return Optional.empty();
        }
        return Optional.ofNullable(
            PROVISIONAL_LANGUAGE_MULTIPLIERS.get(languageCode.trim().toLowerCase(Locale.ROOT)));
    }

    // ═══ Seuils d'interprétation « bas » / « élevé » par dimension ══════════
    // PROVISOIRE — non fourni par le psychologue.
    // Les TEXTES d'interprétation viennent de la fiche (définitifs) ; les seuils
    // numériques qui les DÉCLENCHENT (dimension « basse » / « élevée ») sont déduits.

    /** Une dimension /18 est « élevée » si son ratio ≥ ce seuil. PROVISOIRE. */
    public static final double DIMENSION_HIGH_RATIO = 0.66;

    /** Une dimension /18 est « basse » si son ratio ≤ ce seuil. PROVISOIRE. */
    public static final double DIMENSION_LOW_RATIO = 0.34;

    /** true si la dimension /18 est « élevée » (ratio ≥ {@link #DIMENSION_HIGH_RATIO}). */
    public static boolean isDimensionHigh(int dimensionScore) {
        return dimensionScore / (double) DecisionConfig.DIMENSION_MAX >= DIMENSION_HIGH_RATIO;
    }

    /** true si la dimension /18 est « basse » (ratio ≤ {@link #DIMENSION_LOW_RATIO}). */
    public static boolean isDimensionLow(int dimensionScore) {
        return dimensionScore / (double) DecisionConfig.DIMENSION_MAX <= DIMENSION_LOW_RATIO;
    }

    // ═══ Seuils de qualité de session ═══════════════════════════════════════
    // PROVISOIRE — non chiffré par la fiche (renforcés en mode non supervisé).

    /** Temps de réponse moyen minimum plausible (ms) — sinon suspicion de clic rapide. PROVISOIRE. */
    public static final double MIN_PLAUSIBLE_AVG_TIME_MS = 1500.0;

    /** Taux max de réponses « impulsives » (sous le plancher) toléré. PROVISOIRE. */
    public static final double MAX_IMPULSIVE_RATE = 0.30;

    /** Taux max de réponses aléatoires estimé toléré. PROVISOIRE. */
    public static final double MAX_RANDOM_RESPONSE_RATE = 0.30;

    /** Offset de calibrage au-delà duquel la latence appareil est jugée hors norme (ms). PROVISOIRE. */
    public static final double MAX_DEVICE_LATENCY_OFFSET_MS = 100.0;

    /**
     * Facteur de renforcement des contrôles en mode non supervisé. PROVISOIRE :
     * les seuils de plausibilité sont resserrés (× ce facteur) sans surveillance.
     */
    public static final double UNSUPERVISED_STRICTNESS_FACTOR = 1.25;
}
