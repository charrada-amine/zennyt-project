package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarV2Config;

import java.util.List;

/**
 * Moteur de difficulté <b>adaptative</b> d'« Emotional Radar v2 » (admin table
 * {@code adaptive_difficulty}). Décide, après chaque scène, si le joueur monte,
 * descend ou reste, à partir de sa réussite sur une <b>fenêtre glissante</b> de 3–4
 * scènes : &gt; 70 % → +1 niveau, &lt; 40 % → −1 niveau, sinon inchangé.
 *
 * <p>Java pur, sans état : on lui passe l'historique et le niveau courant, il rend le
 * niveau suivant. Le contrôle des deux axes (charge de choix vs finesse sémantique)
 * permet, via les métriques, de distinguer sur quoi un joueur bute.
 */
public final class AdaptiveDifficultyService {

    /** Décision de transition de niveau. */
    public enum Transition { UP, DOWN, STAY }

    /**
     * Niveau après une scène, à partir de l'historique de réussite (true = réussi).
     *
     * <p>La décision n'est prise que si la fenêtre a au moins
     * {@link EmotionalRadarV2Config#EVALUATION_WINDOW_MIN} scènes ; sinon on reste.
     * On évalue sur les {@link EmotionalRadarV2Config#EVALUATION_WINDOW_MAX} dernières.
     */
    public int nextLevel(int currentLevel, List<Boolean> recentOutcomes) {
        return switch (decide(currentLevel, recentOutcomes)) {
            case UP -> Math.min(currentLevel + 1, EmotionalRadarV2Config.DIFFICULTY_LEVELS);
            case DOWN -> Math.max(currentLevel - 1, 1);
            case STAY -> currentLevel;
        };
    }

    /** Transition brute (UP/DOWN/STAY) — exposée pour les métriques d'historique. */
    public Transition decide(int currentLevel, List<Boolean> recentOutcomes) {
        if (recentOutcomes == null || recentOutcomes.size() < EmotionalRadarV2Config.EVALUATION_WINDOW_MIN) {
            return Transition.STAY;
        }
        int window = Math.min(recentOutcomes.size(), EmotionalRadarV2Config.EVALUATION_WINDOW_MAX);
        List<Boolean> slice = recentOutcomes.subList(recentOutcomes.size() - window, recentOutcomes.size());
        double accuracy = slice.stream().mapToInt(b -> b ? 1 : 0).average().orElse(0.0);

        if (accuracy >= EmotionalRadarV2Config.LEVEL_UP_THRESHOLD
            && currentLevel < EmotionalRadarV2Config.DIFFICULTY_LEVELS) {
            return Transition.UP;
        }
        if (accuracy <= EmotionalRadarV2Config.LEVEL_DOWN_THRESHOLD && currentLevel > 1) {
            return Transition.DOWN;
        }
        return Transition.STAY;
    }
}
