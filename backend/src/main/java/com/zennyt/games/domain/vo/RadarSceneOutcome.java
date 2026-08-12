package com.zennyt.games.domain.vo;

/**
 * Résultat <b>noté serveur</b> d'une scène d'« Emotional Radar v2 » — la brique
 * autoritaire à partir de laquelle se calculent les deux scores (jeu + theta) et
 * tous les indicateurs de session. Le client n'envoie jamais ce record ; il est
 * produit par la correction serveur (émotion choisie vs jouée).
 *
 * @param sceneOrder        rang de la scène dans la session (1..N)
 * @param level             niveau de difficulté au moment de la scène (1..4)
 * @param choicesCount      nombre de choix proposés (axe charge cognitive)
 * @param sceneDifficulty   distance sémantique moyenne des choix (0..1 ; faible = dur)
 * @param correctKey        clé de l'émotion réellement jouée
 * @param selectedKey       clé de l'émotion choisie par le joueur
 * @param correct           l'émotion a-t-elle été correctement identifiée ?
 * @param semanticErrorDist si erreur, distance entre choix et bonne réponse (0..1) ; 0 si correct
 * @param stimulusIntensity intensité réellement jouée dans la vidéo (0=Faible,1=Modérée,2=Intense)
 * @param selectedIntensity intensité perçue déclarée par le joueur (même échelle)
 * @param responseTimeMs    temps de réponse
 * @param impulsive         réponse sous le plancher impulsif (&lt; 400 ms)
 * @param justificationScore qualité de la justification (0..5) ; -1 si non évaluée
 */
public record RadarSceneOutcome(
    int sceneOrder,
    int level,
    int choicesCount,
    double sceneDifficulty,
    String correctKey,
    String selectedKey,
    boolean correct,
    double semanticErrorDist,
    int stimulusIntensity,
    int selectedIntensity,
    int responseTimeMs,
    boolean impulsive,
    int justificationScore
) {

    public RadarSceneOutcome {
        if (correctKey == null || selectedKey == null) {
            throw new IllegalArgumentException("correctKey et selectedKey requis");
        }
        if (level < 1) {
            throw new IllegalArgumentException("level ≥ 1 requis : " + level);
        }
    }

    /** L'intensité perçue correspond-elle exactement à l'intensité jouée ? */
    public boolean intensityMatches() {
        return stimulusIntensity == selectedIntensity;
    }

    /** Sens de l'erreur d'intensité : -1 sous-estimée, +1 sur-estimée, 0 correcte. */
    public int intensityErrorDirection() {
        return Integer.compare(selectedIntensity, stimulusIntensity);
    }
}
