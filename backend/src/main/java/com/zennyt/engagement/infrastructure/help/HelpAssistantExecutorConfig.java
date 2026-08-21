package com.zennyt.engagement.infrastructure.help;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Fil d'execution dedie aux reponses de l'assistant.
 *
 * <p>Un pool borne, et separe de celui des requetes utilisateur : une generation de texte
 * attend un service distant pendant plusieurs secondes, et laisser ces attentes occuper
 * les fils qui servent les ecrans ferait ralentir toute l'application des qu'une poignee
 * de questions arrivent ensemble.
 *
 * <p>La file d'attente est courte deliberement. Si elle deborde, la tache est rejetee et
 * l'utilisateur n'obtient pas de reponse automatique — desagreable, mais preferable a une
 * file qui gonfle et rend des reponses a des questions posees dix minutes plus tot.
 */
@Configuration
public class HelpAssistantExecutorConfig {

    @Bean("engagementHelpExecutor")
    TaskExecutor engagementHelpExecutor() {
        ThreadPoolTaskExecutor executeur = new ThreadPoolTaskExecutor();
        executeur.setCorePoolSize(2);
        executeur.setMaxPoolSize(4);
        executeur.setQueueCapacity(20);
        executeur.setThreadNamePrefix("aide-");
        executeur.setRejectedExecutionHandler(new java.util.concurrent.ThreadPoolExecutor.AbortPolicy());
        executeur.initialize();
        return executeur;
    }
}
