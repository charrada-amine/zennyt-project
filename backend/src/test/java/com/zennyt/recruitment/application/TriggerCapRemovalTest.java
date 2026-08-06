package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.*;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

/**
 * T2.1 à T2.3 — le plafond de 20 par déclencheur a bien disparu.
 *
 * <p>Reproduit le cas constaté en juillet : un candidat rejoue un mini-jeu alors que
 * 28 offres sont actives. Avant, seules 20 paires étaient rafraîchies et les 8 autres
 * gardaient un score faux <b>indéfiniment</b> — aucun mécanisme ne revenait les chercher.
 * Le test échoue si quelqu'un réintroduit un plafond bas.
 */
class TriggerCapRemovalTest {

    private static final UUID CANDIDAT = UUID.randomUUID();

    private JobOffer offre() {
        Instant now = Instant.now();
        return JobOffer.rehydrate(UUID.randomUUID(), UUID.randomUUID(), null, "Développeur",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, UUID.randomUUID(), false, JobOfferStatus.ACTIVE, now, now);
    }

    private RecomputeFitScoresUseCase useCase(JobOfferRepository offers,
                                              SoftSkillsProjectionRepository soft) {
        FitScoreCalculatorPort calculator = inputs ->
            new FitScoreCalculatorPort.FitScoreResult(50, 50, 100);
        return new RecomputeFitScoresUseCase(calculator, mock(FitScoreRepository.class), offers,
            soft, mock(JobRoleProfileResolver.class), mock(TestResultRepository.class), 5000);
    }

    @Test
    void t2_1_miniJeuRejoueAvec28OffresActivesLesRafraichitToutes() {
        List<JobOffer> vingtHuit = new ArrayList<>();
        for (int i = 0; i < 28; i++) vingtHuit.add(offre());
        JobOfferRepository offers = mock(JobOfferRepository.class);
        when(offers.findFeedForCandidate(eq(CANDIDAT), anyInt(), anyInt())).thenReturn(vingtHuit);

        var pairs = useCase(offers, mock(SoftSkillsProjectionRepository.class))
            .pairsForCandidate(CANDIDAT);

        assertThat(pairs).as("les 28, pas 20 — c'est le bug de juillet").hasSize(28);
    }

    @Test
    void t2_2_miniJeuRejoueAvec500OffresNOublieAucunePaire() {
        List<JobOffer> beaucoup = new ArrayList<>();
        for (int i = 0; i < 500; i++) beaucoup.add(offre());
        JobOfferRepository offers = mock(JobOfferRepository.class);
        when(offers.findFeedForCandidate(eq(CANDIDAT), anyInt(), anyInt())).thenReturn(beaucoup);

        var pairs = useCase(offers, mock(SoftSkillsProjectionRepository.class))
            .pairsForCandidate(CANDIDAT);

        assertThat(pairs).hasSize(500);
        assertThat(pairs).extracting(p -> p.offer().id()).doesNotHaveDuplicates();
    }

    @Test
    void t2_3_offrePublieeAvec300CandidatsLesTraiteTous() {
        JobOffer offre = offre();
        JobOfferRepository offers = mock(JobOfferRepository.class);
        when(offers.findById(offre.id())).thenReturn(java.util.Optional.of(offre));
        SoftSkillsProjectionRepository soft = mock(SoftSkillsProjectionRepository.class);
        List<UUID> troisCents = new ArrayList<>();
        for (int i = 0; i < 300; i++) troisCents.add(UUID.randomUUID());
        when(soft.findCandidateIds(anyInt())).thenReturn(troisCents);

        var pairs = useCase(offers, soft).pairsForOffer(offre.id());

        assertThat(pairs).hasSize(300);
    }

    @Test
    void leGardeFouLargeEstBienCeluiDemandeAuxRepositories() {
        JobOfferRepository offers = mock(JobOfferRepository.class);
        when(offers.findFeedForCandidate(any(), anyInt(), anyInt())).thenReturn(List.of());

        useCase(offers, mock(SoftSkillsProjectionRepository.class)).pairsForCandidate(CANDIDAT);

        // 5000, pas 20 : la borne restante protège d'une requête pathologique,
        // elle ne borne pas le fonctionnement normal.
        verify(offers).findFeedForCandidate(CANDIDAT, 0, 5000);
    }
}
