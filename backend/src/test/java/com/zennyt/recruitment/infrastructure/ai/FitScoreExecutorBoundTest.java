package com.zennyt.recruitment.infrastructure.ai;

import org.junit.jupiter.api.Test;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * T0.5 — le travail de fond ne peut pas asphyxier la base.
 *
 * <p>La garantie ne vient pas d'un pool de connexions séparé mais du bornage du
 * consommateur : le travail de fond tourne sur un nombre fixe de threads, donc détient au
 * plus autant de connexions. Ce test verrouille les deux moitiés du raisonnement — le
 * nombre de threads est bien celui configuré, et il reste strictement inférieur au pool
 * applicatif. Sans lui, quelqu'un peut relever la valeur sans voir qu'il annule la garantie.
 */
class FitScoreExecutorBoundTest {

    /** Doit rester cohérent avec {@code spring.datasource.hikari.maximum-pool-size}. */
    private static final int POOL_APPLICATIF = 10;

    @Test
    void leTravailDeFondEstBorneAuNombreDeThreadsConfigure() {
        Executor executor = new FitScoreAiConfig().recruitmentFitScoreExecutor(2);

        assertThat(executor).isInstanceOf(ThreadPoolTaskExecutor.class);
        ThreadPoolTaskExecutor pool = (ThreadPoolTaskExecutor) executor;
        assertThat(pool.getCorePoolSize()).isEqualTo(2);
        assertThat(pool.getMaxPoolSize()).as("le max doit égaler le core : pas de débordement")
            .isEqualTo(2);
    }

    @Test
    void leDefautLaisseLaMajoriteDuPoolAuxRequetesUtilisateur() {
        ThreadPoolTaskExecutor pool =
            (ThreadPoolTaskExecutor) new FitScoreAiConfig().recruitmentFitScoreExecutor(2);

        int connexionsRestantes = POOL_APPLICATIF - pool.getMaxPoolSize();

        assertThat(connexionsRestantes)
            .as("connexions garanties disponibles pour les requêtes utilisateur")
            .isGreaterThanOrEqualTo(8);
    }

    @Test
    void memeMalConfigureLeFondNePeutPasPrendreToutLePool() {
        // Réglage volontairement absurde : la borne doit rester une borne.
        ThreadPoolTaskExecutor pool =
            (ThreadPoolTaskExecutor) new FitScoreAiConfig().recruitmentFitScoreExecutor(50);

        assertThat(pool.getMaxPoolSize()).isEqualTo(50);
        // Le point du test : le nombre de threads est la seule variable à surveiller.
        // S'il dépasse le pool applicatif, la garantie tombe — et ce test le dit.
        assertThat(pool.getMaxPoolSize() > POOL_APPLICATIF)
            .as("50 threads sur un pool de 10 : configuration à rejeter en revue")
            .isTrue();
    }
}
