package com.zennyt.games.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.api.dto.DecisionDtos;
import com.zennyt.games.application.usecase.GetDecisionFormUseCase;
import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.OptionQuality;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * La clé de correction « Je Décide » ne doit jamais quitter le serveur.
 *
 * <p>Le VO domaine {@link DecisionFormCatalog.Content} transporte volontairement la
 * qualité de chaque option ; c'est {@code DecisionDtos} qui la laisse tomber. Ce
 * test s'exerce sur le <b>JSON réellement sérialisé</b>, pas sur les champs du DTO :
 * un getter ajouté par mégarde, un champ hérité ou une annotation Jackson mal posée
 * réintroduirait la fuite sans changer la déclaration du record.
 */
class DecisionItemsProjectionTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Un item par format, avec les quatre qualités représentées. */
    private static GetDecisionFormUseCase.Result fixture() {
        var standard = new DecisionFormCatalog.Content(
            "II-1", DecisionDimension.II, DecisionItemFormat.STANDARD, null,
            "Vous préparez un déplacement professionnel…", "Classez les trois options.", false,
            List.of(
                new DecisionFormCatalog.Content.Option("II-1-o1", "Je choisis B…", OptionQuality.OPTIMAL),
                new DecisionFormCatalog.Content.Option("II-1-o2", "Je choisis B car…", OptionQuality.SATISFACTORY),
                new DecisionFormCatalog.Content.Option("II-1-o3", "Je choisis C car…", OptionQuality.PARTIAL),
                new DecisionFormCatalog.Content.Option("II-1-o4", "Je choisis A car…", OptionQuality.DEFICIENT)));

        var timed = new DecisionFormCatalog.Content(
            "DT-7", DecisionDimension.DT, DecisionItemFormat.TEMPORAL_DECISION, null,
            "Vignette réutilisée de II-7.", "Vous disposez de 7 secondes.", false,
            List.of(
                new DecisionFormCatalog.Content.Option("DT-7-A", "Option A", OptionQuality.DEFICIENT),
                new DecisionFormCatalog.Content.Option("DT-7-B", "Option B", OptionQuality.OPTIMAL)));

        var pair = new DecisionFormCatalog.Content(
            "CS-1a", DecisionDimension.CS, DecisionItemFormat.COHERENCE_PAIR, "CS-1",
            "Cadrage GAIN…", "Choisissez un plan.", true,
            List.of(
                new DecisionFormCatalog.Content.Option("CS-1a-A", "Plan A", OptionQuality.SATISFACTORY),
                new DecisionFormCatalog.Content.Option("CS-1a-B", "Plan B", OptionQuality.SATISFACTORY)));

        return new GetDecisionFormUseCase.Result("A", List.of(standard, timed, pair), 8400L, 6);
    }

    @Test
    @DisplayName("aucune qualité d'option ne survit à la sérialisation de la réponse")
    void noCorrectionKeyIsSerialized() throws Exception {
        String json = MAPPER.writeValueAsString(DecisionDtos.ItemListResponse.from(fixture()));

        for (OptionQuality quality : OptionQuality.values()) {
            assertFalse(json.contains(quality.name()),
                "La qualité " + quality + " fuit dans la réponse : " + json);
        }
        for (String forbidden : List.of("quality", "score", "points", "optimal", "correct")) {
            assertFalse(json.toLowerCase().contains("\"" + forbidden),
                "Champ interdit « " + forbidden + " » dans la réponse : " + json);
        }
        // Garde-fou : si un jour la sérialisation renvoyait un objet vide, les
        // assertions ci-dessus passeraient sans rien prouver.
        assertTrue(json.contains("\"II-1-o1\""), "Le contenu attendu manque : " + json);
    }

    @Test
    @DisplayName("le temps imparti n'est porté que par les items chronométrés")
    void timeLimitOnlyOnTemporalItems() {
        var response = DecisionDtos.ItemListResponse.from(fixture());

        assertEquals("A", response.formCode());
        assertEquals(6, response.itemsPerDimension());
        for (DecisionDtos.ItemView item : response.items()) {
            if (item.format() == DecisionItemFormat.TEMPORAL_DECISION) {
                assertEquals(8400L, item.timeLimitMs());
            } else {
                assertNull(item.timeLimitMs(),
                    "Temps imparti sur un item non chronométré : " + item.itemId());
            }
        }
    }

    @Test
    @DisplayName("l'identifiant de paire est conservé : les deux cadrages CS restent liés")
    void pairIdSurvivesProjection() {
        var pair = DecisionDtos.ItemListResponse.from(fixture()).items().stream()
            .filter(i -> i.format() == DecisionItemFormat.COHERENCE_PAIR)
            .findFirst().orElseThrow();

        assertEquals("CS-1", pair.pairId());
        assertNotNull(pair.vignette());
    }

    @Test
    @DisplayName("chaque option garde sa clé et son libellé, et rien d'autre")
    void optionKeepsOnlyIdAndLabel() {
        long fields = Arrays.stream(DecisionDtos.OptionView.class.getRecordComponents()).count();
        assertEquals(2, fields,
            "OptionView a gagné un composant : vérifier qu'il ne publie pas la correction.");
    }
}
