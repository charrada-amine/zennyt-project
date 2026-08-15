package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.config.EmotionalRadarV2ProvisionalRules;
import com.zennyt.games.domain.vo.RadarSceneOutcome;
import com.zennyt.games.domain.vo.Score;

import java.util.List;

/**
 * Score « jeu » d'« Emotional Radar v2 » ({@code radar_emotion_score}, 0–10) — la
 * couche <b>visible du joueur</b>, à usage gamification uniquement (« Niveau 3
 * atteint, 7/10 »). Utilisable dès maintenant, contrairement au theta.
 *
 * <p>Formule PROVISOIRE (le brief ne la fixe pas) isolée dans
 * {@link EmotionalRadarV2ProvisionalRules} : combinaison du niveau atteint (poids
 * majeur, « façon jeu vidéo ») et de la précision globale.
 */
public final class RadarGameScoreService {

    /** Score /10 + niveau global textuel, à partir des scènes notées et du niveau final. */
    public Score score(List<RadarSceneOutcome> outcomes, int finalLevel) {
        if (outcomes == null || outcomes.isEmpty()) {
            throw new IllegalArgumentException("aucune scène notée : score impossible");
        }
        double levelComponent = finalLevel / (double) EmotionalRadarV2Config.DIFFICULTY_LEVELS;
        double accuracyComponent = accuracy(outcomes);

        double raw10 = (levelComponent * EmotionalRadarV2ProvisionalRules.GAME_SCORE_LEVEL_WEIGHT
            + accuracyComponent * EmotionalRadarV2ProvisionalRules.GAME_SCORE_ACCURACY_WEIGHT) * 10.0;

        int points = (int) Math.round(Math.max(0.0, Math.min(10.0, raw10)));
        return new Score(points, 10, EmotionalRadarV2ProvisionalRules.emotionalLevel(points));
    }

    /** Précision globale (0..1) : émotions correctement identifiées / scènes jouées. */
    public double accuracy(List<RadarSceneOutcome> outcomes) {
        long ok = outcomes.stream().filter(RadarSceneOutcome::correct).count();
        return outcomes.isEmpty() ? 0.0 : ok / (double) outcomes.size();
    }
}
