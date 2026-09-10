package com.zennyt.games.api.dto;

import com.zennyt.games.application.usecase.GetDecisionFormUseCase;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;

import java.util.List;

/**
 * DTO de sortie de « Je Décide » — <b>point de filtrage unique</b> entre le
 * catalogue serveur et le client.
 *
 * <p>Le VO domaine {@link DecisionFormCatalog.Content} transporte la qualité de
 * chaque option : c'est la clé de correction. Ces records la laissent tomber, et
 * n'exposent ni score, ni réponse attendue, ni {@code optimalOption}. Tout champ
 * ajouté ici doit être relu à cette aune — un test de sérialisation échoue si un
 * libellé de {@code OptionQuality} apparaît dans le JSON produit.
 */
public final class DecisionDtos {

    private DecisionDtos() {
    }

    /** Réponse de {@code GET /games/sessions/{id}/decision/items}. */
    public record ItemListResponse(String formCode, int itemsPerDimension, List<ItemView> items) {

        public static ItemListResponse from(GetDecisionFormUseCase.Result result) {
            return new ItemListResponse(
                result.formCode(),
                result.itemsPerDimension(),
                result.items().stream()
                    .map(content -> ItemView.from(content, result.dtTimeLimitMs()))
                    .toList());
        }
    }

    /**
     * Un item prêt à afficher.
     *
     * @param timeLimitMs temps imparti — uniquement pour {@code TEMPORAL_DECISION},
     *                    {@code null} partout ailleurs
     */
    public record ItemView(String itemId,
                           DecisionDimension dimension,
                           DecisionItemFormat format,
                           String pairId,
                           String vignette,
                           String task,
                           Long timeLimitMs,
                           List<OptionView> options) {

        static ItemView from(DecisionFormCatalog.Content content, long dtTimeLimitMs) {
            return new ItemView(
                content.itemId(),
                content.dimension(),
                content.format(),
                content.pairId(),
                content.vignette(),
                content.task(),
                content.format() == DecisionItemFormat.TEMPORAL_DECISION ? dtTimeLimitMs : null,
                content.options().stream().map(OptionView::from).toList());
        }
    }

    /** Option proposée — sans sa qualité, qui reste serveur. */
    public record OptionView(String optionId, String label) {

        static OptionView from(DecisionFormCatalog.Content.Option option) {
            return new OptionView(option.optionId(), option.label());
        }
    }
}
