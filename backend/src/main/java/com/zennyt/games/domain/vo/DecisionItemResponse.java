package com.zennyt.games.domain.vo;

/**
 * Réponse mesurée à UN item « Je Décide ».
 *
 * <p>Ce sont des <b>mesures</b> objectives (jamais un score ni une qualité) : le
 * client transmet l'item, l'option choisie et le temps ; la QUALITÉ de l'option
 * (donc les points) est décidée serveur via le {@code DecisionScenarioCatalog}.
 * La {@code dimension} est fournie pour cohérence/regroupement mais le catalogue
 * fait autorité.
 *
 * @param itemId               identifiant de l'item (clé du catalogue)
 * @param dimension            dimension déclarée (catalogue autoritaire au calcul)
 * @param selectedOptionId     option choisie (null/blank si non répondu)
 * @param responseTimeMs       temps de réponse brut mesuré (ms)
 * @param answered             true si l'item a été répondu (sinon imputation)
 * @param decisionChangesCount nb de changements d'avis avant validation (indicateur)
 */
public record DecisionItemResponse(
    String itemId,
    DecisionDimension dimension,
    String selectedOptionId,
    int responseTimeMs,
    boolean answered,
    int decisionChangesCount
) {
    public DecisionItemResponse {
        if (itemId == null || itemId.isBlank()) {
            throw new IllegalArgumentException("itemId requis");
        }
        if (dimension == null) {
            throw new IllegalArgumentException("dimension requise");
        }
        if (responseTimeMs < 0) {
            throw new IllegalArgumentException("responseTimeMs doit être >= 0");
        }
        if (decisionChangesCount < 0) {
            throw new IllegalArgumentException("decisionChangesCount doit être >= 0");
        }
        if (answered && (selectedOptionId == null || selectedOptionId.isBlank())) {
            throw new IllegalArgumentException(
                "selectedOptionId requis quand answered=true (item " + itemId + ")");
        }
    }
}
