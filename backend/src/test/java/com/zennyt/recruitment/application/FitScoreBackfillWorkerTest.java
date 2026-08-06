package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository.PairNeedingScore;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

/**
 * T4.1 à T4.6 — le balayage est devenu du pré-remplissage.
 *
 * <p>Changement de rôle : il ne calcule plus, il <b>détecte et enfile</b>. Et il n'est plus
 * la garantie de correction — c'est le calcul à l'affichage qui l'est. En régime établi il
 * ne doit rien trouver ; sa métrique est donc un détecteur de bug, pas une mesure d'activité.
 */
class FitScoreBackfillWorkerTest {

    private FitScoreRepository fitScores;
    private FitScoreEnqueuer enqueuer;
    private MeterRegistry meters;

    @BeforeEach
    void setUp() {
        fitScores = mock(FitScoreRepository.class);
        enqueuer = mock(FitScoreEnqueuer.class);
        meters = new SimpleMeterRegistry();
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(List.of());
        when(fitScores.findStalePairs(anyInt())).thenReturn(List.of());
    }

    private FitScoreBackfillWorker worker(int batchSize, long deadlineMs) {
        return new FitScoreBackfillWorker(fitScores, enqueuer, meters, batchSize, deadlineMs);
    }

    private List<PairNeedingScore> paires(int combien) {
        List<PairNeedingScore> list = new ArrayList<>();
        for (int i = 0; i < combien; i++) {
            list.add(new PairNeedingScore(UUID.randomUUID(), UUID.randomUUID()));
        }
        return list;
    }

    @Test
    void t4_4_baseSaineNeTrouveRienEtNeCouteRien() {
        worker(200, 5000).backfillMissingScores();

        verify(enqueuer, never()).enqueueNormal(any());
        assertThat(meters.get("recruitment.fitscore.backfill.found").counter().count())
            .as("doit rester à 0 en régime établi").isZero();
    }

    @Test
    void t4_5_unTrouEstDetecteEtEnfileEnPrioriteNormale() {
        List<PairNeedingScore> trouvees = paires(3);
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(trouvees, List.of());

        worker(200, 5000).backfillMissingScores();

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<CandidateOfferPair>> captor = ArgumentCaptor.forClass(List.class);
        verify(enqueuer).enqueueNormal(captor.capture());
        assertThat(captor.getValue()).hasSize(3);
        // Priorité normale : le rattrapage ne doit pas passer devant les événements frais.
        verify(enqueuer, never()).enqueueUrgent(any());
        assertThat(meters.get("recruitment.fitscore.backfill.found").counter().count()).isEqualTo(3.0);
    }

    @Test
    void ilNeCalculeJamaisLuiMeme() {
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(paires(5), List.of());

        worker(200, 5000).backfillMissingScores();

        // Un seul chemin d'exécution : tout passe par la file, rien n'est calculé ici.
        verify(enqueuer, times(1)).enqueueNormal(any());
        verifyNoMoreInteractions(enqueuer);
    }

    @Test
    void t4_1_laDeadlineArreteProprementApresLaTrancheEnCours() {
        // Toujours une tranche pleine : sans deadline, la boucle ne s'arrêterait jamais.
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(paires(10));

        worker(10, 0).backfillMissingScores();

        // Deadline à 0 : aucune tranche ne démarre, arrêt immédiat et propre.
        verify(enqueuer, never()).enqueueNormal(any());
    }

    @Test
    void laBoucleEnchaineTantQueLesTranchesSontPleines() {
        // Deux tranches pleines puis une partielle : la boucle doit faire les trois.
        when(fitScores.findPairsNeedingScore(anyInt()))
            .thenReturn(paires(10), paires(10), paires(4), List.of());

        worker(10, 60_000).backfillMissingScores();

        verify(enqueuer, times(3)).enqueueNormal(any());
        assertThat(meters.get("recruitment.fitscore.backfill.found").counter().count())
            .isEqualTo(24.0);
    }

    @Test
    void lesPairesPerimeesCompletentLeBudgetDeLaTranche() {
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(paires(3), List.of());
        when(fitScores.findStalePairs(anyInt())).thenReturn(paires(2), List.of());

        worker(10, 5000).backfillMissingScores();

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<CandidateOfferPair>> captor = ArgumentCaptor.forClass(List.class);
        verify(enqueuer).enqueueNormal(captor.capture());
        assertThat(captor.getValue()).as("3 manquantes + 2 périmées").hasSize(5);
    }

    /**
     * Les paires sans score passent devant les paires périmées : une paire sans score est
     * toujours reléguée en fin de liste, alors qu'une paire périmée reste visible — mal
     * classée, mais visible. Les périmées ne reçoivent donc que le budget restant.
     */
    @Test
    void lesManquantesPassentAvantLesPerimees() {
        when(fitScores.findPairsNeedingScore(anyInt())).thenReturn(paires(3), List.of());

        worker(10, 5000).backfillMissingScores();

        // 3 manquantes sur un budget de 10 : les périmées n'ont droit qu'aux 7 restantes.
        verify(fitScores).findStalePairs(7);
    }
}
