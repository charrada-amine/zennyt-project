package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository.PairNeedingScore;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

/**
 * Le balayage est le filet qui garantit qu'aucune paire ne reste sans score.
 * Ses invariants : il respecte sa borne de lot (il ne doit pas monopoliser la
 * base partagée), et un incident isolé ne doit jamais interrompre le
 * planificateur — sinon on recrée le trou permanent qu'il est censé combler.
 */
class FitScoreBackfillWorkerTest {

    private static final int BATCH_SIZE = 200;

    private FitScoreRepository fitScores;
    private JobOfferRepository offers;
    private RecomputeFitScoresUseCase recompute;
    private FitScoreBackfillWorker worker;

    @BeforeEach
    void setUp() {
        fitScores = mock(FitScoreRepository.class);
        offers = mock(JobOfferRepository.class);
        recompute = mock(RecomputeFitScoresUseCase.class);
        when(recompute.recomputeBatch(any())).thenReturn(List.of());
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(List.of());
        when(fitScores.findStalePairs(anyInt())).thenReturn(List.of());
        worker = new FitScoreBackfillWorker(fitScores, offers, recompute,
            new SimpleMeterRegistry(), BATCH_SIZE);
    }

    @Test
    void soumetChaquePaireEnAttenteAuCalculParLot() {
        JobOffer premiere = offer();
        JobOffer seconde = offer();
        UUID candidat = UUID.randomUUID();
        when(fitScores.findPairsNeedingScore(BATCH_SIZE)).thenReturn(List.of(
            new PairNeedingScore(candidat, premiere.id()),
            new PairNeedingScore(candidat, seconde.id())));
        when(offers.findByIds(any())).thenReturn(List.of(premiere, seconde));

        worker.backfillMissingScores();

        ArgumentCaptor<List<RecomputeFitScoresUseCase.Pair>> captor = ArgumentCaptor.forClass(List.class);
        verify(recompute).recomputeBatch(captor.capture());
        assertThat(captor.getValue()).extracting(pair -> pair.offer().id())
            .containsExactly(premiere.id(), seconde.id());
    }

    @Test
    void respecteLaBorneDeLotMemeAvecUnEnormeRetard() {
        worker.backfillMissingScores();

        // La borne est appliquée par la requête elle-même : c'est ce qui empêche
        // un retard massif de se traduire par un passage sans fin.
        verify(fitScores).findPairsNeedingScore(BATCH_SIZE);
    }

    @Test
    void lesPairesSansScorePassentAvantLesPerimees() {
        JobOffer manquante = offer();
        JobOffer perimee = offer();
        UUID candidat = UUID.randomUUID();
        when(fitScores.findPairsNeedingScore(BATCH_SIZE))
            .thenReturn(List.of(new PairNeedingScore(candidat, manquante.id())));
        when(fitScores.findStalePairs(BATCH_SIZE - 1))
            .thenReturn(List.of(new PairNeedingScore(candidat, perimee.id())));
        when(offers.findByIds(any())).thenReturn(List.of(manquante, perimee));

        worker.backfillMissingScores();

        ArgumentCaptor<List<RecomputeFitScoresUseCase.Pair>> captor = ArgumentCaptor.forClass(List.class);
        verify(recompute).recomputeBatch(captor.capture());
        assertThat(captor.getValue()).extracting(pair -> pair.offer().id())
            .containsExactly(manquante.id(), perimee.id());
    }

    @Test
    void unLotDejaPleinDeManquantesNeChercheAucunePerimee() {
        JobOffer offre = offer();
        UUID candidat = UUID.randomUUID();
        List<PairNeedingScore> lotPlein = java.util.stream.IntStream.range(0, BATCH_SIZE)
            .mapToObj(i -> new PairNeedingScore(candidat, offre.id())).toList();
        when(fitScores.findPairsNeedingScore(BATCH_SIZE)).thenReturn(lotPlein);
        when(offers.findByIds(any())).thenReturn(List.of(offre));

        worker.backfillMissingScores();

        // Budget du lot déjà consommé : inutile d'interroger la fraîcheur, et surtout
        // pas au prix d'une requête supplémentaire sur la base partagée.
        verify(fitScores, never()).findStalePairs(anyInt());
    }

    @Test
    void offreDisparueEntreLaSelectionEtLeChargementEstIgnoree() {
        JobOffer survivante = offer();
        UUID candidat = UUID.randomUUID();
        when(fitScores.findPairsNeedingScore(BATCH_SIZE)).thenReturn(List.of(
            new PairNeedingScore(candidat, UUID.randomUUID()), // supprimée entre-temps
            new PairNeedingScore(candidat, survivante.id())));
        when(offers.findByIds(any())).thenReturn(List.of(survivante));

        worker.backfillMissingScores();

        ArgumentCaptor<List<RecomputeFitScoresUseCase.Pair>> captor = ArgumentCaptor.forClass(List.class);
        verify(recompute).recomputeBatch(captor.capture());
        assertThat(captor.getValue()).extracting(pair -> pair.offer().id())
            .containsExactly(survivante.id());
    }

    @Test
    void unLotEnEchecNInterromptPasLePlanificateur() {
        JobOffer offre = offer();
        when(fitScores.findPairsNeedingScore(BATCH_SIZE))
            .thenReturn(List.of(new PairNeedingScore(UUID.randomUUID(), offre.id())));
        when(offers.findByIds(any())).thenReturn(List.of(offre));
        when(recompute.recomputeBatch(any())).thenThrow(new IllegalStateException("base indisponible"));

        assertThatCode(() -> worker.backfillMissingScores()).doesNotThrowAnyException();
    }

    @Test
    void aucunePaireEnAttenteNeDeclencheAucunCalcul() {
        worker.backfillMissingScores();

        verifyNoInteractions(offers, recompute);
    }

    private static JobOffer offer() {
        Instant now = Instant.now();
        return JobOffer.rehydrate(UUID.randomUUID(), UUID.randomUUID(), null, "Développeur",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, UUID.randomUUID(), false, JobOfferStatus.ACTIVE, now, now);
    }
}
