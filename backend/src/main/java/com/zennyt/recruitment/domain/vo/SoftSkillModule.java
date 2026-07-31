package com.zennyt.recruitment.domain.vo;

/**
 * Les 5 modules psychométriques du CdC Fit Score v3 (§3.2, §4.3 Couche A),
 * découplés du {@code GameType} du contexte Games — même principe d'isolation
 * que {@code GenerateSoftSkillsSummaryUseCase.MODULE_LABELS}, qui documente la
 * même correspondance à des fins d'affichage.
 *
 * <p>État réel côté Games (vérifié dans {@code MiniGame}, {@code GameType}) :
 * seuls {@link #COGNITIVE_FLEXIBILITY}, {@link #WORKING_MEMORY} et
 * {@link #EXECUTIVE_PLANNING} sont mesurables aujourd'hui. {@code DECISION} est
 * déclaré côté Games mais sans aucun mini-jeu ; la régulation émotionnelle n'a
 * même pas de {@code GameType}. Leur poids ne s'applique donc jamais en
 * pratique tant que Games ne les implémente pas — un état permanent, pas un
 * cas limite rare.
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
            default -> null;
        };
    }
}
