package com.zennyt.games.domain.catalog;

import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.OptionQuality;

import java.util.List;
import java.util.UUID;

/**
 * Port de <b>lecture</b> — contenu d'une forme de passation « Je Décide ».
 *
 * <p>Distinct de {@link DecisionScenarioCatalog}, et volontairement. Le port de
 * notation ne connaît qu'un triplet (dimension, format, qualité par option) : il
 * n'a ni vignette, ni énoncé d'option, donc il ne peut pas servir l'écran. Élargir
 * sa signature ferait entrer du contenu de présentation dans le chemin du barème —
 * on préfère deux ports étroits qu'un port fourre-tout.
 *
 * <p><b>La clé de correction voyage ici</b> ({@link Content.Option#quality}), comme
 * dans {@code GetEmotionalRadarScenesUseCase} : le domaine n'a pas à savoir ce qui
 * est publiable. C'est le DTO du contrôleur qui projette sans la qualité, et un
 * test de sérialisation vérifie qu'aucune ne fuit.
 */
public interface DecisionFormCatalog {

    /**
     * Items d'une forme, dans l'ordre de passation.
     *
     * @param formCode code de forme (A/B/C/D)
     * @return les {@code DecisionConfig.TOTAL_ITEMS} items, ou une liste vide si la
     *         forme n'est pas seedée
     */
    List<Content> form(String formCode);

    /** Published administration bank, with legacy form fallback for old sessions. */
    default List<Content> bank(UUID bankId, String fallbackFormCode) {
        return form(fallbackFormCode);
    }

    /**
     * Un item prêt à être présenté.
     *
     * @param vignette            texte de la situation, <b>déjà résolu</b> : les items
     *                            DT n'ont pas de vignette propre et réutilisent celle
     *                            de leur homologue II, la référence est suivie ici
     * @param task                consigne (« Vous disposez de 7 secondes… »)
     * @param provisionalScoring  true → item en notation neutre provisoire
     */
    record Content(
        String itemId,
        DecisionDimension dimension,
        DecisionItemFormat format,
        String pairId,
        String vignette,
        String task,
        boolean provisionalScoring,
        List<Option> options
    ) {
        public Content {
            options = options == null ? List.of() : List.copyOf(options);
        }

        /** Option proposée. {@code quality} est la clé de correction — jamais publiée. */
        public record Option(String optionId, String label, OptionQuality quality) {
        }
    }
}
