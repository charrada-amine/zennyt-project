package com.zennyt.recruitment.domain.vo;

/**
 * Les 5 modules psychométriques du CdC Fit Score v3 (§3.2, §4.3 Couche A),
 * découplés du {@code GameType} du contexte Games — même principe d'isolation
 * que {@code GenerateSoftSkillsSummaryUseCase.MODULE_LABELS}, qui documente la
 * même correspondance à des fins d'affichage.
 *
 * <p>État réel côté Games (vérifié dans {@code MiniGame}, {@code GameType}) :
 * {@link #COGNITIVE_FLEXIBILITY}, {@link #WORKING_MEMORY},
 * {@link #EXECUTIVE_PLANNING} et {@link #EMOTIONAL_REGULATION} sont mesurables.
 * {@code DECISION} reste déclaré côté Games mais sans mini-jeu jouable
 * ({@code MiniGame.DECISION_CORE.playable() == false}, catalogue de scénarios
 * vide) : sa pondération ne s'applique donc jamais en pratique tant que ce
 * catalogue n'est pas rempli — pas un cas limite rare, l'état permanent
 * jusque-là.
 */
public enum SoftSkillModule {
    COGNITIVE_FLEXIBILITY, WORKING_MEMORY, DECISION_MAKING, EXECUTIVE_PLANNING, EMOTIONAL_REGULATION;

    /** @return {@code null} si le module Games n'est pas (encore) rattaché à un module CdC. */
    public static SoftSkillModule fromGamesModule(String gamesModule) {
        return switch (gamesModule) {
            case "MOVE_FAST" -> COGNITIVE_FLEXIBILITY;
            case "MEMORY_QUEST" -> WORKING_MEMORY;
            case "PLANIFIK" -> EXECUTIVE_PLANNING;
            case "DECISION" -> DECISION_MAKING;
            case "EMOTIONAL_REGULATION" -> EMOTIONAL_REGULATION;
            default -> null;
        };
    }
}
