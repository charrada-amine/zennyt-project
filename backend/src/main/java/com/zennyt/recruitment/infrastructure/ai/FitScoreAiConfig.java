package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
public class FitScoreAiConfig {
    /**
     * D3 (PLAN_FITSCORE_V3.md) — formule déterministe, désormais <b>seul</b> moteur.
     *
     * <p>Le repli sur un moteur IA externe (Groq, ou un stub sans clé) a été supprimé :
     * il calculait certaines paires selon une logique entièrement différente, sans que
     * ce soit visible, et ~12× plus lentement. Une offre sans métier approuvé n'a
     * simplement pas de score tant que l'admin ne l'a pas validé.
     *
     * <p>Groq reste utilisé ailleurs dans le contexte (génération de QCM, résumé de CV
     * candidat) — seul le calcul du Fit Score est concerné.
     */
    @Bean
    FitScoreCalculatorPort fitScoreCalculator() {
        return new DeterministicFitScoreCalculator();
    }

    /**
     * Borne stricte du travail de fond sur la base de données.
     *
     * <p>Le plan demandait un <i>pool de connexions dédié</i> au travail de fond. Ici c'est
     * le <b>consommateur</b> qui est borné plutôt que la ressource partitionnée, et la
     * garantie obtenue est la même : un travail de fond qui ne peut jamais tourner sur plus
     * de N threads ne peut jamais détenir plus de N connexions, quels que soient les autres
     * réglages. Sur un pool applicatif de 10, il en reste donc toujours au moins 8 pour les
     * requêtes utilisateur.
     *
     * <p>Partitionner réellement le pool imposerait un second {@code EntityManagerFactory}
     * et un second gestionnaire de transactions, donc de dupliquer toute la couche de
     * persistance — les mêmes repositories servent le chemin requête et le chemin de fond.
     * Coût structurel élevé pour une garantie identique : écarté volontairement.
     */
    @Bean(name = "recruitmentFitScoreExecutor")
    Executor recruitmentFitScoreExecutor(
            @Value("${recruitment.fitscore.db-pool-size:2}") int poolSize) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(poolSize);
        executor.setMaxPoolSize(poolSize);
        executor.setQueueCapacity(200);
        executor.setThreadNamePrefix("recruitment-fit-");
        executor.initialize();
        return executor;
    }
}
