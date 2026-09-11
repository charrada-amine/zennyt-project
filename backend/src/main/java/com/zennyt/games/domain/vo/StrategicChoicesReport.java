package com.zennyt.games.domain.vo;

import java.util.List;
import java.util.Map;

/**
 * Retour pédagogique de « Choix Stratégiques ».
 *
 * <p>Décrit la conduite du joueur sans rien lui révéler d'une « bonne réponse »
 * situation par situation : la banque reste au serveur.
 *
 * @param situationsPlayed          nombre de situations jouées
 * @param rawPoints                 somme des cotations retenues
 * @param maxPoints                 {@code situationsPlayed × 3}
 * @param optimalChoices            situations où la stratégie la mieux cotée a été retenue
 * @param counterProductiveChoices  situations où une stratégie cotée 0 a été retenue
 * @param mostUsedStrategy          stratégie la plus souvent retenue
 * @param distinctStrategiesUsed    nombre de stratégies différentes mobilisées —
 *                                  un joueur qui n'en emploie qu'une n'a pas
 *                                  adapté sa réponse au contexte
 * @param averageResponseTimeMs     temps de réponse moyen
 * @param chanceBaseline            score qu'une réponse au hasard obtiendrait
 *                                  sur les situations effectivement tirées
 * @param chanceCorrectedPercent    écart au hasard, ramené sur 100 — 0 = pas
 *                                  mieux qu'au hasard, 100 = optimal partout
 * @param copingProfile             répartition des réponses par famille de
 *                                  coping ; c'est la sortie défendable au sens
 *                                  de Carver, qui regroupe ses échelles au lieu
 *                                  de les ordonner
 * @param provisionalScoring        vrai tant que le barème n'est pas validé
 * @param situationsAwaitingReview  fiches jouées dont le document demande une
 *                                  validation du psychologue
 * @param level                     interprétation, assise sur l'indice CORRIGÉ
 */
public record StrategicChoicesReport(
    int situationsPlayed,
    int rawPoints,
    int maxPoints,
    int optimalChoices,
    int counterProductiveChoices,
    StrategicChoiceStrategy mostUsedStrategy,
    int distinctStrategiesUsed,
    int averageResponseTimeMs,
    double chanceBaseline,
    double chanceCorrectedPercent,
    Map<CopingFamily, Integer> copingProfile,
    boolean provisionalScoring,
    List<String> situationsAwaitingReview,
    String level
) {
    public StrategicChoicesReport {
        situationsAwaitingReview = List.copyOf(situationsAwaitingReview);
        copingProfile = Map.copyOf(copingProfile);
    }

    /** Part des réponses relevant de [family], en pourcentage des situations jouées. */
    public double sharePercent(CopingFamily family) {
        if (situationsPlayed <= 0) {
            return 0.0;
        }
        return copingProfile.getOrDefault(family, 0) * 100.0 / situationsPlayed;
    }
}
