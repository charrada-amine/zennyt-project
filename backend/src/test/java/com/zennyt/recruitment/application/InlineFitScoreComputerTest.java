package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.vo.*;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * T1.1 à T1.6 — le calcul à l'affichage.
 *
 * <p>Le point le plus important de cette classe est {@code failOpen...} : cette route est
 * l'une des plus fréquentées de l'application, et une exception qui s'en échapperait la
 * transformerait en source d'erreurs 500. C'est le comportement à ne jamais casser.
 */
class InlineFitScoreComputerTest {

    private static final UUID CANDIDAT = UUID.randomUUID();
    private static final UUID RECRUTEUR = UUID.randomUUID();

    private static final JobRoleProfile PONDERATION = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 35, 65, 65, 30, 20, 30, 15, 5,
        TypeEvaluationHard.QCM, false, Instant.now());

    private FitScoreRepository fitScores;
    private JobRoleProfileResolver resolver;
    private InlineFitScoreWriter writer;
    private MeterRegistry meters;

    @BeforeEach
    void setUp() {
        fitScores = mock(FitScoreRepository.class);
        resolver = mock(JobRoleProfileResolver.class);
        writer = mock(InlineFitScoreWriter.class);
        meters = new SimpleMeterRegistry();
        when(fitScores.findByPairs(any())).thenReturn(List.of());
        when(writer.computeAndPersist(any())).thenReturn(List.of());
    }

    private InlineFitScoreComputer computer(boolean enabled, long budgetMs, int maxPairs) {
        return new InlineFitScoreComputer(fitScores, resolver, writer, meters,
            enabled, budgetMs, maxPairs);
    }

    private JobOffer offre() {
        Instant now = Instant.now();
        return JobOffer.rehydrate(UUID.randomUUID(), RECRUTEUR, null, "Développeur",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, UUID.randomUUID(), false, JobOfferStatus.ACTIVE, now, now);
    }

    private List<JobOffer> offres(int n) {
        List<JobOffer> list = new ArrayList<>();
        for (int i = 0; i < n; i++) list.add(offre());
        return list;
    }

    private void toutesEligibles(List<JobOffer> pool) {
        Map<UUID, JobRoleProfile> profils = new HashMap<>();
        pool.forEach(o -> profils.put(o.id(), PONDERATION));
        when(resolver.resolveAll(any())).thenReturn(profils);
    }

    @Test
    void t1_1_aucunManquantNeDeclencheAucunCalcul() {
        List<JobOffer> pool = offres(3);
        // Toutes déjà notées.
        when(fitScores.findByPairs(any())).thenReturn(pool.stream()
            .map(o -> FitScore.calculated(UUID.randomUUID(), CANDIDAT, o.id(), 50, 50, null, 100, Instant.now()))
            .toList());

        var reste = computer(true, 800, 200).ensureScored(CANDIDAT, pool);

        assertThat(reste).isEmpty();
        verify(writer, never()).computeAndPersist(any());
    }

    @Test
    void t1_2_lesManquantsSontCalculesSansDoublon() {
        List<JobOffer> pool = offres(5);
        toutesEligibles(pool);

        computer(true, 800, 200).ensureScored(CANDIDAT, pool);

        @SuppressWarnings("unchecked")
        var captor = org.mockito.ArgumentCaptor.forClass(List.class);
        verify(writer).computeAndPersist(captor.capture());
        List<RecomputeFitScoresUseCase.Pair> soumises = captor.getValue();
        assertThat(soumises).hasSize(5);
        assertThat(soumises).extracting(p -> p.offer().id()).doesNotHaveDuplicates();
    }

    @Test
    void t1_3_budgetEpuiseArreteProprementEtRetourneLeReste() {
        List<JobOffer> pool = offres(10);
        toutesEligibles(pool);

        // Budget nul : rien n'entre dans le lot, tout est reporté.
        var reste = computer(true, 0, 200).ensureScored(CANDIDAT, pool);

        assertThat(reste).hasSize(10);
        verify(writer, never()).computeAndPersist(any());
        assertThat(meters.get("fitscore.inline.capped").counter().count()).isEqualTo(1.0);
    }

    @Test
    void t1_4_leplafondMaxPairsNestJamaisDepasse() {
        List<JobOffer> pool = offres(10);
        toutesEligibles(pool);

        var reste = computer(true, 60_000, 4).ensureScored(CANDIDAT, pool);

        @SuppressWarnings("unchecked")
        var captor = org.mockito.ArgumentCaptor.forClass(List.class);
        verify(writer).computeAndPersist(captor.capture());
        assertThat(captor.getValue()).hasSize(4);
        assertThat(reste).hasSize(6);
    }

    @Test
    void t1_5_uneOffreAuMetierNonValideEstExclueDuCalcul() {
        List<JobOffer> pool = offres(3);
        // Seule la première a un profil résolu ; les deux autres attendent un admin.
        Map<UUID, JobRoleProfile> profils = new HashMap<>();
        profils.put(pool.get(0).id(), PONDERATION);
        when(resolver.resolveAll(any())).thenReturn(profils);

        var reste = computer(true, 800, 200).ensureScored(CANDIDAT, pool);

        @SuppressWarnings("unchecked")
        var captor = org.mockito.ArgumentCaptor.forClass(List.class);
        verify(writer).computeAndPersist(captor.capture());
        List<RecomputeFitScoresUseCase.Pair> soumises = captor.getValue();
        assertThat(soumises).hasSize(1);
        assertThat(soumises.get(0).offer().id()).isEqualTo(pool.get(0).id());
        // Jamais reportées non plus : sinon elles reviendraient à chaque affichage.
        assertThat(reste).isEmpty();
    }

    @Test
    void t1_6_drapeauDesactiveNeChangeStrictementRien() {
        List<JobOffer> pool = offres(5);

        var reste = computer(false, 800, 200).ensureScored(CANDIDAT, pool);

        assertThat(reste).isEmpty();
        verifyNoInteractions(fitScores, resolver, writer);
    }

    @Test
    void failOpen_uneExceptionDuCalculNeRemonteJamais() {
        List<JobOffer> pool = offres(3);
        toutesEligibles(pool);
        when(writer.computeAndPersist(any())).thenThrow(new IllegalStateException("base indisponible"));

        var computer = computer(true, 800, 200);

        // Ne doit pas lever : la liste s'affiche sans les notes manquantes.
        var reste = computer.ensureScored(CANDIDAT, pool);

        assertThat(reste).isEmpty();
        assertThat(meters.get("fitscore.inline.failures").counter().count()).isEqualTo(1.0);
    }

    @Test
    void failOpen_uneExceptionDeLaLectureNeRemonteJamaisNonPlus() {
        List<JobOffer> pool = offres(3);
        when(fitScores.findByPairs(any())).thenThrow(new IllegalStateException("timeout"));

        var reste = computer(true, 800, 200).ensureScored(CANDIDAT, pool);

        assertThat(reste).isEmpty();
        assertThat(meters.get("fitscore.inline.failures").counter().count()).isEqualTo(1.0);
    }

    @Test
    void poolVideNeDeclencheAucuneRequete() {
        var reste = computer(true, 800, 200).ensureScored(CANDIDAT, List.of());

        assertThat(reste).isEmpty();
        verifyNoInteractions(fitScores, resolver, writer);
    }

    @Test
    void lesPairesCalculeesSontComptees() {
        List<JobOffer> pool = offres(3);
        toutesEligibles(pool);

        computer(true, 800, 200).ensureScored(CANDIDAT, pool);

        assertThat(meters.get("fitscore.inline.pairs").counter().count()).isEqualTo(3.0);
    }
}
