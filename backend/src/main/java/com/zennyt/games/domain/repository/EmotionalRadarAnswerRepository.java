package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.EmotionalRadarAnswer;

import java.util.List;
import java.util.UUID;

/**
 * Port de persistance des réponses notées d'« Emotional Radar ».
 *
 * <p>Ces réponses sont la <b>source de vérité du score</b> : elles sont écrites par
 * le serveur au moment où il corrige une scène, puis relues à la soumission finale
 * pour calculer le score du mini-jeu. Le client n'intervient jamais dans ce chemin.
 */
public interface EmotionalRadarAnswerRepository {

    /**
     * Enregistre (ou remplace) la réponse notée d'une scène.
     *
     * <p>Le remplacement rend l'opération idempotente : re-valider la même scène
     * après une coupure réseau ne crée pas de doublon et ne double pas les points.
     */
    EmotionalRadarAnswer save(EmotionalRadarAnswer answer);

    /** Réponses déjà notées pour une session, triées par ordre de scène. */
    List<EmotionalRadarAnswer> findBySessionId(UUID sessionId);

    /** Une scène a-t-elle déjà été validée dans cette session ? */
    boolean existsBySessionIdAndSceneId(UUID sessionId, UUID sceneId);
}
