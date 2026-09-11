package com.zennyt.games.domain.catalog;

import com.zennyt.games.domain.vo.StrategicChoiceStrategy;

import java.util.Set;

/**
 * Banque « Choix Stratégiques » vue par le domaine.
 *
 * <p>Le barème est ici, jamais chez le client : celui-ci remonte une situation
 * et la stratégie qu'il a choisie, le serveur en déduit la cotation.
 */
public interface StrategicChoicesCatalog {

    /** Identifiants connus (CS-001 à CS-060). */
    Set<String> situationIds();

    /** Cotation 0-3 de [strategy] dans [situationId]. */
    int score(String situationId, StrategicChoiceStrategy strategy);

    /** Meilleure cotation atteignable sur [situationId]. */
    int bestScore(String situationId);

    /**
     * Espérance d'une réponse au hasard sur [situationId] — moyenne des huit
     * cotations.
     *
     * <p>C'est la ligne de base contre laquelle le score se lit. Sans elle, un
     * 15/30 passerait pour « la moitié », alors que le hasard rapporte déjà
     * 38 % du maximum sur cette banque.
     */
    double chanceBaseline(String situationId);

    /**
     * Situation dont le document demande une validation du psychologue.
     *
     * <p>Le barème a été reconstruit par inférence, à partir des seuls titres et
     * sans visionnage des vidéos ; sa propre synthèse nomme trois fiches
     * ambiguës. Le drapeau suit jusqu'au rapport, pour qu'un score provisoire ne
     * se lise jamais comme un score validé.
     */
    boolean needsPsychologistValidation(String situationId);
}
