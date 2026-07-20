package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.SendOpportunityOfferUseCase;
import com.zennyt.recruitment.domain.event.JobOpportunityOfferSentEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garde-fous du sourcing (cadrage 16/07, révisé 20/07 : candidature APPROVED
 * ou Match ACTIVE désormais exigé) : destinataire = acteur candidat actif
 * connu, offre du recruteur appelant, événements publiés après persistance.
 */
class SendOpportunityOfferUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID INTRUS = UUID.randomUUID();
    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID OFFER_ID = UUID.randomUUID();

    private JobOpportunityOfferRepository repository;
    private JobOfferRepository offers;
    private RecruitmentActorRepository actors;
    private ApplicationRepository applications;
    private MatchRepository matches;
    private ApplicationEventPublisher events;
    private SendOpportunityOfferUseCase useCase;

    @BeforeEach
    void setUp() {
        repository = mock(JobOpportunityOfferRepository.class);
        offers = mock(JobOfferRepository.class);
        actors = mock(RecruitmentActorRepository.class);
        applications = mock(ApplicationRepository.class);
        matches = mock(MatchRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SendOpportunityOfferUseCase(repository, offers, actors, applications, matches, events);

        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(
            new RecruitmentActor(CANDIDATE, "CANDIDATE", true, null, null, null, null, Instant.now(), UUID.randomUUID())));
        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(RECRUITER);
        when(offers.findById(OFFER_ID)).thenReturn(Optional.of(offer));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(applications.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.empty());
        when(matches.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.empty());
    }

    private Application approvedApplication() {
        return Application.rehydrate(UUID.randomUUID(), CANDIDATE, OFFER_ID,
            ApplicationStatus.APPROVED, Instant.now(), Instant.now());
    }

    @Test
    void envoiAutoriseAvecCandidatureApprouvee() {
        when(applications.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID))
            .thenReturn(Optional.of(approvedApplication()));

        JobOpportunityOffer result = useCase.execute(RECRUITER, CANDIDATE, OFFER_ID);
        assertThat(result.candidateId()).isEqualTo(CANDIDATE);
        verify(events).publishEvent(any(JobOpportunityOfferSentEvent.class));
    }

    @Test
    void envoiAutoriseAvecMatchActif() {
        Match match = Match.rehydrate(UUID.randomUUID(), CANDIDATE, OFFER_ID, RECRUITER,
            "Titre", com.zennyt.recruitment.domain.vo.MatchStatus.ACTIVE, Instant.now());
        when(matches.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID)).thenReturn(Optional.of(match));

        JobOpportunityOffer result = useCase.execute(RECRUITER, CANDIDATE, OFFER_ID);
        assertThat(result.candidateId()).isEqualTo(CANDIDATE);
    }

    @Test
    void envoiRefuseSansCandidatureNiMatch() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER, CANDIDATE, OFFER_ID))
            .isInstanceOf(ForbiddenException.class);
        verify(repository, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    @Test
    void candidatInconnuRefuse() {
        UUID ghost = UUID.randomUUID();
        when(actors.findById(ghost)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> useCase.execute(RECRUITER, ghost, OFFER_ID))
            .isInstanceOf(NotFoundException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void candidatDesactiveRefuse() {
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(
            new RecruitmentActor(CANDIDATE, "CANDIDATE", false, null, null, null, null, Instant.now(), UUID.randomUUID())));
        assertThatThrownBy(() -> useCase.execute(RECRUITER, CANDIDATE, OFFER_ID))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void cibleRecruteurRefusee() {
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(
            new RecruitmentActor(CANDIDATE, "RECRUITER", true, null, null, null, null, Instant.now(), UUID.randomUUID())));
        assertThatThrownBy(() -> useCase.execute(RECRUITER, CANDIDATE, OFFER_ID))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void offreDUnAutreRecruteurRefusee() {
        when(applications.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER_ID))
            .thenReturn(Optional.of(approvedApplication()));
        assertThatThrownBy(() -> useCase.execute(INTRUS, CANDIDATE, OFFER_ID))
            .isInstanceOf(ForbiddenException.class);
        verify(repository, never()).save(any());
        verify(events, never()).publishEvent(any());
    }
}
