package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.ZennytApplication;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.CandidateJobPositionCouple;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.HardSkillLevelEstimate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * D1 — les lectures d'historique par métier, exécutées contre un vrai PostgreSQL.
 *
 * <p>Ce sont deux requêtes natives : la jointure sur {@code job_offers}, le filtre de
 * statut et le zip {@code unnest} ne sont vérifiables que par la base. Les tests unitaires
 * du calcul ({@code HardSkillLevelEstimateTest}) supposent l'historique déjà chargé — ce
 * test-ci vérifie qu'il l'est correctement.
 *
 * <p>Suit la convention du projet : base PostgreSQL jetable activée par variable
 * d'environnement, pas de Testcontainers.
 */
@SpringBootTest(classes = ZennytApplication.class)
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class HardSkillHistoryPostgresTest {

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

    @Autowired private TestResultRepository testResults;
    @Autowired private JdbcTemplate jdbc;

    private static final Instant MAINTENANT = Instant.parse("2026-08-06T12:00:00Z");

    private UUID candidat;
    private UUID autreCandidat;
    private UUID metier;
    private UUID autreMetier;
    private UUID recruteur;
    private UUID offreA;   // métier, le candidat y a passé un vieux test à 40
    private UUID offreC;   // métier, test récent à 80
    private UUID offreB;   // métier, aucun test
    private UUID offreHors; // autre métier — ne doit jamais entrer dans l'historique

    @BeforeEach
    void seed() {
        // CASCADE : test_results et les autres tables qui référencent job_offers sont vidées
        // avec elle. Les 142 métiers seedés par V26 ne sont pas touchés — seuls les métiers
        // créés ici sont retirés.
        jdbc.execute("TRUNCATE recruitment.job_offers CASCADE");
        jdbc.update("DELETE FROM recruitment.job_positions WHERE name LIKE 'ZTEST-%'");

        candidat = UUID.randomUUID();
        autreCandidat = UUID.randomUUID();
        recruteur = UUID.randomUUID();
        metier = insererMetier("ZTEST-Developpeur");
        autreMetier = insererMetier("ZTEST-Comptable");

        // Niveaux de l'échelle CdC en vigueur (V53) : JUNIOR, SENIOR, LEAD, MANAGER.
        offreA = insererOffre(metier, "JUNIOR");
        offreC = insererOffre(metier, "SENIOR");
        offreB = insererOffre(metier, "LEAD");
        offreHors = insererOffre(autreMetier, "LEAD");

        insererResultat(candidat, offreA, 40, MAINTENANT.minus(365, ChronoUnit.DAYS), "COMPLETED");
        insererResultat(candidat, offreC, 80, MAINTENANT.minus(30, ChronoUnit.DAYS), "COMPLETED");
        insererResultat(candidat, offreHors, 95, MAINTENANT.minus(10, ChronoUnit.DAYS), "COMPLETED");
        insererResultat(autreCandidat, offreA, 10, MAINTENANT.minus(5, ChronoUnit.DAYS), "COMPLETED");
    }

    private UUID insererMetier(String nom) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
            INSERT INTO recruitment.job_positions (id, name, sector, profile_type, calibrated, status, created_at)
            VALUES (?, ?, NULL, 'TECHNIQUE', false, 'APPROVED', now())
            """, id, nom);
        return id;
    }

    private UUID insererOffre(UUID jobPositionId, String niveau) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
            INSERT INTO recruitment.job_offers
                (id, recruiter_id, title, description, contract_type, workplace_type,
                 experience_level, job_position_id, open_to_international, status, posted_at, updated_at)
            VALUES (?, ?, 'Offre', 'desc', 'FULL_TIME', 'REMOTE', ?::text, ?, false, 'ACTIVE', now(), now())
            """, id, recruteur, niveau, jobPositionId);
        return id;
    }

    private void insererResultat(UUID candidateId, UUID jobOfferId, int pourcentage,
                                 Instant completedAt, String statut) {
        jdbc.update("""
            INSERT INTO recruitment.test_results
                (id, job_offer_id, hard_skill_test_id, candidate_id, score, percentage,
                 passed, answers_json, started_at, completed_at, duration, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, '[]', ?, ?, 60, ?)
            """, UUID.randomUUID(), jobOfferId, UUID.randomUUID(), candidateId,
            pourcentage, pourcentage, pourcentage >= 70,
            java.sql.Timestamp.from(completedAt), java.sql.Timestamp.from(completedAt), statut);
    }

    @Test
    void lHistoriqueRemonteLesTestsDuMetierDuPlusRecentAuPlusAncien() {
        List<HardSkillHistoryEntry> historique = testResults.findHardSkillHistory(candidat, metier);

        assertThat(historique).extracting(HardSkillHistoryEntry::percentage)
            .containsExactly(80, 40);
        assertThat(historique).allSatisfy(entry -> {
            assertThat(entry.candidateId()).isEqualTo(candidat);
            assertThat(entry.jobPositionId()).isEqualTo(metier);
        });
    }

    /** Un test d'un autre métier ne doit jamais peser sur l'estimation — c'est tout D1. */
    @Test
    void lesTestsDUnAutreMetierSontExclus() {
        List<HardSkillHistoryEntry> historique = testResults.findHardSkillHistory(candidat, metier);

        assertThat(historique).extracting(HardSkillHistoryEntry::jobOfferId)
            .doesNotContain(offreHors);
    }

    /** Le niveau de l'offre source remonte avec la ligne (D5) — affiché, jamais filtrant. */
    @Test
    void leNiveauDeLOffreSourceRemonteAvecChaqueLigne() {
        List<HardSkillHistoryEntry> historique = testResults.findHardSkillHistory(candidat, metier);

        assertThat(historique).extracting(HardSkillHistoryEntry::experienceLevel)
            .containsExactly("SENIOR", "JUNIOR");
    }

    /** D4 — un abandon n'est pas un résultat noté. Un TIMEOUT, si. */
    @Test
    void lesTentativesAbandonneesSontExcluesMaisPasLesTimeouts() {
        insererResultat(candidat, offreB, 15, MAINTENANT.minus(1, ChronoUnit.DAYS), "ABANDONED");
        assertThat(testResults.findHardSkillHistory(candidat, metier)).hasSize(2);

        jdbc.update("UPDATE recruitment.test_results SET status = 'TIMEOUT' WHERE job_offer_id = ?", offreB);
        assertThat(testResults.findHardSkillHistory(candidat, metier)).hasSize(3);
    }

    /**
     * La lecture par lot doit reconstituer exactement les mêmes historiques que la lecture
     * unitaire, sans mélanger les candidats — c'est ce que le zip {@code unnest} garantit
     * et qu'un {@code IN ... AND IN ...} aurait cassé.
     */
    @Test
    void laLectureParLotDonneLesMemesHistoriquesQueLaLectureUnitaire() {
        List<HardSkillHistoryEntry> parLot = testResults.findHardSkillHistoryByCouples(List.of(
            new CandidateJobPositionCouple(candidat, metier),
            new CandidateJobPositionCouple(autreCandidat, metier)));

        assertThat(parLot.stream().filter(e -> e.candidateId().equals(candidat)).toList())
            .containsExactlyInAnyOrderElementsOf(testResults.findHardSkillHistory(candidat, metier));
        assertThat(parLot.stream().filter(e -> e.candidateId().equals(autreCandidat)).toList())
            .containsExactlyInAnyOrderElementsOf(testResults.findHardSkillHistory(autreCandidat, metier));
        // Le couple (autreCandidat, autreMetier) n'a pas été demandé : le produit croisé
        // l'aurait remonté, le zip non.
        assertThat(parLot).noneMatch(entry -> entry.jobPositionId().equals(autreMetier));
    }

    @Test
    void unCoupleInexistantEtUneListeVideNeRemontentRien() {
        assertThat(testResults.findHardSkillHistoryByCouples(List.of(
            new CandidateJobPositionCouple(UUID.randomUUID(), UUID.randomUUID())))).isEmpty();
        assertThat(testResults.findHardSkillHistoryByCouples(List.of())).isEmpty();
        assertThat(testResults.findHardSkillHistory(candidat, UUID.randomUUID())).isEmpty();
    }

    /**
     * Le scénario complet de D3 sur données réelles : le mauvais test propre à l'offre A
     * lui reste attaché (53), tandis qu'une offre B du même métier bénéficie du test récent
     * (67). C'est la démonstration bout en bout de la lecture et du calcul combinés.
     */
    @Test
    void leScenarioDeReferenceDonne53SurLOffreTesteeEt67SurLaSoeur() {
        List<HardSkillHistoryEntry> historique = testResults.findHardSkillHistory(candidat, metier);

        assertThat(HardSkillLevelEstimate.estimate(historique, offreA)).isEqualTo(53);
        assertThat(HardSkillLevelEstimate.estimate(historique, offreB)).isEqualTo(67);
        assertThat(HardSkillLevelEstimate.estimate(historique, offreC)).isEqualTo(67);
    }
}
