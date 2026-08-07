package com.zennyt.recruitment.domain.vo;

import java.util.Arrays;
import java.util.List;

/**
 * Les 5 modules psychométriques du CdC Fit Score v3 (§3.2, §4.3 Couche A),
 * découplés du {@code GameType} du contexte Games.
 *
 * <p><b>Un module peut être alimenté par plusieurs jeux.</b> Le hub mobile
 * l'affiche ainsi (5 cartes = les 5 modules, plusieurs jeux par carte) :
 * Flexibilité cognitive = Move Fast + Je continue + Je coordonne ; Mémoire de
 * travail = Memory Quest + Je place. À ne pas confondre avec les <i>mini-jeux</i>
 * d'un même {@code GameType} (les 3 de Planifik, les 2 de la régulation
 * émotionnelle) : ceux-là sont agrégés par Games lui-même et n'arrivent ici que
 * sous forme d'une seule ligne.
 *
 * <p>C'est la source unique de vérité de <b>ce que le Fit Score sait mesurer
 * aujourd'hui</b>. Chaque jeu porte un drapeau {@code available} : un jeu non
 * disponible ne pénalise personne (il sort du dénominateur), un jeu disponible
 * que le candidat n'a pas joué le pénalise (il reste au dénominateur avec un
 * score nul). Voir {@code FITSCORE_REMEDIATION.md} §2, décision D-D telle
 * qu'ajustée le 2026-08-05.
 *
 * <p><b>À tenir à jour quand Games livre :</b> passer un jeu à {@code true} suffit
 * — le calcul s'adapte sans autre modification.
 */
public enum SoftSkillModule {

    COGNITIVE_FLEXIBILITY(
        game("MOVE_FAST", true),
        // Livrés par Games mais pas encore fusionnés chez nous (cf. GAMES_MODULE.md).
        game("CONTINUOUS_ATTENTION", false),
        game("VISUOMOTOR_COORDINATION", false)),

    WORKING_MEMORY(
        game("MEMORY_QUEST", true),
        game("VISUOSPATIAL_MEMORY", false)),

    /**
     * « Je Décide » — moteur backend et écrans mobiles complets, mais le catalogue
     * de 30 scénarios est vide ({@code EmptyDecisionScenarioCatalog},
     * {@code DECISION_CORE.isPlayable() == false}). En attente du psychologue.
     * Tant que c'est le cas, ce module ne compte dans aucun score : sans ça, un
     * développeur parfait plafonnerait à 70/100 — exactement le seuil « bon profil ».
     */
    DECISION_MAKING(game("DECISION", false)),

    EXECUTIVE_PLANNING(game("PLANIFIK", true)),

    EMOTIONAL_REGULATION(game("EMOTIONAL_REGULATION", true));

    /** Un jeu Games alimentant un module, et sa disponibilité réelle. */
    public record Game(String gamesModule, boolean available) {}

    private static Game game(String gamesModule, boolean available) {
        return new Game(gamesModule, available);
    }

    private final List<Game> games;

    SoftSkillModule(Game... games) {
        this.games = List.of(games);
    }

    /** @return {@code null} si le module Games n'est rattaché à aucun module CdC. */
    public static SoftSkillModule fromGamesModule(String gamesModule) {
        return Arrays.stream(values())
            .filter(module -> module.games.stream().anyMatch(g -> g.gamesModule().equals(gamesModule)))
            .findFirst()
            .orElse(null);
    }

    /**
     * Nombre de jeux réellement disponibles pour ce module — le dénominateur de sa
     * couverture. Un candidat ayant joué Move Fast seul couvre 1 jeu sur les 3 de la
     * Flexibilité cognitive une fois les deux autres livrés ; aujourd'hui il la couvre
     * entièrement, puisqu'ils n'existent pas encore.
     */
    public int availableGameCount() {
        return (int) games.stream().filter(Game::available).count();
    }

    /**
     * {@code true} si aucun jeu de ce module n'est disponible — le module sort alors
     * du calcul, numérateur <b>et</b> dénominateur. On ne pénalise personne pour un
     * jeu qui n'existe pour personne.
     */
    public boolean unmeasurable() {
        return availableGameCount() == 0;
    }

    public List<Game> games() {
        return games;
    }
}
