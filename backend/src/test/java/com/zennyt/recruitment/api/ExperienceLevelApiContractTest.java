package com.zennyt.recruitment.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import com.zennyt.recruitment.api.dto.CreateJobOfferRequest;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Documente l'impact exact du changement cassant F31 (décision D-A) sur les
 * clients de l'API, pour que la squad web sache précisément ce qui casse et ce
 * qui dégrade en douceur.
 *
 * <p>V29 avait renommé positionnellement les 4 bandes de niveau ; F31 revient à
 * l'échelle du cahier des charges. Anciennes valeurs → nouvelles :
 * {@code MID → SENIOR}, {@code SENIOR → LEAD}, {@code EXECUTIVE → MANAGER},
 * {@code JUNIOR} inchangé.
 *
 * <p><b>Deux comportements très différents selon l'endroit</b> :
 * <ul>
 *   <li>dans le <b>corps</b> d'une requête (création/remplacement d'offre), une
 *       ancienne valeur fait échouer la désérialisation → <b>400 Bad Request</b>
 *       via {@code GlobalExceptionHandler.handleMalformedRequest} ;</li>
 *   <li>en <b>paramètre de recherche</b>, {@code JobOfferRepositoryAdapter.toEnum}
 *       rattrape l'exception et renvoie {@code null} → le filtre est simplement
 *       ignoré, la requête répond 200 avec des résultats non filtrés.</li>
 * </ul>
 */
class ExperienceLevelApiContractTest {

    private final ObjectMapper mapper = new ObjectMapper();

    private String bodyWithLevel(String level) {
        return """
            {"title":"Ingénieur Backend","city":"Tunis","country":"TN",
             "contractType":"FULL_TIME","workplaceType":"REMOTE",
             "experienceLevel":"%s","description":"desc"}""".formatted(level);
    }

    @Test
    @DisplayName("Les 4 valeurs de l'échelle CdC sont acceptées dans le corps d'une requête")
    void lesQuatreValeursDuCdcSontAcceptees() throws Exception {
        for (ExperienceLevel level : ExperienceLevel.values()) {
            CreateJobOfferRequest request =
                mapper.readValue(bodyWithLevel(level.name()), CreateJobOfferRequest.class);
            assertThat(request.experienceLevel()).isEqualTo(level);
        }
        assertThat(ExperienceLevel.values())
            .containsExactly(ExperienceLevel.JUNIOR, ExperienceLevel.SENIOR,
                             ExperienceLevel.LEAD, ExperienceLevel.MANAGER);
    }

    @Test
    @DisplayName("F31 : une ancienne valeur (MID / EXECUTIVE) dans le corps produit une 400, pas une 500")
    void anciennesValeursRejeteesDansLeCorps() {
        for (String obsolete : new String[]{"MID", "EXECUTIVE"}) {
            assertThatThrownBy(() -> mapper.readValue(bodyWithLevel(obsolete), CreateJobOfferRequest.class))
                .as("valeur obsolète %s", obsolete)
                .isInstanceOf(InvalidFormatException.class);
        }
    }

    /**
     * Le renommage n'a pas seulement changé des noms : il a déplacé la
     * pondération. Un client qui envoyait {@code SENIOR} avant F31 visait le
     * niveau que le CdC appelle « Lead » ; il vise désormais « Senior », qui
     * porte le pic du poids hard skills. Même mot, poste différent — c'est le
     * piège de migration à signaler à la squad web.
     */
    @Test
    @DisplayName("F31 : SENIOR reste une valeur valide mais ne désigne plus le même niveau")
    void seniorResteValideMaisChangeDeSens() throws Exception {
        CreateJobOfferRequest request =
            mapper.readValue(bodyWithLevel("SENIOR"), CreateJobOfferRequest.class);

        assertThat(request.experienceLevel()).isEqualTo(ExperienceLevel.SENIOR);
        // SENIOR est désormais la 2e bande (ex-MID), plus la 3e (ex-LEAD).
        assertThat(ExperienceLevel.SENIOR.ordinal()).isEqualTo(1);
        assertThat(ExperienceLevel.LEAD.ordinal()).isEqualTo(2);
    }
}
