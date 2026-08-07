package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.ZennytApplication;
import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository;
import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository.QueuedPair;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;
import static com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository.PRIORITY_NORMAL;
import static com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository.PRIORITY_URGENT;

/**
 * T3.1 à T3.10 — la file de travail sur base réelle.
 *
 * <p>Trois comportements ne peuvent pas être vérifiés autrement qu'avec un vrai PostgreSQL :
 * la déduplication par index unique partiel, la réservation concurrente par
 * {@code SKIP LOCKED}, et le backoff exponentiel calculé en SQL.
 */
@SpringBootTest(classes = ZennytApplication.class)
@EnabledIfEnvironmentVariable(named = "ZENNYT_TEST_POSTGRES_URL", matches = "jdbc:postgresql:.*")
class FitScoreWorkQueuePostgresTest {

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

    @Autowired private FitScoreWorkQueueRepository queue;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private PlatformTransactionManager txManager;

    @BeforeEach
    void viderLaFile() {
        jdbc.update("DELETE FROM recruitment.fitscore_work_queue");
    }

    private CandidateOfferPair paire() {
        return new CandidateOfferPair(UUID.randomUUID(), UUID.randomUUID());
    }

    @Test
    void t3_1_enfilerDeuxFoisLaMemePaireNeCreeQuUneLigne() {
        CandidateOfferPair p = paire();

        int premier = queue.enqueue(List.of(p), PRIORITY_URGENT);
        int second = queue.enqueue(List.of(p), PRIORITY_URGENT);

        assertThat(premier).isEqualTo(1);
        assertThat(second).as("déjà en attente : ignorée silencieusement").isZero();
        assertThat(queue.depth(PRIORITY_URGENT)).isEqualTo(1);
    }

    @Test
    void t3_3_lesUrgentesPassentAvantLesNormales() {
        List<CandidateOfferPair> normales = List.of(paire(), paire(), paire());
        queue.enqueue(normales, PRIORITY_NORMAL);
        CandidateOfferPair urgente = paire();
        queue.enqueue(List.of(urgente), PRIORITY_URGENT);

        List<QueuedPair> reservees = queue.claim(1);

        assertThat(reservees).hasSize(1);
        assertThat(reservees.get(0).pair()).isEqualTo(urgente);
    }

    @Test
    void t3_2_deuxWorkersNeTraitentJamaisLaMemeLigne() throws Exception {
        List<CandidateOfferPair> paires = new ArrayList<>();
        for (int i = 0; i < 100; i++) paires.add(paire());
        queue.enqueue(paires, PRIORITY_NORMAL);

        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            CountDownLatch depart = new CountDownLatch(1);
            // Les deux transactions doivent être ouvertes EN MÊME TEMPS, sinon le test ne
            // prouve rien : les verrous ne durent que le temps de la transaction, et un
            // worker qui commit avant que l'autre ne commence lui laisse voir les mêmes
            // lignes, toujours en attente. C'est exactement ce que fait le worker réel —
            // il garde sa transaction ouverte pendant tout le traitement de la tranche.
            CountDownLatch reserveesDesDeuxCotes = new CountDownLatch(2);
            List<Future<List<Long>>> futurs = new ArrayList<>();
            for (int i = 0; i < 2; i++) {
                futurs.add(pool.submit(() -> {
                    depart.await();
                    TransactionTemplate tx = new TransactionTemplate(txManager);
                    return tx.execute(status -> {
                        List<Long> ids = queue.claim(50).stream().map(QueuedPair::id).toList();
                        reserveesDesDeuxCotes.countDown();
                        try {
                            // Maintient la transaction ouverte le temps que l'autre réserve.
                            reserveesDesDeuxCotes.await(30, TimeUnit.SECONDS);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                        return ids;
                    });
                }));
            }
            depart.countDown();
            List<Long> tous = new ArrayList<>();
            for (Future<List<Long>> f : futurs) tous.addAll(f.get(60, TimeUnit.SECONDS));

            assertThat(tous).as("aucune ligne réservée deux fois").doesNotHaveDuplicates();
            assertThat(tous).as("les 100 lignes réparties entre les deux workers").hasSize(100);
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void t3_6_echecsRepetesFinissentEnFailedAvecBackoff() {
        CandidateOfferPair p = paire();
        queue.enqueue(List.of(p), PRIORITY_URGENT);
        long id = queue.claim(1).get(0).id();

        for (int essai = 1; essai <= 3; essai++) {
            queue.fail(id, "panne simulée " + essai, 3);
        }

        Integer attempts = jdbc.queryForObject(
            "SELECT attempts FROM recruitment.fitscore_work_queue WHERE id = ?", Integer.class, id);
        String status = jdbc.queryForObject(
            "SELECT status FROM recruitment.fitscore_work_queue WHERE id = ?", String.class, id);
        String erreur = jdbc.queryForObject(
            "SELECT last_error FROM recruitment.fitscore_work_queue WHERE id = ?", String.class, id);

        assertThat(attempts).isEqualTo(3);
        assertThat(status).isEqualTo("FAILED");
        assertThat(erreur).contains("panne simulée 3");
        assertThat(queue.failedCount()).isEqualTo(1);
        // Abandonnée par la file, mais pas perdue : le calcul à l'affichage la reprendra.
        assertThat(queue.depth(PRIORITY_URGENT)).isZero();
    }

    @Test
    void unePaireEnAttenteDeReessaiNestPasReserveeAvantLHeure() {
        CandidateOfferPair p = paire();
        queue.enqueue(List.of(p), PRIORITY_URGENT);
        long id = queue.claim(1).get(0).id();
        queue.fail(id, "première panne", 5);   // programme next_retry_at dans le futur

        assertThat(queue.claim(10)).as("le backoff doit être respecté").isEmpty();
    }

    @Test
    void t3_9_fileVideNeCouteRien() {
        assertThat(queue.claim(200)).isEmpty();
        assertThat(queue.depth(PRIORITY_URGENT)).isZero();
        assertThat(queue.depth(PRIORITY_NORMAL)).isZero();
        assertThat(queue.oldestPendingAgeSeconds()).isZero();
    }

    @Test
    void completeRetireLesLignesDeLaFile() {
        List<CandidateOfferPair> paires = List.of(paire(), paire());
        queue.enqueue(paires, PRIORITY_NORMAL);
        List<Long> ids = queue.claim(10).stream().map(QueuedPair::id).toList();

        queue.complete(ids);

        assertThat(queue.depth(PRIORITY_NORMAL)).isZero();
        assertThat(queue.claim(10)).isEmpty();
    }

    @Test
    void unePaireTraiteePeutEtreReenfileePlusTard() {
        CandidateOfferPair p = paire();
        queue.enqueue(List.of(p), PRIORITY_NORMAL);
        queue.complete(queue.claim(1).stream().map(QueuedPair::id).toList());

        // L'index unique est partiel (status = PENDING) : une paire terminée peut revenir.
        int reenfilee = queue.enqueue(List.of(p), PRIORITY_URGENT);

        assertThat(reenfilee).isEqualTo(1);
        assertThat(queue.depth(PRIORITY_URGENT)).isEqualTo(1);
    }

    @Test
    void lAgeDeLaPlusAncienneEstMesure() {
        queue.enqueue(List.of(paire()), PRIORITY_NORMAL);

        assertThat(queue.oldestPendingAgeSeconds()).isGreaterThanOrEqualTo(0);
        assertThat(queue.depth(PRIORITY_NORMAL)).isEqualTo(1);
    }
}
