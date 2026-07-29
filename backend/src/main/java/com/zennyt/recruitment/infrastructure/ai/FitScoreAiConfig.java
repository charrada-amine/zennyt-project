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

    @Bean(name = "recruitmentFitScoreExecutor")
    Executor recruitmentFitScoreExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(200);
        executor.setThreadNamePrefix("recruitment-fit-");
        executor.initialize();
        return executor;
    }
}
