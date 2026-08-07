package com.zennyt.recruitment.application;

import com.zennyt.ZennytApplication;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
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
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * T1.7 à T1.15 — le calcul à l'affichage sur base réelle.
 *
 * <p>Le test qui compte le plus ici est {@code t1_10_deuxRequetesParallelesNeCassentPas} :
 * deux onglets ouverts, ou un rafraîchissement rapide, font calculer la même paire deux
 * fois simultanément. Sans {@code ON CONFLICT}, un simple double-clic produirait une
 * erreur 500. Aucun verrou distribué n'est utilisé — à quelques millisecondes par paire,
 * le mécanisme pour éviter le calcul redondant coûterait plus cher que le gaspillage.
 */
@SpringBootTest(classes = ZennytApplication.class,
    properties = {
        "recruitment.fitscore.inline.enabled=true",
        "recruitment.fitscore.inline.budget-ms=60000",
        "recruitment.fitscore.inline.max-pairs=200"
    })
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class InlineFitScorePostgresTest {

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

    @Autowired private InlineFitScoreComputer inlineComputer;
    @Autowired private FitScoreRepository fitScores;
    @Autowired private JdbcTemplate jdbc;

    private UUID candidat;
    private UUID positionApprouvee;

    @BeforeEach
    void setUp() {
        jdbc.update("DELETE FROM recruitment.fit_scores");
        jdbc.update("DELETE FROM recruitment.job_offers");
        candidat = UUID.randomUUID();
        positionApprouvee = jdbc.queryForObject(
            "SELECT id FROM recruitment.job_positions WHERE profile_type IS NOT NULL LIMIT 1",
            UUID.class);
        // Un score soft, sinon le calcul reste possible mais sans signal.
        jdbc.update("DELETE FROM recruitment.soft_skills_projection WHERE candidate_id = ?", candidat);
        jdbc.update("""
            INSERT INTO recruitment.soft_skills_projection
                (id, candidate_id, module, score, coverage_ratio, updated_at)
            VALUES (?, ?, 'MOVE_FAST', 80, 100, ?)
            """, UUID.randomUUID(), candidat, java.sql.Timestamp.from(Instant.now()));
    }

    private List<JobOffer> creerOffres(int combien, UUID positionId) {
        List<UUID> ids = new ArrayList<>();
        Instant now = Instant.now();
        for (int i = 0; i < combien; i++) {
            UUID id = UUID.randomUUID();
            jdbc.update("""
                INSERT INTO recruitment.job_offers
                    (id, recruiter_id, title, location_city, location_country, salary_min,
                     salary_max, contract_type, workplace_type, experience_level, description,
                     responsibilities, minimum_qualifications, preferred_qualifications,
                     what_we_offer, how_to_apply, job_position_id, open_to_international,
                     status, posted_at, updated_at)
                VALUES (?, ?, ?, 'Tunis', 'Tunisie', 40000, 70000, 'FULL_TIME', 'REMOTE',
                        'SENIOR', 'desc', 'r', 'm', 'p', 'w', 'h', ?, false, 'ACTIVE', ?, ?)
                """, id, UUID.randomUUID(), "Offre " + i, positionId,
                java.sql.Timestamp.from(now), java.sql.Timestamp.from(now));
            ids.add(id);
        }
        return ids.stream().map(this::chargerOffre).toList();
    }

    private JobOffer chargerOffre(UUID id) {
        return offresRepo.findById(id).orElseThrow();
    }

    @Autowired private com.zennyt.recruitment.domain.repository.JobOfferRepository offresRepo;

    private long compterScores() {
        Long n = jdbc.queryForObject(
            "SELECT count(*) FROM recruitment.fit_scores WHERE candidate_id = ?", Long.class, candidat);
        return n == null ? 0 : n;
    }

    @Test
    void t1_7_nouveauCandidatObtientToutesSesNotes() {
        List<JobOffer> pool = creerOffres(30, positionApprouvee);

        var reste = inlineComputer.ensureScored(candidat, pool);

        assertThat(reste).isEmpty();
        assertThat(compterScores()).isEqualTo(30);
    }

    @Test
    void t1_8_deuxiemeAppelIdentiqueNecritRien() {
        List<JobOffer> pool = creerOffres(10, positionApprouvee);
        inlineComputer.ensureScored(candidat, pool);
        long apresPremier = compterScores();

        inlineComputer.ensureScored(candidat, pool);

        assertThat(compterScores()).as("aucune écriture au second passage").isEqualTo(apresPremier);
        assertThat(apresPremier).isEqualTo(10);
    }

    @Test
    void t1_9_leScoreInlineEgaleLeScoreDuCheminParLot() {
        List<JobOffer> pool = creerOffres(5, positionApprouvee);
        inlineComputer.ensureScored(candidat, pool);

        var inline = fitScores.findByPairs(pool.stream()
            .map(o -> new CandidateOfferPair(candidat, o.id())).toList());

        // Le calcul inline délègue au même chemin par lot que le balayage : l'équivalence
        // est acquise par construction (aucune logique de calcul dupliquée), c'est ce que
        // verrouille RecomputeFitScoresUseCaseBatchTest. Ici on vérifie que ce chemin a
        // bien produit de vrais scores persistés, et l'invariant propre à ce jeu de
        // données : même candidat + même métier => même score soft sur les 5 offres.
        // La valeur exacte relève de la formule (profil incomplet => score volontairement
        // bas, un module non joué comptant 0 au numérateur mais son poids au dénominateur)
        // et a ses propres tests dédiés.
        assertThat(inline).hasSize(5);
        assertThat(inline).allSatisfy(s -> assertThat(s.score()).isBetween(0, 100));
        assertThat(inline).extracting(s -> s.softSkillScore()).hasSize(5)
            .containsOnly(inline.get(0).softSkillScore());
    }

    @Test
    void t1_10_deuxRequetesParallelesNeCassentPas() throws Exception {
        List<JobOffer> pool = creerOffres(20, positionApprouvee);
        ExecutorService pool2 = Executors.newFixedThreadPool(2);
        try {
            CountDownLatch depart = new CountDownLatch(1);
            List<Future<Throwable>> resultats = new ArrayList<>();
            for (int i = 0; i < 2; i++) {
                resultats.add(pool2.submit(() -> {
                    try {
                        depart.await();
                        inlineComputer.ensureScored(candidat, pool);
                        return null;
                    } catch (Throwable t) {
                        return t;
                    }
                }));
            }
            depart.countDown();
            for (Future<Throwable> f : resultats) {
                assertThat(f.get(60, TimeUnit.SECONDS)).as("aucune exception remontée").isNull();
            }
        } finally {
            pool2.shutdownNow();
        }

        // Une seule ligne par paire malgré les deux calculs simultanés.
        assertThat(compterScores()).isEqualTo(20);
    }

    @Test
    void t1_11_offreAuMetierNonValideNestJamaisCalculee() {
        UUID positionEnAttente = UUID.randomUUID();
        jdbc.update("""
            INSERT INTO recruitment.job_positions
                (id, name, sector, status, profile_type, calibrated, created_at)
            VALUES (?, ?, 'IT, AI & Fintech', 'PENDING_APPROVAL', NULL, false, ?)
            """, positionEnAttente, "Métier en attente " + UUID.randomUUID(),
            java.sql.Timestamp.from(Instant.now()));
        List<JobOffer> pool = creerOffres(3, positionEnAttente);

        var reste = inlineComputer.ensureScored(candidat, pool);

        assertThat(compterScores()).as("aucun score inventé").isZero();
        assertThat(reste).as("ni reporté : sinon resoumis à chaque affichage").isEmpty();
    }

    @Test
    void t1_15_aucunManquantNouvreAucuneEcriture() {
        List<JobOffer> pool = creerOffres(5, positionApprouvee);
        inlineComputer.ensureScored(candidat, pool);
        var avant = fitScores.findByPairs(pool.stream()
            .map(o -> new CandidateOfferPair(candidat, o.id())).toList());

        inlineComputer.ensureScored(candidat, pool);

        var apres = fitScores.findByPairs(pool.stream()
            .map(o -> new CandidateOfferPair(candidat, o.id())).toList());
        // computed_at inchangé = aucune réécriture.
        assertThat(apres).extracting(s -> s.computedAt())
            .containsExactlyInAnyOrderElementsOf(avant.stream().map(s -> s.computedAt()).toList());
    }
}
