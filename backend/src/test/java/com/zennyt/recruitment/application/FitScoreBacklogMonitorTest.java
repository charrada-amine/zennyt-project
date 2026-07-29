package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.*;

class FitScoreBacklogMonitorTest {

    private static final String GAUGE = "recruitment.fitscore.backlog.depth";

    private final FitScoreRepository fitScores = mock(FitScoreRepository.class);
    private final MeterRegistry registry = new SimpleMeterRegistry();
    private final FitScoreBacklogMonitor monitor = new FitScoreBacklogMonitor(fitScores, registry);

    @Test
    void publieLaProfondeurDuRetardCommeJauge() {
        when(fitScores.countPairsNeedingScore()).thenReturn(4_200L);

        monitor.measureBacklogDepth();

        assertThat(registry.get(GAUGE).gauge().value()).isEqualTo(4_200d);
        assertThat(monitor.lastMeasuredDepth()).isEqualTo(4_200L);
    }

    @Test
    void avantTouteMesureLaJaugeVautMoinsUnPasZero() {
        // Un zéro laisserait croire à un retard nul alors qu'on n'a simplement rien mesuré.
        assertThat(monitor.lastMeasuredDepth()).isEqualTo(-1L);
        verifyNoInteractions(fitScores);
    }

    @Test
    void uneMesureEnEchecConserveLaValeurPrecedente() {
        when(fitScores.countPairsNeedingScore()).thenReturn(17L);
        monitor.measureBacklogDepth();

        when(fitScores.countPairsNeedingScore()).thenThrow(new IllegalStateException("base indisponible"));

        assertThatCode(monitor::measureBacklogDepth).doesNotThrowAnyException();
        assertThat(monitor.lastMeasuredDepth())
            .as("la dernière mesure valable est conservée, pas écrasée par un zéro trompeur")
            .isEqualTo(17L);
    }
}
