package com.zennyt.games.domain;

import com.zennyt.games.domain.config.ReflectivePauseConfig;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.service.PlanifikScoringService;
import com.zennyt.games.domain.service.ReflectivePauseScoringService;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.games.domain.vo.ReflectivePauseMedium;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMomentMetric;
import com.zennyt.games.domain.vo.ReflectivePauseReport;
import com.zennyt.games.domain.vo.ReflectivePauseResponseType;
import com.zennyt.games.domain.vo.Score;
import com.zennyt.games.domain.vo.SessionStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Barème « Reflective Pause » — Java pur, sans Spring.
 */
class ReflectivePauseScoringTest {

    private final ReflectivePauseScoringService scoring =
        new ReflectivePauseScoringService();

    /**
     * Réaction la mieux cotée de TR-001 à TR-010, relevée à la main dans le
     * document du client.
     *
     * <p>Écrite en dur exprès. La lire depuis {@link ReflectivePauseConfig}
     * rendrait le test tautologique : il confirmerait que la table est égale à
     * elle-même. Ces valeurs viennent des justifications psychométriques des
     * fiches — « E corrige factuellement » pour TR-001, « D le plus adapté »
     * pour TR-002 — et attrapent donc une table mal engendrée.
     */
    private static ReflectivePauseResponseType recommended(int index) {
        return switch (index) {
            case 1, 5, 8 -> ReflectivePauseResponseType.REFORMULATE_CALMLY;
            case 2, 3, 4 -> ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION;
            case 7, 9 -> ReflectivePauseResponseType.BREATHE_ANALYZE;
            case 6, 10 -> ReflectivePauseResponseType.WAIT;
            default -> throw new IllegalArgumentException();
        };
    }

    private static ReflectivePauseMetrics perfectMetrics() {
        List<ReflectivePauseMomentMetric> moments = new ArrayList<>();
        for (int i = 1; i <= ReflectivePauseConfig.TOTAL_MOMENTS; i++) {
            moments.add(new ReflectivePauseMomentMetric(
                "TR-%03d".formatted(i),
                recommended(i),
                4_000,
                true));
        }
        return new ReflectivePauseMetrics(moments);
    }

    @Test
    @DisplayName("10 pauses + 10 réponses recommandées → 3 + 4 + 3 = 10/10")
    void perfectJourneyScoresTen() {
        Score score = scoring.score(perfectMetrics());
        ReflectivePauseReport report = scoring.report(perfectMetrics());

        assertThat(score.rawPoints()).isEqualTo(10);
        assertThat(score.maxPoints()).isEqualTo(10);
        assertThat(score.level()).isEqualTo("Very good self-control");
        assertThat(report.controlledReactionTimeScore()).isEqualTo(3.0);
        assertThat(report.nonImpulsiveResponsesScore()).isEqualTo(4.0);
        assertThat(report.abilityToStepBackScore()).isEqualTo(3.0);
        assertThat(report.impulsiveChoiceCount()).isZero();
    }

    @Test
    @DisplayName("8 pauses, 9 non-impulsives, 7 recommandées → 2.4 + 3.6 + 2.1 → 8/10")
    void mixedJourneyUsesWeightedRatesAndRoundsOnce() {
        List<ReflectivePauseMomentMetric> moments =
            new ArrayList<>(perfectMetrics().moments());
        moments.set(0, new ReflectivePauseMomentMetric(
            "TR-001",
            ReflectivePauseResponseType.RESPOND_IMPULSIVELY,
            2_000,
            false));
        // TR-008 attend « reformuler » : attendre reste posé mais non recommandé.
        moments.set(7, new ReflectivePauseMomentMetric(
            "TR-008",
            ReflectivePauseResponseType.WAIT,
            2_000,
            false));
        // TR-010 attend « attendre » : il faut donc une AUTRE réponse posée
        // pour rester à sept recommandations.
        moments.set(9, new ReflectivePauseMomentMetric(
            "TR-010",
            ReflectivePauseResponseType.BREATHE_ANALYZE,
            4_000,
            true));
        ReflectivePauseMetrics metrics = new ReflectivePauseMetrics(moments);

        ReflectivePauseReport report = scoring.report(metrics);
        Score score = scoring.score(metrics);

        assertThat(report.controlledReactionTimeScore()).isEqualTo(2.4);
        assertThat(report.nonImpulsiveResponsesScore()).isEqualTo(3.6);
        assertThat(report.abilityToStepBackScore()).isEqualTo(2.1);
        assertThat(score.rawPoints()).isEqualTo(8);
    }

    @Test
    @DisplayName("Le booléen du timer ne peut pas contredire le temps brut")
    void timerFlagMustMatchResponseTime() {
        assertThatThrownBy(() -> new ReflectivePauseMomentMetric(
            "TR-001",
            ReflectivePauseResponseType.BREATHE_ANALYZE,
            2_999,
            true))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("incohérent");
    }

