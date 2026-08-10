package com.zennyt.architecture;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.recruitment.domain.vo.SoftSkillModule;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Garde-fou entre deux contextes qui ne peuvent pas se parler.
 *
 * <p>{@link SoftSkillModule} redit ce que {@link MiniGame} sait déjà : quels jeux
 * existent réellement. Le doublon n'est pas un oubli — la règle d'architecture
 * (« un bounded context ne dépend pas du domaine d'un autre », voir
 * {@code ArchitectureTest}) interdit à recruitment d'importer {@code MiniGame} en
 * production. Le prix de cette isolation est que les deux listes peuvent diverger,
 * et le Fit Score se tromperait alors sans rien signaler : un jeu livré mais resté à
 * {@code false} sort du dénominateur, donc plus personne n'est pénalisé de ne pas
 * l'avoir joué.
 *
 * <p>C'est exactement ce qui s'est produit le 2026-08-10 : Games a livré « Je continue »,
 * « Je coordonne » et la mémoire visuospatiale, et le calcul du Fit Score les ignorait
 * encore. Ce test transforme cette dérive en échec de CI plutôt qu'en score faux.
 *
 * <p>Vit dans le paquet {@code architecture} et non dans {@code recruitment} : c'est du
 * code de test, hors du périmètre scanné par ArchUnit, donc autorisé à voir les deux côtés.
 */
class SoftSkillModuleGamesParityTest {

    /** Ce que Games considère jouable : au moins un mini-jeu avec un barème. */
    private static Map<String, Boolean> playableParGameType() {
        Map<String, Boolean> playable = new LinkedHashMap<>();
        for (GameType type : GameType.values()) {
            playable.put(type.name(), Arrays.stream(MiniGame.values())
                .filter(game -> game.belongsTo(type))
                .anyMatch(MiniGame::isPlayable));
        }
        return playable;
    }

    @Test
    @DisplayName("Chaque jeu déclaré par le Fit Score existe bien côté Games")
    void aucunJeuFantome() {
        Set<String> connusDeGames = playableParGameType().keySet();

        Set<String> declaresParFitScore = Arrays.stream(SoftSkillModule.values())
            .flatMap(module -> module.games().stream())
            .map(SoftSkillModule.Game::gamesModule)
            .collect(Collectors.toSet());

        assertThat(connusDeGames)
            .as("Un jeu renommé ou supprimé côté Games laisse ici une clé morte : "
                + "elle ne remontera jamais de score, en silence.")
            .containsAll(declaresParFitScore);
    }

    @Test
    @DisplayName("La disponibilité déclarée au Fit Score suit celle de Games")
    void disponibiliteAlignee() {
        Map<String, Boolean> cotesGames = playableParGameType();

        Map<String, Boolean> ecarts = new LinkedHashMap<>();
        for (SoftSkillModule module : SoftSkillModule.values()) {
            for (SoftSkillModule.Game game : module.games()) {
                boolean cotéGames = cotesGames.getOrDefault(game.gamesModule(), false);
                if (cotéGames != game.available()) {
                    ecarts.put(game.gamesModule(),  cotéGames);
                }
            }
        }

        assertThat(ecarts)
            .as("Games et le Fit Score ne sont plus d'accord sur ces jeux. La valeur "
                + "indiquée est celle de Games (isPlayable), qui fait foi : reportez-la "
                + "dans SoftSkillModule. Un jeu livré mais laissé à false sort du "
                + "dénominateur et fausse toutes les couvertures.")
            .isEmpty();
    }

    /**
     * Le seul module attendu comme non mesurable est « Je Décide » : son moteur existe,
     * son catalogue de 30 scénarios est vide en attendant le psychologue. Si un autre
     * module devient non mesurable, c'est soit une régression Games, soit une décision
     * qui doit être écrite noir sur blanc.
     */
    @Test
    @DisplayName("Seule la prise de décision reste non mesurable")
    void seuleLaPriseDeDecisionEstNonMesurable() {
        assertThat(Arrays.stream(SoftSkillModule.values())
            .filter(SoftSkillModule::unmeasurable)
            .toList())
            .containsExactly(SoftSkillModule.DECISION_MAKING);
    }
}
