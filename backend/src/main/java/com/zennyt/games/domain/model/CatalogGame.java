package com.zennyt.games.domain.model;

import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMode;

import java.util.EnumSet;
import java.util.Set;

/**
 * Les jeux du catalogue tels que le joueur les voit dans le hub — la base de
 * la <b>couverture</b> affichée (« Coverage n % »).
 *
 * <p>Distinct de {@link MiniGame} : « Memory Quest » est un seul mini-jeu
 * serveur, mais deux jeux pour le joueur (chiffres et images), qui se jouent
 * et se valident séparément. Tous les jeux du catalogue comptent, y compris
 * ceux encore fermés dans l'application : 100 % signifie que le joueur a
 * terminé chacun d'eux au moins une fois.
 */
public enum CatalogGame {
    MOVE_FAST,
    CONTINUOUS_ATTENTION,
    COORDINATION_TRACKING,
    MEMORY_QUEST_DIGITS,
    MEMORY_QUEST_IMAGES,
    OBJECT_LOCATION,
    DECISION,
    OPTIMAL_PATH,
    TASK_SCHEDULING,
    PREDICTIVE_PUZZLE,
    EMOTIONAL_RADAR,
    REFLECTIVE_PAUSE,
    STRATEGIC_CHOICES,
    BART,
    INFORMATION_SAMPLING;

    /**
     * Jeux du catalogue terminés par un résultat enregistré de [miniGame].
     *
     * <p>Une partie enregistrée est une partie complète : elle contient déjà
     * toutes ses manches ou niveaux (les quatre manches de Day Stack, les
     * scènes du Radar…). Pour Memory Quest, le mode joué dit lequel des deux
     * jeux — ou les deux, en mode complet — la partie termine.
     */
    public static Set<CatalogGame> completedBy(MiniGame miniGame, Object metrics) {
        return switch (miniGame) {
            case MOVE_FAST_CORE -> EnumSet.of(MOVE_FAST);
            case CONTINUOUS_ATTENTION_CORE -> EnumSet.of(CONTINUOUS_ATTENTION);
            case COORDINATION_TRACKING_CORE -> EnumSet.of(COORDINATION_TRACKING);
            case OBJECT_LOCATION_BINDING_CORE -> EnumSet.of(OBJECT_LOCATION);
            case DECISION_CORE -> EnumSet.of(DECISION);
            case OPTIMAL_PATH -> EnumSet.of(OPTIMAL_PATH);
            case TASK_SCHEDULING -> EnumSet.of(TASK_SCHEDULING);
            case PREVISION_PUZZLE -> EnumSet.of(PREDICTIVE_PUZZLE);
            case EMOTIONAL_RADAR_CORE -> EnumSet.of(EMOTIONAL_RADAR);
            case REFLECTIVE_PAUSE_CORE -> EnumSet.of(REFLECTIVE_PAUSE);
            case STRATEGIC_CHOICES_CORE -> EnumSet.of(STRATEGIC_CHOICES);
            case MEMORY_QUEST_CORE -> memoryQuest(metrics);
            case BART_CORE -> EnumSet.of(BART);
            case INFORMATION_SAMPLING_CORE -> EnumSet.of(INFORMATION_SAMPLING);
        };
    }

    private static Set<CatalogGame> memoryQuest(Object metrics) {
        MemoryQuestMode mode = metrics instanceof MemoryQuestMetrics m
            ? m.mode() : MemoryQuestMode.FULL;
        Set<CatalogGame> games = EnumSet.noneOf(CatalogGame.class);
        if (mode.playsDigits()) games.add(MEMORY_QUEST_DIGITS);
        if (mode.playsImages()) games.add(MEMORY_QUEST_IMAGES);
        return games;
    }
}