    @Test
    @DisplayName("Les 10 identifiants du catalogue sont obligatoires et uniques")
    void completeUniqueCatalogIsRequired() {
        List<ReflectivePauseMomentMetric> duplicated =
            new ArrayList<>(perfectMetrics().moments());
        duplicated.set(9, duplicated.get(0));

        assertThatThrownBy(() -> new ReflectivePauseMetrics(duplicated))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("dupliqué");
    }

    @Test
    @DisplayName("Le catalogue porte les 60 situations de la banque client")
    void catalogHoldsTheSixtySituations() {
        // La table était écrite à la main sur dix moments inventés
        // (PRESSURE_01 à PRESSURE_10). Ces identifiants n'existent plus côté
        // écran, et un identifiant inconnu fait LEVER le domaine : une partie
        // jouée sur la vraie banque échouait à l'enregistrement.
        assertThat(ReflectivePauseConfig.momentIds()).hasSize(60);
        assertThat(ReflectivePauseConfig.momentIds()).contains("TR-001", "TR-060");

        assertThatThrownBy(() -> new ReflectivePauseMomentMetric(
            "PRESSURE_01",
            ReflectivePauseResponseType.BREATHE_ANALYZE,
            4_000,
            true))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("inconnu");
    }

    @Test
    @DisplayName("Dix situations parmi soixante suffisent, le catalogue entier n'est pas exigé")
    void aDrawOfTenIsEnough() {
        // L'ancienne règle exigeait que les identifiants remontés soient ÉGAUX
        // au catalogue. Avec soixante situations dont une partie n'en joue que
        // dix, elle rejetait toute partie réelle.
        List<ReflectivePauseMomentMetric> moments = new ArrayList<>();
        for (int i = 51; i <= 60; i++) {
            moments.add(new ReflectivePauseMomentMetric(
                "TR-0%d".formatted(i),
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                4_000,
                true,
                ReflectivePauseMedium.VIDEO));
        }

        ReflectivePauseMetrics metrics = new ReflectivePauseMetrics(moments);
        assertThat(metrics.moments()).hasSize(10);
        assertThat(metrics.moments().get(0).medium())
            .isEqualTo(ReflectivePauseMedium.VIDEO);
    }

    @Test
    @DisplayName("Le support reste facultatif et vaut « non renseigné »")
    void mediumStaysOptional() {
        ReflectivePauseMomentMetric sansSupport = new ReflectivePauseMomentMetric(
            "TR-001", ReflectivePauseResponseType.BREATHE_ANALYZE, 4_000, true);

        assertThat(sansSupport.medium()).isNull();
    }

    @Test
    @DisplayName("Emotional Regulation : Radar /27 + Reflective /10 → /37, module encore ouvert")
    void emotionalRegulationCompletesAfterBothMiniGames() {
        GameSession session = GameSession.start(
            UUID.randomUUID(), GameType.EMOTIONAL_REGULATION);
        PlanifikScoringService global = new PlanifikScoringService();

        session.recordResult(
            MiniGame.EMOTIONAL_RADAR_CORE,
            new Score(27, 27, "Excellent"),
            global);

        assertThat(session.status()).isEqualTo(SessionStatus.IN_PROGRESS);
        assertThat(session.compositeRaw()).isEqualTo(27);
        assertThat(session.compositeMax()).isEqualTo(37);
        assertThat(session.normalizedScore()).isLessThanOrEqualTo(100.0);

        session.recordResult(
            MiniGame.REFLECTIVE_PAUSE_CORE,
            new Score(8, 10, "Very good self-control"),
            global);

        // Le module compte TROIS mini-jeux depuis l'arrivée de « Choix
        // Stratégiques » : deux ne suffisent plus à le clore.
        assertThat(session.status()).isEqualTo(SessionStatus.IN_PROGRESS);
        assertThat(session.compositeRaw()).isEqualTo(35);
        // 27 (radar joué) + 10 (reflective joué) + 0 (choix stratégiques, barème
        // dynamique donc maximum encore inconnu).
        assertThat(session.compositeMax()).isEqualTo(37);
        // F14 — un événement par mini-jeu ; la couverture suit le module.
        assertThat(session.domainEvents()).hasSize(2);
        var premier = (com.zennyt.games.domain.event.GameResultRecordedEvent) session.domainEvents().get(0);
        var second = (com.zennyt.games.domain.event.GameResultRecordedEvent) session.domainEvents().get(1);
        assertThat(premier.coverageRatio()).isEqualTo(33);
        assertThat(second.coverageRatio()).isEqualTo(67);
    }
}
