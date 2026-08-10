package com.zennyt.recruitment.api;

import com.zennyt.recruitment.application.JobRoleProfileResolver;
import com.zennyt.recruitment.application.usecase.ChangeJobOfferStatusUseCase;
import com.zennyt.recruitment.application.usecase.CreateJobOfferUseCase;
import com.zennyt.recruitment.application.usecase.GetSwipeDeckUseCase;
import com.zennyt.recruitment.application.usecase.ReplaceJobOfferUseCase;
import com.zennyt.recruitment.application.usecase.UpdateJobOfferUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * F20 (FITSCORE_REMEDIATION.md §3 index F20) — {@code toSummaries} appelait
 * auparavant {@code actors.findById} et {@code roleProfileResolver.resolve}
 * une fois par offre (3 requêtes/offre, ~60 sur une page de 20). Ce test
 * verrouille l'usage des variantes par lot pour empêcher une régression
 * silencieuse vers le N+1.
 */
class JobOfferControllerSummaryTest {

    private final JobOfferRepository jobOfferRepository = mock(JobOfferRepository.class);
    private final RecruitmentActorRepository actors = mock(RecruitmentActorRepository.class);
    private final JobRoleProfileResolver roleProfileResolver = mock(JobRoleProfileResolver.class);

    private final JobOfferController controller = new JobOfferController(
        mock(CreateJobOfferUseCase.class), mock(ReplaceJobOfferUseCase.class), mock(UpdateJobOfferUseCase.class),
        mock(ChangeJobOfferStatusUseCase.class), jobOfferRepository, mock(SwipeRepository.class),
        mock(AssessmentRepository.class), mock(FitScoreRepository.class), mock(GetSwipeDeckUseCase.class),
        actors, roleProfileResolver);

    @Test
    void listingOffersBatchesActorsAndRoleProfilesInsteadOfPerOfferCalls() {
        UUID recruiterA = UUID.randomUUID();
        UUID recruiterB = UUID.randomUUID();
        UUID offer1Id = UUID.randomUUID();
        UUID offer2Id = UUID.randomUUID();
        JobOffer offer1 = offerOwnedBy(offer1Id, recruiterA);
        JobOffer offer2 = offerOwnedBy(offer2Id, recruiterB);
        when(jobOfferRepository.findByRecruiterId(any(), any(), any(), anyInt(), anyInt()))
            .thenReturn(List.of(offer1, offer2));
        when(jobOfferRepository.countByRecruiterId(any(), any())).thenReturn(2L);
        when(actors.findByIds(anyList())).thenReturn(List.of(
            actorNamed(recruiterA, "Acme"), actorNamed(recruiterB, "Globex")));
        JobRoleProfile profile = roleProfile();
        Map<UUID, JobRoleProfile> resolved = Map.of(offer1Id, profile);
        when(roleProfileResolver.resolveAll(anyList())).thenReturn(resolved);

        var response = controller.myOffers(null, null, 0, 20,
            () -> recruiterA.toString());

        assertThat(response.getBody().content()).hasSize(2);
        // Batch variants called exactly once for the whole page...
        verify(actors, times(1)).findByIds(anyList());
        verify(roleProfileResolver, times(1)).resolveAll(anyList());
        // ...and the per-offer variants never called at all.
        verify(actors, never()).findById(any());
        verify(roleProfileResolver, never()).resolve(any());
    }

    private static JobOffer offerOwnedBy(UUID id, UUID recruiterId) {
        JobOffer offer = mock(JobOffer.class);
        when(offer.id()).thenReturn(id);
        when(offer.recruiterId()).thenReturn(recruiterId);
        when(offer.assessmentId()).thenReturn(null);
        when(offer.postedAt()).thenReturn(Instant.now());
        return offer;
    }

    private static RecruitmentActor actorNamed(UUID publicUserId, String companyName) {
        return new RecruitmentActor(publicUserId, "RECRUITER", true, "Jane Doe", null,
            null, null, companyName, null, null, null, null, null, null, null, null, null, null);
    }

    private static JobRoleProfile roleProfile() {
        return new JobRoleProfile(JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR,
            35, 65, 65, 30, 20, 30, 15, 5, false, Instant.now());
    }
}
