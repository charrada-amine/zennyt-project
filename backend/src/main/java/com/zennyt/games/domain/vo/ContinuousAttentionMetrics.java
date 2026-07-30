package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Payload complet du protocole Long Rosvold.
 *
 * <p>La validation est volontairement stricte : ordre des 44 blocs, timeline
 * nominale, continuité inter-blocs et PRACTICE→TEST, cibles et valeur
 * {@code correct} recalculée. La correspondance à la séquence déterministe
 * dépend de l'UUID de session et est donc faite par le service de scoring.
 */
public record ContinuousAttentionMetrics(
    String protocolVersion,
    List<ContinuousAttentionBlockMetric> blocks,
    boolean sessionCompleted,
    boolean interrupted,
    int backgroundEventCount,
    int droppedFrameCount
) implements GameMetrics {

    public ContinuousAttentionMetrics {
        if (!ContinuousAttentionConfig.PROTOCOL_VERSION.equals(protocolVersion)) {
            throw new IllegalArgumentException(
                "protocolVersion attendu : " + ContinuousAttentionConfig.PROTOCOL_VERSION);
        }
        blocks = List.copyOf(Objects.requireNonNull(blocks, "blocks"));
        if (blocks.size() != ContinuousAttentionConfig.TOTAL_BLOCK_COUNT) {
            throw new IllegalArgumentException("Le protocole doit contenir exactement 44 blocs");
        }
        if (backgroundEventCount < 0 || droppedFrameCount < 0) {
            throw new IllegalArgumentException(
                "backgroundEventCount et droppedFrameCount doivent être positifs");
        }
        validateStructure(blocks);
    }

    private static void validateStructure(List<ContinuousAttentionBlockMetric> blocks) {
        int cursor = 0;
        for (ContinuousAttentionPhase phase : ContinuousAttentionPhase.values()) {
            for (int blockIndex = 1; blockIndex <= phase.expectedBlockCount(); blockIndex++) {
                ContinuousAttentionBlockMetric block = blocks.get(cursor++);
                if (block.phase() != phase || block.blockIndex() != blockIndex) {
                    throw new IllegalArgumentException(
                        "Ordre de blocs invalide : attendu " + phase + " #" + blockIndex);
                }
            }
        }

        Map<ContinuousAttentionPhase, Integer> phaseTrialOffsets =
            new EnumMap<>(ContinuousAttentionPhase.class);
        Map<ContinuousAttentionPhase, Long> previousActualOnsets =
            new EnumMap<>(ContinuousAttentionPhase.class);
        String previous = null;
        for (ContinuousAttentionBlockMetric block : blocks) {
            if (block.phase() == ContinuousAttentionPhase.AX_PRACTICE
                && block.blockIndex() == 1) {
                previous = null;
            }
            int offset = phaseTrialOffsets.getOrDefault(block.phase(), 0);
            int targets = 0;
            for (ContinuousAttentionTrialMetric trial : block.trials()) {
                if (!Objects.equals(previous, trial.previousLetter())) {
                    throw new IllegalArgumentException(
                        "previousLetter rompt la continuité à "
                            + block.phase() + " #" + block.blockIndex()
                            + "/" + trial.trialIndex());
                }
                long expectedOnset =
                    (long) (offset + trial.trialIndex() - 1)
                        * ContinuousAttentionConfig.TRIAL_CYCLE_MS;
                if (trial.scheduledOnsetMs() != expectedOnset) {
                    throw new IllegalArgumentException(
                        "scheduledOnsetMs invalide à " + block.phase()
                            + " #" + block.blockIndex() + "/" + trial.trialIndex());
                }
                Long previousActualOnset = previousActualOnsets.get(block.phase());
                if (previousActualOnset != null
                    && trial.actualOnsetMs() <= previousActualOnset) {
                    throw new IllegalArgumentException(
                        "actualOnsetMs doit être strictement croissant dans "
                            + block.phase());
                }
                previousActualOnsets.put(block.phase(), trial.actualOnsetMs());
                boolean target = isTarget(block.phase(), previous, trial.currentLetter());
                if (target) {
                    targets++;
                }
                int expectedCorrect = target == trial.responded() ? 1 : 0;
                if (trial.correct() != expectedCorrect) {
                    throw new IllegalArgumentException(
                        "correct diverge du recalcul serveur à "
                            + block.phase() + " #" + block.blockIndex()
                            + "/" + trial.trialIndex());
                }
                previous = trial.currentLetter();
            }
            phaseTrialOffsets.put(
                block.phase(), offset + ContinuousAttentionConfig.TRIALS_PER_BLOCK);
            int expectedTargets = block.phase().isAx()
                ? ContinuousAttentionConfig.AX_TARGETS_PER_BLOCK
                : ContinuousAttentionConfig.X_TARGETS_PER_BLOCK;
            if (targets != expectedTargets) {
                throw new IllegalArgumentException(
                    "Nombre de cibles invalide pour " + block.phase()
                        + " #" + block.blockIndex() + " : " + targets);
            }
        }
    }

    public static boolean isTarget(ContinuousAttentionPhase phase,
                                   String previousLetter,
                                   String currentLetter) {
        return phase.isAx()
            ? "A".equals(previousLetter) && "X".equals(currentLetter)
            : "X".equals(currentLetter);
    }
}
