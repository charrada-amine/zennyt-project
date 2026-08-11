package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.ZennytApplication;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.HardSkillsAlertLevel;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * F32 / décision D-C — le mode de mesure du hard skills appartient au métier.
 *
 * <p>Ne peut se vérifier que sur une vraie base : c'est la migration V60 qui porte
 * l'intention, en reprenant les 142 métiers seedés. Le CdC §4.3 nomme explicitement
 * UX/UI Designer et Motion designer comme hybrides (Mixte) et Photographe, Illustrateur,
 * Compositeur, Scénariste, Directeur artistique comme Portfolio — <b>tous ARTISTIQUE</b>.
 * Tant que le champ vivait sur {@code job_role_profile} (profil × niveau), cette
 * distinction était littéralement inexprimable : ils partageaient forcément le même mode.
 */
@SpringBootTest(classes = ZennytApplication.class)
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class TypeEvaluationHardByPositionPostgresTest {

    @DynamicPropertySource
    static void postgres(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> System.getenv("ZENNYT_TEST_POSTGRES_URL"));
        registry.add("spring.datasource.username", () -> env("ZENNYT_TEST_POSTGRES_USER", "postgres"));
        registry.add("spring.datasource.password", () -> env("ZENNYT_TEST_POSTGRES_PASSWORD", "postgres"));
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }

    @Autowired private JobPositionRepository positions;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private JobRoleProfileRepository roleProfiles;

    @Test
    @DisplayName("Deux métiers ARTISTIQUE peuvent avoir des modes différents")
    void deuxMetiersArtistiquesModesDifferents() {
        assertThat(modeDe("UX/UI Designer")).isEqualTo("MIXTE");
        assertThat(modeDe("Photographe")).isEqualTo("PORTFOLIO");
        // Le point de la tâche : même famille, modes différents. Impossible avant V60.
        assertThat(profilDe("UX/UI Designer")).isEqualTo(profilDe("Photographe")).isEqualTo("ARTISTIQUE");
    }

    @Test
    @DisplayName("Les métiers hybrides nommés par le CdC §4.3 sont en Mixte, les autres créatifs en Portfolio")
    void reprisesDeLaMigrationConformesAuCdc() {
        assertThat(metiersEnMode("MIXTE"))
            .containsExactlyInAnyOrder("UX/UI Designer", "UX/UI e-commerce", "Motion designer");

        assertThat(metiersEnMode("PORTFOLIO"))
            .contains("Photographe", "Illustrateur / Concept artist", "Compositeur / Sound designer",
                "Scénariste", "Directeur artistique", "Graphiste / Designer")
            .doesNotContain("UX/UI Designer", "Motion designer");
    }

    @Test
    @DisplayName("Les métiers non créatifs restent en QCM")
    void metiersNonCreatifsEnQcm() {
        assertThat(modeDe("Développeur")).isEqualTo("QCM");
        assertThat(modeDe("Infirmier")).isEqualTo("QCM");
        assertThat(jdbc.queryForObject("""
            SELECT count(*) FROM recruitment.job_positions
            WHERE profile_type <> 'ARTISTIQUE' AND type_evaluation_hard <> 'QCM'
            """, Integer.class)).isZero();
    }

    /**
     * Le domaine doit relire ce que la migration a écrit — un champ correct en base mais
     * perdu au mapping ne servirait à rien.
     */
    @Test
    @DisplayName("Le mode remonte jusqu'au domaine, pas seulement en base")
    void leModeRemonteJusquAuDomaine() {
        var photographe = positions
            .findByStatus(JobPositionStatus.APPROVED, null).stream()
            .filter(p -> "Photographe".equals(p.name()))
            .findFirst();

        assertThat(photographe).isPresent();
        assertThat(photographe.get().typeEvaluationHard()).isEqualTo(TypeEvaluationHard.PORTFOLIO);
    }

    /**
     * Boucle fermée : le mode lu en base décide bien de l'alerte hard skills.
     *
     * <p>Les tests unitaires prouvent que {@code hardSkillsAlert} obéit au mode ; celui-ci
     * prouve que le mode qui lui parvient est celui du vrai métier seedé. Sans ce maillon,
     * la correction pourrait être juste et inopérante — c'est exactement ce qui s'était
     * passé : la logique était correcte pour ARTISTIQUE, mais elle lisait la famille au
     * lieu du métier, et les trois hybrides passaient à travers.
     */
    @Test
    @DisplayName("Un métier hybride réclame bien un QCM, un métier portfolio non")
    void lAlerteSuitLeModeDuMetierSeede() {
        var artistiqueSenior = roleProfiles
            .findByProfileTypeAndLevel(JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR)
            .orElseThrow();

        // Photographe : le portfolio EST l'évaluation, aucun test ne manque.
        assertThat(artistiqueSenior.hardSkillsAlert(modeDomaineDe("Photographe")))
            .isEqualTo(HardSkillsAlertLevel.PORTFOLIO_BASED);

        // UX/UI Designer : même profil, même ligne de pondération, mais un QCM est attendu.
        assertThat(artistiqueSenior.hardSkillsAlert(modeDomaineDe("UX/UI Designer")))
            .isEqualTo(HardSkillsAlertLevel.STRONG);
    }

    private TypeEvaluationHard modeDomaineDe(String metier) {
        return positions.findByStatus(JobPositionStatus.APPROVED, null).stream()
            .filter(p -> metier.equals(p.name()))
            .findFirst().orElseThrow()
            .typeEvaluationHard();
    }

    private String modeDe(String metier) {
        return jdbc.queryForObject(
            "SELECT type_evaluation_hard FROM recruitment.job_positions WHERE name = ?",
            String.class, metier);
    }

    private String profilDe(String metier) {
        return jdbc.queryForObject(
            "SELECT profile_type FROM recruitment.job_positions WHERE name = ?", String.class, metier);
    }

    private List<String> metiersEnMode(String mode) {
        return jdbc.queryForList(
            "SELECT name FROM recruitment.job_positions WHERE type_evaluation_hard = ?",
            String.class, mode);
    }
}
