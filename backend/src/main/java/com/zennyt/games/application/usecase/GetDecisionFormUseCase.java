package com.zennyt.games.application.usecase;

import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.config.DecisionConfig;
import com.zennyt.games.domain.config.DecisionProvisionalRules;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.repository.GameSessionRepository;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Use case : servir les items « Je Décide » de la forme assignée à une session.
 *
 * <p>Renvoie les items <b>avec</b> la qualité de chaque option (VO domaine) : c'est
 * le contrôleur qui les projette dans un DTO expurgé. Même séparation que
 * {@link GetEmotionalRadarScenesUseCase} — le domaine n'a pas à connaître ce qui est
 * publiable, et le point de filtrage reste unique et auditable.
 *
 * <p>La forme vient de la <b>session persistée</b>, jamais d'un paramètre client :
 * un candidat ne choisit pas les items sur lesquels il sera évalué.
 */
@Service
public class GetDecisionFormUseCase {

    private final DecisionFormCatalog catalog;
    private final GameSessionRepository sessions;

    public GetDecisionFormUseCase(DecisionFormCatalog catalog, GameSessionRepository sessions) {
        this.catalog = catalog;
        this.sessions = sessions;
    }

    @Transactional(readOnly = true)
    public Result execute(UUID sessionId, String language) {
        GameSession session = sessions.findById(sessionId)
            .orElseThrow(() -> new NotFoundException("Session introuvable : " + sessionId));

        if (session.gameType() != GameType.DECISION) {
            throw new IllegalStateException(
                "Session " + sessionId + " de type " + session.gameType()
                    + " : les items « Je Décide » ne s'appliquent pas.");
        }
        String formCode = session.decisionFormCode();
        if (formCode == null) {
            throw new IllegalStateException(
                "Aucune forme « Je Décide » assignée à la session " + sessionId);
        }

        List<DecisionFormCatalog.Content> items = catalog.form(formCode);
        if (items.isEmpty()) {
            throw new IllegalStateException(
                "Forme « Je Décide » " + formCode + " absente du catalogue.");
        }

        // Temps imparti DT affiché au joueur : base × multiplicateur de langue.
        // Il n'intègre PAS calibrationOffsetMs — cet offset se déduit de la
        // télémétrie appareil, que le serveur ne reçoit qu'à la soumission. Le seuil
        // de notation est donc très légèrement plus permissif que le chronomètre
        // affiché, ce qui joue toujours en faveur du candidat.
        double multiplier = DecisionConfig.providedLanguageMultiplier(language)
            .orElseGet(() -> DecisionProvisionalRules.provisionalLanguageMultiplier(language)
                .orElse(DecisionProvisionalRules.LANGUAGE_FALLBACK_MULTIPLIER));
        long dtTimeLimitMs = Math.round(DecisionConfig.dtEffectiveLimitMs(multiplier, 0.0));

        return new Result(formCode, items, dtTimeLimitMs, DecisionConfig.ITEMS_PER_DIMENSION);
    }

    /**
     * @param items           items de la forme, dans l'ordre (clé de correction
     *                        incluse — à ne jamais sérialiser telle quelle)
     * @param dtTimeLimitMs   temps imparti des items {@code TEMPORAL_DECISION}
     */
    public record Result(String formCode,
                         List<DecisionFormCatalog.Content> items,
                         long dtTimeLimitMs,
                         int itemsPerDimension) {
    }
}
