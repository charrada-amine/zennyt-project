package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.config.IstProvisionalRules;
import com.zennyt.games.domain.service.ObjectLocationLayoutGenerator.XorShift32;
import com.zennyt.games.domain.vo.IstColor;
import com.zennyt.games.domain.vo.IstCondition;
import com.zennyt.games.domain.vo.IstPhase;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Grilles des 22 essais IST, dérivées de l'UUID de session.
 *
 * <p>Pour chaque essai : nombre de cases bleues tiré UNIFORMÉMENT dans
 * {@code IstProvisionalRules.BLUE_COUNT_MIN..MAX} — la loi même que
 * {@link IstPosteriorModel} utilise comme a priori — puis placement uniforme par
 * Fisher-Yates. C'est cette identité générateur / a priori qui rend P(correct)
 * exact pour notre tâche.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : FNV-1a + xorshift32 réutilisés de « Je place », ordre
 * exact des tirages reproduit dans
 * {@code mobile/lib/features/games/domain/config/ist_config.dart}.
 */
public final class IstLayoutGenerator {

    public record Layout(
        int trialIndex,
        IstPhase phase,
        IstCondition condition,
        List<IstColor> boxes,
        int blueCount,
        IstColor majorityColor
    ) {
        public Layout {
            boxes = List.copyOf(boxes);
        }
    }

    public List<Layout> generate(UUID sessionId) {
        String material = sessionId.toString().toLowerCase(Locale.ROOT)
            + "|" + IstConfig.PROTOCOL_VERSION;
        XorShift32 random = new XorShift32(ObjectLocationLayoutGenerator.fnv1a32(material));
        int support = IstProvisionalRules.BLUE_COUNT_MAX - IstProvisionalRules.BLUE_COUNT_MIN + 1;
        List<Layout> layouts = new ArrayList<>(IstConfig.TOTAL_TRIAL_COUNT);
        for (IstConfig.TrialSlot slot : IstConfig.TRIAL_ORDER) {
            int blueCount = IstProvisionalRules.BLUE_COUNT_MIN + random.nextInt(support);
            int[] cells = new int[IstConfig.BOX_COUNT];
            for (int i = 0; i < cells.length; i++) cells[i] = i;
            for (int i = cells.length - 1; i > 0; i--) {
                int j = random.nextInt(i + 1);
                int swap = cells[i];
                cells[i] = cells[j];
                cells[j] = swap;
            }
            IstColor[] boxes = new IstColor[IstConfig.BOX_COUNT];
            Arrays.fill(boxes, IstColor.ORANGE);
            for (int i = 0; i < blueCount; i++) boxes[cells[i]] = IstColor.BLUE;
            IstColor majority = blueCount >= IstConfig.MAJORITY_THRESHOLD
                ? IstColor.BLUE : IstColor.ORANGE;
            layouts.add(new Layout(slot.trialIndex(), slot.phase(), slot.condition(),
                Arrays.asList(boxes), blueCount, majority));
        }
        return List.copyOf(layouts);
    }
}
