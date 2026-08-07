package com.zennyt.games.domain.config;

/**
 * Protocole expérimental « Je continue ».
 *
 * <p>Il s'agit du Long Rosvold CPT X/AX, jamais du Conners CPT-3. Ces constantes
 * constituent la source de vérité partagée par le générateur, la validation et
 * le scoring serveur.
 */
public final class ContinuousAttentionConfig {

    public static final String PROTOCOL_VERSION = "ROSVOLD_LONG_V1";
    public static final int PRACTICE_BLOCK_COUNT = 2;
    public static final int TEST_BLOCK_COUNT = 20;
    public static final int TRIALS_PER_BLOCK = 31;
    public static final int X_TARGETS_PER_BLOCK = 8;
    public static final int AX_TARGETS_PER_BLOCK = 6;
    public static final int LETTER_DISPLAY_MS = 690;
    public static final int ISI_MS = 230;
    public static final int TRIAL_CYCLE_MS = LETTER_DISPLAY_MS + ISI_MS;
    public static final int EPOCH_BLOCK_COUNT = 5;
    public static final int EPOCH_COUNT_PER_TEST_PHASE =
        TEST_BLOCK_COUNT / EPOCH_BLOCK_COUNT;
    public static final int TOTAL_BLOCK_COUNT =
        2 * (PRACTICE_BLOCK_COUNT + TEST_BLOCK_COUNT);
    public static final int TOTAL_TRIAL_COUNT = TOTAL_BLOCK_COUNT * TRIALS_PER_BLOCK;
    public static final int RESPONSE_CODE_NONE = 0;
    public static final int RESPONSE_CODE_SPACE = 57;
    public static final int SCORE_MAX = 100;

    // PROVISOIRE — à valider sur appareils réels
    public static final int TIMING_TOLERANCE_MS = 100;

    /** Lettres distractrices de la phase X : A-W, Y et Z (X exclu). */
    public static final String X_DISTRACTOR_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWYZ";
    /** Alphabet complet utilisé par les distracteurs de la phase AX. */
    public static final String AX_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    /** État de secours public et stable lorsque FNV-1a produit exactement zéro. */
    public static final int ZERO_SEED_FALLBACK = 0x6D2B79F5;

    private ContinuousAttentionConfig() {
    }
}
