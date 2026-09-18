package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.JobOfferResponse;
import com.zennyt.recruitment.api.dto.JobOfferResponse.MyApplication;
import com.zennyt.recruitment.application.JobRoleProfileResolver;
import com.zennyt.recruitment.application.usecase.ChangeJobOfferStatusUseCase;
import com.zennyt.recruitment.application.usecase.CreateJobOfferUseCase;
import com.zennyt.recruitment.application.usecase.GetSwipeDeckUseCase;
import com.zennyt.recruitment.application.usecase.ReplaceJobOfferUseCase;
import com.zennyt.recruitment.application.usecase.UpdateJobOfferUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * « Postuler » depuis le détail d'une offre : le client doit savoir où en est le
 * candidat connecté (rien, postulé, passé, match) sans deviner à partir d'erreurs 409.
 */
class JobOfferMyApplicationTest {

    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER = UUID.randomUUID();

    private final JobOfferRepository offers = mock(JobOfferRepository.class);
    private final SwipeRepository swipes = mock(SwipeRepository.class);
    private final MatchRepository matches = mock(MatchRepository.class);
    private final JobOfferController controller = new JobOfferController(
        mock(CreateJobOfferUseCase.class), mock(ReplaceJobOfferUseCase.class),
        mock(UpdateJobOfferUseCase.class), mock(ChangeJobOfferStatusUseCase.class),
        offers, swipes, mock(AssessmentRepository.class), mock(FitScoreRepository.class),
        mock(GetSwipeDeckUseCase.class), mock(RecruitmentActorRepository.class),
        mock(JobRoleProfileResolver.class), matches);

    {
        Instant now = Instant.now();
        when(offers.findById(OFFER)).thenReturn(Optional.of(JobOffer.rehydrate(
            OFFER, RECRUITER, null, "Développeur Flutter", new Location("Tunis", "TN"),
            1800.0, 2600.0, ContractType.FULL_TIME, WorkplaceType.HYBRID, ExperienceLevel.JUNIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, null, false, JobOfferStatus.ACTIVE, now, now)));
        when(matches.findByCandidateIdAndJobOfferId(any(), any())).thenReturn(Optional.empty());
        when(swipes.find(any(), any(), any())).thenReturn(Optional.empty());
    }

    private static Authentication as(UUID user, String role) {
        return new UsernamePasswordAuthenticationToken(user.toString(), null,
            List.of(new SimpleGrantedAuthority("ROLE_" + role)));
    }

    private MyApplication statusFor(Authentication auth) {
        JobOfferResponse body = controller.getById(OFFER, auth).getBody();
        assertThat(body).isNotNull();
        return body.myApplication();
    }

    private void candidateSwiped(SwipeDirection direction) {
        when(swipes.find(OFFER, CANDIDATE, SwipeSide.CANDIDATE)).thenReturn(Optional.of(
            Swipe.rehydrate(UUID.randomUUID(), OFFER, CANDIDATE, SwipeSide.CANDIDATE, direction,
                Instant.now())));
    }

    @Test
    void candidateWhoHasNotSwiped_seesNone() {
        assertThat(statusFor(as(CANDIDATE, "STUDENT"))).isEqualTo(MyApplication.NONE);
    }

    @Test
    void candidateRightSwipe_isAnApplicationAwaitingTheRecruiter() {
        candidateSwiped(SwipeDirection.RIGHT);
        assertThat(statusFor(as(CANDIDATE, "CANDIDATE"))).isEqualTo(MyApplication.APPLIED);
    }

    @Test
    void candidateLeftSwipe_isPassed() {
        candidateSwiped(SwipeDirection.LEFT);
        assertThat(statusFor(as(CANDIDATE, "STUDENT"))).isEqualTo(MyApplication.PASSED);
    }

    @Test
    void mutualMatch_winsOverTheSwipe() {
        candidateSwiped(SwipeDirection.RIGHT);
        when(matches.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER)).thenReturn(Optional.of(
            Match.rehydrate(UUID.randomUUID(), CANDIDATE, OFFER, RECRUITER, Instant.now())));
        assertThat(statusFor(as(CANDIDATE, "STUDENT"))).isEqualTo(MyApplication.MATCHED);
    }

    @Test
    void recruiterAndAnonymousVisitors_getNoApplicationState() {
        assertThat(statusFor(as(RECRUITER, "RECRUITER"))).isNull();
        assertThat(statusFor(null)).isNull();
    }
}
