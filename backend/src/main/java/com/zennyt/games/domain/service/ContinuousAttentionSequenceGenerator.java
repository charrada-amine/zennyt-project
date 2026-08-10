package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.vo.ContinuousAttentionBlockMetric;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionPhase;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Générateur déterministe Long Rosvold partagé conceptuellement avec le mobile.
 *
 * <p>Algorithmes figés : FNV-1a 32 bits UTF-8, xorshift32, modulo non signé et
 * Fisher-Yates. Le backend reconstruit ainsi chaque lettre sans faire confiance
 * au payload.
 */
public final class ContinuousAttentionSequenceGenerator {

    public record GeneratedBlock(
        ContinuousAttentionPhase phase,
        int blockIndex,
        List<String> letters
    ) {
        public GeneratedBlock {
            letters = List.copyOf(letters);
        }
    }

    public List<GeneratedBlock> generate(UUID sessionId) {
        String material = sessionId.toString().toLowerCase(Locale.ROOT)
            + "|" + ContinuousAttentionConfig.PROTOCOL_VERSION;
        XorShift32 random = new XorShift32(fnv1a32(material));
        List<GeneratedBlock> result = new ArrayList<>(
            ContinuousAttentionConfig.TOTAL_BLOCK_COUNT);

        for (ContinuousAttentionPhase phase :
            List.of(ContinuousAttentionPhase.X_PRACTICE,
                ContinuousAttentionPhase.X_TEST)) {
            for (int block = 1; block <= phase.expectedBlockCount(); block++) {
                result.add(new GeneratedBlock(phase, block, generateXBlock(random)));
            }
        }

        char previous = '\0';
        for (ContinuousAttentionPhase phase :
            List.of(ContinuousAttentionPhase.AX_PRACTICE,
                ContinuousAttentionPhase.AX_TEST)) {
            for (int block = 1; block <= phase.expectedBlockCount(); block++) {
                List<String> letters = generateAxBlock(random, previous);
                previous = letters.get(letters.size() - 1).charAt(0);
                result.add(new GeneratedBlock(phase, block, letters));
            }
        }
        return List.copyOf(result);
    }

    /** Rejette toute lettre client différente de la séquence reconstruite. */
    public void validate(UUID sessionId, ContinuousAttentionMetrics metrics) {
        List<GeneratedBlock> expected = generate(sessionId);
        for (int blockIndex = 0; blockIndex < expected.size(); blockIndex++) {
            GeneratedBlock generated = expected.get(blockIndex);
            ContinuousAttentionBlockMetric actual = metrics.blocks().get(blockIndex);
            if (generated.phase() != actual.phase()
                || generated.blockIndex() != actual.blockIndex()) {
                throw new IllegalArgumentException("Bloc différent de la séquence déterministe");
            }
            for (int trialIndex = 0; trialIndex < generated.letters().size(); trialIndex++) {
                ContinuousAttentionTrialMetric trial = actual.trials().get(trialIndex);
                if (!generated.letters().get(trialIndex).equals(trial.currentLetter())) {
                    throw new IllegalArgumentException(
                        "Lettre différente de la séquence déterministe à "
                            + actual.phase() + " #" + actual.blockIndex()
                            + "/" + trial.trialIndex());
                }
            }
        }
    }

    private static List<String> generateXBlock(XorShift32 random) {
        List<String> letters = new ArrayList<>(ContinuousAttentionConfig.TRIALS_PER_BLOCK);
        for (int i = 0; i < ContinuousAttentionConfig.X_TARGETS_PER_BLOCK; i++) {
            letters.add("X");
        }
        for (int i = ContinuousAttentionConfig.X_TARGETS_PER_BLOCK;
             i < ContinuousAttentionConfig.TRIALS_PER_BLOCK; i++) {
            int index = random.nextInt(
                ContinuousAttentionConfig.X_DISTRACTOR_LETTERS.length());
            letters.add(String.valueOf(
                ContinuousAttentionConfig.X_DISTRACTOR_LETTERS.charAt(index)));
        }
        fisherYates(letters, random);
        return List.copyOf(letters);
    }

    private static List<String> generateAxBlock(XorShift32 random, char previous) {
        List<Boolean> tokens = new ArrayList<>(25);
        for (int i = 0; i < ContinuousAttentionConfig.AX_TARGETS_PER_BLOCK; i++) {
            tokens.add(Boolean.TRUE);
        }
        while (tokens.size() < 25) {
            tokens.add(Boolean.FALSE);
        }
        fisherYates(tokens, random);

        List<String> letters = new ArrayList<>(ContinuousAttentionConfig.TRIALS_PER_BLOCK);
        for (boolean pair : tokens) {
            if (pair) {
                letters.add("A");
                previous = 'A';
                letters.add("X");
                previous = 'X';
            } else {
                char letter;
                do {
                    letter = ContinuousAttentionConfig.AX_LETTERS.charAt(
                        random.nextInt(ContinuousAttentionConfig.AX_LETTERS.length()));
                } while (previous == 'A' && letter == 'X');
                letters.add(String.valueOf(letter));
                previous = letter;
            }
        }
        return List.copyOf(letters);
    }

    private static <T> void fisherYates(List<T> values, XorShift32 random) {
        for (int i = values.size() - 1; i > 0; i--) {
            Collections.swap(values, i, random.nextInt(i + 1));
        }
    }

    /** FNV-1a 32 bits, débordement modulo 2^32 intentionnel. */
    public static int fnv1a32(String value) {
        int hash = 0x811C9DC5;
        for (byte octet : value.getBytes(StandardCharsets.UTF_8)) {
            hash ^= Byte.toUnsignedInt(octet);
            hash *= 0x01000193;
        }
        return hash;
    }

    /** PRNG xorshift32 ; l'état nul reçoit un fallback explicite et partagé. */
    public static final class XorShift32 {
        private int state;

        public XorShift32(int seed) {
            this.state = seed == 0 ? ContinuousAttentionConfig.ZERO_SEED_FALLBACK : seed;
        }

        public long nextUnsigned() {
            int value = state;
            value ^= value << 13;
            value ^= value >>> 17;
            value ^= value << 5;
            state = value;
            return Integer.toUnsignedLong(value);
        }

        public int nextInt(int bound) {
            if (bound <= 0) {
                throw new IllegalArgumentException("bound doit être > 0");
            }
            return (int) (nextUnsigned() % bound);
        }
    }
}
