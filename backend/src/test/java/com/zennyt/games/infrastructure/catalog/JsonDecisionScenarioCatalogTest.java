package com.zennyt.games.infrastructure.catalog;

import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.OptionQuality;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Vérifie que la banque « Je Décide » du psychologue (120 items) est chargée
 * correctement depuis {@code resources/games/decision_scenarios.json}, et que le
 * mini-jeu est désormais jouable.
 */
class JsonDecisionScenarioCatalogTest {

    private final JsonDecisionScenarioCatalog catalog = new JsonDecisionScenarioCatalog();

    @Test
    @DisplayName("La banque charge 120 items (24 par dimension) et n'est pas vide")
    void chargeLes120Items() {
        assertThat(catalog.isEmpty()).isFalse();
        assertThat(catalog.size()).isEqualTo(120);

        // II / ER / DT / RE : 24 items « <dim>-1..-24 ».
        for (String prefix : new String[] {"II", "ER", "DT", "RE"}) {
            long count = IntStream.rangeClosed(1, 24)
                .filter(n -> catalog.item(prefix + "-" + n).isPresent())
                .count();
            assertThat(count).as("items présents pour %s", prefix).isEqualTo(24);
        }
        // CS : 12 paires « CS-<n>a » / « CS-<n>b » = 24 items.
        long cs = IntStream.rangeClosed(1, 12)
            .filter(n -> catalog.item("CS-" + n + "a").isPresent()
                && catalog.item("CS-" + n + "b").isPresent())
            .count();
        assertThat(cs).as("paires CS présentes").isEqualTo(12);
    }

    @Test
    @DisplayName("II-1 : barème 0..3 mappé sur OptionQuality (STANDARD)")
    void iiItemEstNoteParQualite() {
        DecisionScenarioCatalog.Item item = catalog.item("II-1").orElseThrow();
        assertThat(item.dimension()).isEqualTo(DecisionDimension.II);
        assertThat(item.format()).isEqualTo(DecisionItemFormat.STANDARD);
        assertThat(item.qualityOf("II-1-o1")).isEqualTo(OptionQuality.OPTIMAL);      // score 3
        assertThat(item.qualityOf("II-1-o4")).isEqualTo(OptionQuality.DEFICIENT);    // score 0
    }

    @Test
    @DisplayName("DT-1 : chronométré, l'option optimale du document est OPTIMAL")
    void dtItemEstTemporelAvecOptionOptimale() {
        DecisionScenarioCatalog.Item item = catalog.item("DT-1").orElseThrow();
        assertThat(item.dimension()).isEqualTo(DecisionDimension.DT);
        assertThat(item.format()).isEqualTo(DecisionItemFormat.TEMPORAL_DECISION);
        assertThat(item.qualityOf("DT-1-B")).isEqualTo(OptionQuality.OPTIMAL);       // réponse optimale B
        assertThat(item.qualityOf("DT-1-A")).isEqualTo(OptionQuality.DEFICIENT);
    }

    @Test
    @DisplayName("CS : format paire liée, deux vignettes a/b par paire")
    void csItemEstUnePaireLiee() {
        DecisionScenarioCatalog.Item a = catalog.item("CS-1a").orElseThrow();
        DecisionScenarioCatalog.Item b = catalog.item("CS-1b").orElseThrow();
        assertThat(a.dimension()).isEqualTo(DecisionDimension.CS);
        assertThat(a.format()).isEqualTo(DecisionItemFormat.COHERENCE_PAIR);
        assertThat(b.format()).isEqualTo(DecisionItemFormat.COHERENCE_PAIR);
    }

    @Test
    @DisplayName("Le mini-jeu DECISION_CORE est jouable une fois la banque livrée")
    void decisionCoreEstJouable() {
        assertThat(MiniGame.DECISION_CORE.isPlayable()).isTrue();
    }
}
