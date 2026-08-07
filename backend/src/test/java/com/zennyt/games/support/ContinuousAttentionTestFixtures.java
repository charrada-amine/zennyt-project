package com.zennyt.games.support;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;
import com.zennyt.games.domain.service.ContinuousAttentionSequenceGenerator;
import com.zennyt.games.domain.vo.ContinuousAttentionBlockMetric;
import com.zennyt.games.domain.vo.ContinuousAttentionInputSource;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionPhase;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Fabrique test-only de payloads strictement alignés sur le générateur serveur. */
public final class ContinuousAttentionTestFixtures {

    @FunctionalInterface
    public interface ResponsePolicy {
        boolean respond(ContinuousAttentionPhase phase,
                        boolean target,
                        int targetOrdinal,
                        int nonTargetOrdinal);
    }

    private ContinuousAttentionTestFixtures() {
    }

    public static ContinuousAttentionMetrics perfect(UUID sessionId) {
        return metrics(sessionId, (phase, target, targetOrdinal, nonTargetOrdinal) -> target);
    }

    public static ContinuousAttentionMetrics neverRespond(UUID sessionId) {
        return metrics(sessionId, (phase, target, targetOrdinal, nonTargetOrdinal) -> false);
    }

    public static ContinuousAttentionMetrics alwaysRespond(UUID sessionId) {
        return metrics(sessionId, (phase, target, targetOrdinal, nonTargetOrdinal) -> true);
    }

    public static ContinuousAttentionMetrics metrics(UUID sessionId, ResponsePolicy policy) {
        List<ContinuousAttentionSequenceGenerator.GeneratedBlock> generated =
            new ContinuousAttentionSequenceGenerator().generate(sessionId);
        Map<ContinuousAttentionPhase, Integer> phaseOffsets =
            new EnumMap<>(ContinuousAttentionPhase.class);
        Map<ContinuousAttentionPhase, Integer> targetOrdinals =
            new EnumMap<>(ContinuousAttentionPhase.class);
        Map<ContinuousAttentionPhase, Integer> nonTargetOrdinals =
            new EnumMap<>(ContinuousAttentionPhase.class);
        List<ContinuousAttentionBlockMetric> blocks = new ArrayList<>(generated.size());

        String previous = null;
        for (ContinuousAttentionSequenceGenerator.GeneratedBlock generatedBlock : generated) {
            ContinuousAttentionPhase phase = generatedBlock.phase();
            if (phase == ContinuousAttentionPhase.AX_PRACTICE
                && generatedBlock.blockIndex() == 1) {
                previous = null;
            }
            int phaseOffset = phaseOffsets.getOrDefault(phase, 0);
            List<ContinuousAttentionTrialMetric> trials =
                new ArrayList<>(ContinuousAttentionConfig.TRIALS_PER_BLOCK);
            for (int index = 0; index < generatedBlock.letters().size(); index++) {
                String current = generatedBlock.letters().get(index);
                boolean target = ContinuousAttentionMetrics.isTarget(phase, previous, current);
                int targetOrdinal = target
                    ? targetOrdinals.merge(phase, 1, Integer::sum) : 0;
                int nonTargetOrdinal = !target
                    ? nonTargetOrdinals.merge(phase, 1, Integer::sum) : 0;
                boolean respond = policy.respond(
                    phase, target, targetOrdinal, nonTargetOrdinal);
                long scheduled =
                    (long) (phaseOffset + index) * ContinuousAttentionConfig.TRIAL_CYCLE_MS;
                Integer latency = respond ? 300 : null;
                trials.add(new ContinuousAttentionTrialMetric(
                    index + 1,
                    previous,
                    current,
                    respond ? ContinuousAttentionConfig.RESPONSE_CODE_SPACE
                        : ContinuousAttentionConfig.RESPONSE_CODE_NONE,
                    respond == target ? 1 : 0,
                    latency,
                    scheduled,
                    scheduled,
                    respond ? scheduled + latency : null,
                    ContinuousAttentionConfig.LETTER_DISPLAY_MS,
                    ContinuousAttentionConfig.ISI_MS,
                    respond ? ContinuousAttentionInputSource.KEYBOARD : null,
                    0,
                    false));
                previous = current;
            }
            blocks.add(new ContinuousAttentionBlockMetric(
                phase, generatedBlock.blockIndex(), trials));
            phaseOffsets.put(
                phase, phaseOffset + ContinuousAttentionConfig.TRIALS_PER_BLOCK);
        }

        return new ContinuousAttentionMetrics(
            ContinuousAttentionConfig.PROTOCOL_VERSION,
            blocks,
            true,
            false,
            0,
            0);
    }

    public static ContinuousAttentionMetrics replaceTrial(
            ContinuousAttentionMetrics source,
            int blockPosition,
            int trialPosition,
            ContinuousAttentionTrialMetric replacement) {
        List<ContinuousAttentionBlockMetric> blocks = new ArrayList<>(source.blocks());
        ContinuousAttentionBlockMetric oldBlock = blocks.get(blockPosition);
        List<ContinuousAttentionTrialMetric> trials = new ArrayList<>(oldBlock.trials());
        trials.set(trialPosition, replacement);
        blocks.set(blockPosition, new ContinuousAttentionBlockMetric(
            oldBlock.phase(), oldBlock.blockIndex(), trials));
        return new ContinuousAttentionMetrics(
            source.protocolVersion(), blocks, source.sessionCompleted(),
            source.interrupted(), source.backgroundEventCount(),
            source.droppedFrameCount());
    }
}
