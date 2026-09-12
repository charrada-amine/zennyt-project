package com.zennyt.games.domain.vo;

/**
 * Mesures brutes d'une situation de « Choix Stratégiques ».
 *
 * <p>Aucune cotation ne circule : le client dit quelle situation il a vue et
 * quelle stratégie il a retenue, le serveur note.
 *
 * @param situationId    identifiant de la fiche (CS-001 à CS-060)
 * @param selectedStrategy stratégie retenue par le joueur
 * @param responseTimeMs temps entre l'affichage de la situation et la validation
 * @param medium         support de présentation, facultatif
 */
public record StrategicChoiceAnswerMetric(
    String situationId,
    StrategicChoiceStrategy selectedStrategy,
    int responseTimeMs,
    StrategicChoiceMedium medium
) {
    public StrategicChoiceAnswerMetric {
        if (situationId == null || situationId.isBlank()) {
            throw new IllegalArgumentException("situationId requis");
        }
        if (selectedStrategy == null) {
            throw new IllegalArgumentException("selectedStrategy requise");
        }
        if (responseTimeMs < 0) {
            throw new IllegalArgumentException("responseTimeMs doit être >= 0");
        }
    }
}
