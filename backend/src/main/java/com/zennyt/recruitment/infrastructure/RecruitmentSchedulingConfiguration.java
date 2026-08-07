package com.zennyt.recruitment.infrastructure;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Active la planification pour le contexte Recruitment ({@code FitScoreBackfillWorker}).
 *
 * <p>Techniquement redondant : {@code @EnableScheduling} enregistre un post-processeur
 * unique et valable pour toute l'application, et le contexte Engagement en déclare déjà
 * un. Cette classe existe pour ne pas faire dépendre silencieusement le balayage
 * Recruitment d'une configuration appartenant à un autre bounded context — supprimer
 * celle d'Engagement arrêterait sinon ce balayage sans le moindre signal à la
 * compilation. Spring dédoublonne l'import sans effet de bord.
 */
@Configuration
@EnableScheduling
public class RecruitmentSchedulingConfiguration {
}
