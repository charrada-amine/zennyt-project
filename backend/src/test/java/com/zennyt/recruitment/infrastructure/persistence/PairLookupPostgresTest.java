package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.ZennytApplication;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * T0.3 / T0.4 — les lectures par lot doivent cibler les paires demandées, jamais leur
 * produit croisé.
 *
 * <p>Le test construit une grille complète (chaque candidat a une ligne pour chaque offre)
 * puis n'en demande que la <b>diagonale</b>. Avec l'ancienne requête
 * ({@code candidate_id IN (...) AND job_offer_id IN (...)}), demander N paires réparties
 * sur N candidats et N offres remontait les N² lignes de la grille. C'est exactement ce
 * que ce test rend impossible de réintroduire sans être vu.
 *
 * <p>Suit la convention du projet pour les tests sur base réelle
 * ({@code EngagementPostgresConcurrencyTest}) : activé par variable d'environnement contre
 * une base PostgreSQL jetable, plutôt que par Testcontainers — le projet n'en dépend pas.
 */
@SpringBootTest(classes = ZennytApplication.class)
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class PairLookupPostgresTest {

    /** Côté de la grille : 20 × 20 = 400 lignes posées, 20 seulement demandées. */
    private static final int GRID = 20;

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
    @Autowired private FitScoreRepository fitScores;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidates = new ArrayList<>();
    private final List<UUID> offers = new ArrayList<>();

    @BeforeEach
    void seedGrid() {
        jdbc.update("DELETE FROM recruitment.test_results");
        jdbc.update("DELETE FROM recruitment.fit_scores");
        candidates.clear();
        offers.clear();
        for (int i = 0; i < GRID; i++) {
            candidates.add(UUID.randomUUID());
            offers.add(UUID.randomUUID());
        }
        Instant now = Instant.now();
        for (UUID candidate : candidates) {
            for (UUID offer : offers) {
                jdbc.update("""
                    INSERT INTO recruitment.test_results
                        (id, job_offer_id, hard_skill_test_id, candidate_id, score, percentage,
                         passed, answers_json, started_at, completed_at, duration, status)
                    VALUES (?, ?, ?, ?, 10, 70, true, '[]', ?, ?, 60, 'COMPLETED')
                    """, UUID.randomUUID(), offer, UUID.randomUUID(), candidate,
                    java.sql.Timestamp.from(now), java.sql.Timestamp.from(now));
                jdbc.update("""
                    INSERT INTO recruitment.fit_scores
                        (id, candidate_id, job_offer_id, score, soft_skill_score,
                         hard_skill_score, coverage_ratio, computed_at)
                    VALUES (?, ?, ?, 50, 50, NULL, 100, ?)
                    """, UUID.randomUUID(), candidate, offer, java.sql.Timestamp.from(now));
            }
        }
    }

    /** La diagonale : GRID paires, réparties sur GRID candidats et GRID offres. */
    private List<CandidateOfferPair> diagonale() {
        List<CandidateOfferPair> pairs = new ArrayList<>();
        for (int i = 0; i < GRID; i++) {
            pairs.add(new CandidateOfferPair(candidates.get(i), offers.get(i)));
        }
        return pairs;
    }

    @Test
    void lesResultatsDeTestNeRemontentQueLesPairesDemandees() {
        List<CandidateOfferPair> demandees = diagonale();

        var lus = testResults.findByPairs(demandees);

        // Avec le produit croisé, on aurait obtenu GRID² = 400 lignes.
        assertThat(lus).as("lignes lues").hasSize(GRID);
        assertThat(lus).allSatisfy(result ->
            assertThat(demandees).contains(
                new CandidateOfferPair(result.candidateId(), result.jobOfferId())));
    }

    @Test
    void lesFitScoresNeRemontentQueLesPairesDemandees() {
        List<CandidateOfferPair> demandees = diagonale();

        var lus = fitScores.findByPairs(demandees);

        assertThat(lus).as("lignes lues").hasSize(GRID);
        assertThat(lus).allSatisfy(score ->
            assertThat(demandees).contains(
                new CandidateOfferPair(score.candidateId(), score.jobOfferId())));
    }

    @Test
    void unePaireInexistanteNeRemonteRien() {
        var lus = testResults.findByPairs(List.of(
            new CandidateOfferPair(UUID.randomUUID(), UUID.randomUUID())));

        assertThat(lus).isEmpty();
    }

    @Test
    void listeVideNeDeclencheAucuneRequete() {
        assertThat(testResults.findByPairs(List.of())).isEmpty();
        assertThat(fitScores.findByPairs(List.of())).isEmpty();
    }
}
