package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.HardSkillLevelEstimate;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le cœur de D2/D3 — testable sans base ni Spring, ce qui est précisément la raison
 * d'être de l'objet de valeur.
 */
class HardSkillLevelEstimateTest {

    private static final UUID CANDIDAT = UUID.randomUUID();
    private static final UUID METIER = UUID.randomUUID();
    private static final Instant MAINTENANT = Instant.parse("2026-08-06T12:00:00Z");

    private HardSkillHistoryEntry test(UUID offre, int pourcentage, long joursAvant) {
        return new HardSkillHistoryEntry(CANDIDAT, METIER, offre, pourcentage, pourcentage >= 70,
            MAINTENANT.minus(joursAvant, ChronoUnit.DAYS), "SENIOR");
    }

    @Test
    void unHistoriqueVideNeProduitAucuneEstimation() {
        assertThat(HardSkillLevelEstimate.estimate(List.of(), UUID.randomUUID())).isNull();
        assertThat(HardSkillLevelEstimate.estimate(null, UUID.randomUUID())).isNull();
    }

    /**
     * Non-régression stricte : avec un seul test, l'estimation vaut exactement le
     * pourcentage — c'est-à-dire le comportement d'avant D1.
     */
    @Test
    void unSeulTestDonneExactementSonPourcentage() {
        UUID offre = UUID.randomUUID();
        assertThat(HardSkillLevelEstimate.estimate(List.of(test(offre, 72, 0)), offre)).isEqualTo(72);
    }

    /** L'exemple de référence de la décision D2 : 80 / 65 / 40 donnent 70. */
    @Test
    void troisTestsDonnentLaMoyennePondereeParRang() {
        UUID offre = UUID.randomUUID();
        List<HardSkillHistoryEntry> historique = List.of(
            test(offre, 80, 30),
            test(UUID.randomUUID(), 65, 180),
            test(UUID.randomUUID(), 40, 365));

        // (80x1 + 65x0,5 + 40x0,25) / 1,75 = 122,5 / 1,75 = 70
        assertThat(HardSkillLevelEstimate.estimate(historique, offre)).isEqualTo(70);
    }

    /**
     * D3 — les deux moitiés de l'exemple du plan. Le mauvais test propre à l'offre A lui
     * reste attaché (53) ; vu depuis une offre B du même métier, c'est le test récent qui
     * mène (67). C'est ce qui empêche d'effacer un mauvais résultat en testant ailleurs,
     * et ce qui conserve une différenciation entre offres d'un même métier.
     */
    @Test
    void leTestDeLOffreConsulteePasseAuRang1MemeSilEstPlusAncien() {
        UUID offreA = UUID.randomUUID();
        UUID offreC = UUID.randomUUID();
        UUID offreB = UUID.randomUUID();
        List<HardSkillHistoryEntry> historique = List.of(
            test(offreC, 80, 30),
            test(offreA, 40, 365));

        assertThat(HardSkillLevelEstimate.estimate(historique, offreA)).isEqualTo(53);
        assertThat(HardSkillLevelEstimate.estimate(historique, offreB)).isEqualTo(67);
    }

    /** Sans offre de référence (cas du résumé, qui est par métier), l'ordre est purement chronologique. */
    @Test
    void sansOffreDeReferenceLOrdreEstChronologique() {
        List<HardSkillHistoryEntry> historique = List.of(
            test(UUID.randomUUID(), 80, 30),
            test(UUID.randomUUID(), 40, 365));

        assertThat(HardSkillLevelEstimate.estimate(historique, null)).isEqualTo(67);
    }

    /** L'ordre d'arrivée des lignes ne doit rien changer : c'est le comparateur qui décide du rang. */
    @Test
    void leResultatNeDependPasDeLOrdreDeLaListeFournie() {
        UUID offre = UUID.randomUUID();
        List<HardSkillHistoryEntry> historique = new ArrayList<>(List.of(
            test(offre, 80, 30),
            test(UUID.randomUUID(), 65, 180),
            test(UUID.randomUUID(), 40, 365)));
        Collections.reverse(historique);

        assertThat(HardSkillLevelEstimate.estimate(historique, offre)).isEqualTo(70);
    }

    /**
     * La propriété qui rend l'agrégation défendable : la somme des poids du passé reste
     * strictement inférieure au poids du rang 1, donc le plus récent en détient toujours
     * plus de la moitié. Cas limite : 30 tests à 0 ne peuvent pas tirer un 100 récent
     * <b>en dessous</b> de 50. Une moyenne simple, elle, l'aurait fait tomber à 3.
     */
    @Test
    void toutLePasseReuniNePeutPasPeserPlusQueLePlusRecent() {
        UUID offre = UUID.randomUUID();
        List<HardSkillHistoryEntry> historique = new ArrayList<>();
        historique.add(test(offre, 100, 0));
        for (int i = 1; i <= 30; i++) {
            historique.add(test(UUID.randomUUID(), 0, i * 10L));
        }

        assertThat(HardSkillLevelEstimate.estimate(historique, offre)).isEqualTo(50);
    }

    /**
     * Non gamable : ajouter un test moins bon que sa moyenne pondérée la fait baisser.
     * Une agrégation par le maximum, elle, aurait laissé le score inchangé.
     */
    @Test
    void unMauvaisTestSupplementaireFaitBaisserLEstimation() {
        UUID offre = UUID.randomUUID();
        List<HardSkillHistoryEntry> avant = List.of(test(offre, 80, 30));
        List<HardSkillHistoryEntry> apres = List.of(test(offre, 30, 0), test(offre, 80, 30));

        Integer estimationAvant = HardSkillLevelEstimate.estimate(avant, offre);
        Integer estimationApres = HardSkillLevelEstimate.estimate(apres, offre);

        assertThat(estimationApres).isLessThan(estimationAvant);
    }

    /** Deux tests soumis à la même milliseconde doivent donner un ordre stable, pas aléatoire. */
    @Test
    void lesEgalitesDHorodatageSontDepartageesDeFaconDeterministe() {
        UUID offreA = UUID.fromString("00000000-0000-0000-0000-0000000000aa");
        UUID offreB = UUID.fromString("00000000-0000-0000-0000-0000000000bb");
        List<HardSkillHistoryEntry> ordre1 = List.of(test(offreA, 100, 5), test(offreB, 0, 5));
        List<HardSkillHistoryEntry> ordre2 = List.of(test(offreB, 0, 5), test(offreA, 100, 5));

        assertThat(HardSkillLevelEstimate.estimate(ordre1, null))
            .isEqualTo(HardSkillLevelEstimate.estimate(ordre2, null));
    }
}
