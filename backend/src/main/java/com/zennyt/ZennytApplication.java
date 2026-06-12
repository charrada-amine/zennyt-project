package com.zennyt;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Point d'entrée du monolithe modulaire.
 *
 * <p>L'application est organisée en bounded contexts (identity, recruitment,
 * engagement, analytics) sous le package racine {@code com.zennyt}.
 * Chaque contexte suit l'architecture hexagonale et ne communique avec les
 * autres que par Domain Events — jamais par appel direct.
 */
@SpringBootApplication
@EnableJpaRepositories
public class ZennytApplication {
    public static void main(String[] args) {
        SpringApplication.run(ZennytApplication.class, args);
    }
}
