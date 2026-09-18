package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.IstCondition;
import com.zennyt.games.domain.vo.IstPhase;

import java.util.List;

/**
 * Configuration <b>MOTEUR</b> de l'IST — Information Sampling Task.
 *
 * <p>Source : Clark, Robbins, Ersche &amp; Sahakian (2006), <i>Biological
 * Psychiatry</i>, 60(5), 515–522 : grille de 25 cases, deux couleurs, décision de
 * la couleur majoritaire, conditions « gain fixe » et « gain décroissant ». Les
 * choix non publiés (loi de génération des grilles, poids du score, seuils de
 * validité, échelle de confiance) vivent dans {@link IstProvisionalRules}.
 *
 * <p>Revue scientifique complète : {@code docs/PREUVES_SCIENTIFIQUES_JEUX_DECISION.md} §3.
 */
public final class IstConfig {

    private IstConfig() {
    }

    public static final String PROTOCOL_VERSION = "IST_CLARK_V1";

    /** {@code grid_side} — grille 5 × 5. */
    public static final int GRID_SIDE = 5;

    /** {@code box_count} — 25 cases : nombre impair, donc jamais d'égalité. */
    public static final int BOX_COUNT = GRID_SIDE * GRID_SIDE;

    /** Une couleur est majoritaire à partir de 13 cases sur 25. */
    public static final int MAJORITY_THRESHOLD = BOX_COUNT / 2 + 1;

    /** {@code test_trials_per_condition} — 10 essais notés par condition. */
    public static final int TEST_TRIALS_PER_CONDITION = 10;

    /** {@code fixed_win_points} — gain d'une réponse juste en gain fixe. */
    public static final int FIXED_WIN_POINTS = 100;

    /** {@code decreasing_win_start_points} — gain de départ en gain décroissant. */
    public static final int DECREASING_WIN_START_POINTS = 250;

    /** {@code decreasing_win_cost_per_box} — perte par case ouverte en gain décroissant. */
    public static final int DECREASING_WIN_COST_PER_BOX = 10;

    /** {@code incorrect_penalty_points} — perte d'une réponse fausse, deux conditions. */
    public static final int INCORRECT_PENALTY_POINTS = 100;

    /**
     * Ordre des essais : un entraînement par condition, puis un bloc de 10 en gain
     * fixe, puis un bloc de 10 en gain décroissant — ordre de la version d'origine.
     */
    public static final List<TrialSlot> TRIAL_ORDER = buildOrder();

    public static final int TOTAL_TRIAL_COUNT = TRIAL_ORDER.size();

    /** Position protocolaire d'un essai. */
    public record TrialSlot(int trialIndex, IstPhase phase, IstCondition condition) {
    }

    public static TrialSlot slot(int trialIndex) {
        if (trialIndex < 0 || trialIndex >= TOTAL_TRIAL_COUNT) {
            throw new IllegalArgumentException("Index d'essai hors protocole : " + trialIndex);
        }
        return TRIAL_ORDER.get(trialIndex);
    }

    /**
     * Points d'un essai selon la règle de la condition. Le gain décroissant ne
     * descend jamais sous zéro : 250 − 10 × 25 = 0 au pire.
     */
    public static int trialPoints(IstCondition condition, int boxesOpened, boolean correct) {
        if (!correct) {
            return -INCORRECT_PENALTY_POINTS;
        }
        return switch (condition) {
            case FIXED_WIN -> FIXED_WIN_POINTS;
            case DECREASING_WIN -> Math.max(0,
                DECREASING_WIN_START_POINTS - DECREASING_WIN_COST_PER_BOX * boxesOpened);
        };
    }

    private static List<TrialSlot> buildOrder() {
        java.util.ArrayList<TrialSlot> order = new java.util.ArrayList<>();
        order.add(new TrialSlot(0, IstPhase.PRACTICE, IstCondition.FIXED_WIN));
        order.add(new TrialSlot(1, IstPhase.PRACTICE, IstCondition.DECREASING_WIN));
        for (IstCondition condition : List.of(IstCondition.FIXED_WIN, IstCondition.DECREASING_WIN)) {
            for (int i = 0; i < TEST_TRIALS_PER_CONDITION; i++) {
                order.add(new TrialSlot(order.size(), IstPhase.TEST, condition));
            }
        }
        return List.copyOf(order);
    }
}
