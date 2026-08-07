package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.HardSkillTrend;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille le sens de la trajectoire.
 *
 * <p>Ce calcul existe parce que le modèle s'était trompé dessus : sur un historique
 * 50 % (récent) après 100 %, il avait annoncé « une amélioration significative » — dans les
 * deux versions du résumé, sur deux appels indépendants. Le cas de référence ci-dessous est
 * exactement celui-là.
 */
class HardSkillTrendTest {

    private static final Instant MAINTENANT = Instant.parse("2026-08-07T12:00:00Z");

    private HardSkillHistoryEntry test(int pourcentage, long heuresAvant) {
        return new HardSkillHistoryEntry(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            pourcentage, pourcentage >= 70, MAINTENANT.minus(heuresAvant, ChronoUnit.HOURS), "SENIOR");
    }

    @Test
    void unSeulTestNaPasDeTrajectoire() {
        assertThat(HardSkillTrend.of(List.of(test(80, 0)))).isEqualTo(HardSkillTrend.SINGLE);
        assertThat(HardSkillTrend.of(List.of())).isEqualTo(HardSkillTrend.SINGLE);
        assertThat(HardSkillTrend.of(null)).isEqualTo(HardSkillTrend.SINGLE);
    }

    /** Le cas réel qui a révélé le défaut : 100 % puis 50 % le même jour. */
    @Test
    void unDernierResultatPlusFaibleEstUneBaisse() {
        List<HardSkillHistoryEntry> historique = List.of(test(50, 0), test(100, 6));

        assertThat(HardSkillTrend.of(historique)).isEqualTo(HardSkillTrend.DECLINING);
    }

    @Test
    void unDernierResultatMeilleurEstUneProgression() {
        assertThat(HardSkillTrend.of(List.of(test(100, 0), test(50, 6))))
            .isEqualTo(HardSkillTrend.IMPROVING);
    }

    /** Sous le seuil, l'écart n'est pas interprétable : deux QCM différents ne se comparent pas au point près. */
    @Test
    void unEcartSousLeSeuilResteStable() {
        assertThat(HardSkillTrend.of(List.of(test(75, 0), test(70, 6))))
            .isEqualTo(HardSkillTrend.STABLE);
        assertThat(HardSkillTrend.of(List.of(test(70, 0), test(75, 6))))
            .isEqualTo(HardSkillTrend.STABLE);
    }

    @Test
    void leSeuilEstInclusif() {
        assertThat(HardSkillTrend.of(List.of(test(80, 0), test(70, 6))))
            .isEqualTo(HardSkillTrend.IMPROVING);
        assertThat(HardSkillTrend.of(List.of(test(70, 0), test(80, 6))))
            .isEqualTo(HardSkillTrend.DECLINING);
    }

    /** Seuls les deux plus récents comptent : un vieux résultat ne masque pas l'évolution actuelle. */
    @Test
    void seulsLesDeuxPlusRecentsComptent() {
        assertThat(HardSkillTrend.of(List.of(test(50, 0), test(100, 6), test(10, 100))))
            .isEqualTo(HardSkillTrend.DECLINING);
    }

    /**
     * L'énoncé transmis au modèle doit nommer la direction sans ambiguïté et rappeler quel
     * chiffre est le plus récent — c'est précisément ce qui manquait.
     */
    @Test
    void lEnonceNommeLaDirectionEtDesigneLePlusRecent() {
        String enonce = HardSkillTrend.DECLINING.asStatement(50, 100);

        assertThat(enonce).contains("DECLINING").contains("Most recent test: 50%")
            .contains("The test before it: 100%")
            .contains("never recompute or contradict");
    }

    @Test
    void lEnonceDUnSeulTestInterditDeParlerDeProgression() {
        assertThat(HardSkillTrend.SINGLE.asStatement(80, 80))
            .contains("only one test")
            .contains("Do not describe any progression or decline");
    }
}
