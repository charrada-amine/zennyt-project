package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecordSwipeUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Tests du cas d'usage de swipe (contrat squad web §5) — centrés sur la
 * détection de match mutuel et les règles "pas de réécriture silencieuse".
 *
 * <p>Le {@link SwipeRepository} est un faux en mémoire (et non un mock) afin
 * que le test prouve réellement l'appariement entre deux swipes opposés : un
 * Match n'est créé que lorsque les DEUX côtés ont swipé RIGHT sur la même
 * paire {@code (jobOfferId, candidateId)}, et jamais sur un seul swipe.
 */
class RecordSwipeUseCaseTest {

    private static final UUID RECRUITER = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID CANDIDATE = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID OFFER = UUID.fromString("a0000000-0000-0000-0000-000000000001");

    private InMemorySwipeRepository swipeRepository;
    private MatchRepository matchRepository;
    private JobOfferRepository jobOfferRepository;
    private RecruitmentActorRepository actors;
    private ApplicationEventPublisher eventPublisher;
    private RecordSwipeUseCase useCase;

    @BeforeEach
    void setUp() {
        swipeRepository = new InMemorySwipeRepository();
        matchRepository = mock(MatchRepository.class);
        when(matchRepository.save(any(Match.class))).thenAnswer(inv -> inv.getArgument(0));
        when(matchRepository.findByCandidateIdAndJobOfferId(any(), any())).thenReturn(Optional.empty());
        jobOfferRepository = mock(JobOfferRepository.class);
        when(jobOfferRepository.findById(OFFER)).thenReturn(Optional.of(offer(OFFER)));
        actors = mock(RecruitmentActorRepository.class);
        when(actors.findById(CANDIDATE)).thenReturn(Optional.of(
            new RecruitmentActor(CANDIDATE, "CANDIDATE", true, null, null, null, null, null, null,
                null, null, null, null, null, null, null, Instant.now(), UUID.randomUUID())));
        eventPublisher = mock(ApplicationEventPublisher.class);
        useCase = new RecordSwipeUseCase(swipeRepository, matchRepository, jobOfferRepository, actors, eventPublisher);
    }

    @Test
    void singleCandidateRight_doesNotCreateMatch() {
        var result = useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT);

        assertNull(result.match(), "Un seul swipe (candidat) ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void singleRecruiterRight_doesNotCreateMatch() {
        var result = useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);

        assertNull(result.match(), "Un seul swipe (recruteur) ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void bothSidesRight_createsMatchOnSecondSwipe() {
        var first = useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT);
        assertNull(first.match());

        var second = useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);

        assertNotNull(second.match(), "Le second swipe opposé doit créer le match mutuel");
        assertEquals(CANDIDATE, second.match().candidateId());
        assertEquals(OFFER, second.match().jobOfferId());
        assertEquals(RECRUITER, second.match().recruiterId());
        verify(matchRepository, times(1)).save(any(Match.class));
    }

    @Test
    void bothSidesRight_recruiterFirst_createsMatchOnSecondSwipe() {
        var first = useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);
        assertNull(first.match());

        var second = useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT);

        assertNotNull(second.match());
        assertEquals(CANDIDATE, second.match().candidateId());
        assertEquals(OFFER, second.match().jobOfferId());
        assertEquals(RECRUITER, second.match().recruiterId());
        verify(matchRepository, times(1)).save(any(Match.class));
    }

    @Test
    void rightsOnDifferentOffers_doNotMatch() {
        UUID otherOffer = UUID.fromString("a0000000-0000-0000-0000-000000000002");
        when(jobOfferRepository.findById(otherOffer)).thenReturn(Optional.of(offer(otherOffer)));

        useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT);
        var second = useCase.execute(RECRUITER, otherOffer, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);

        assertNull(second.match(), "Des RIGHT sur des offres différentes ne doivent pas matcher");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void candidateRightThenRecruiterLeft_doesNotMatch() {
        useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT);
        var second = useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.LEFT);

        assertNull(second.match(), "Un LEFT du côté opposé ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void recruiterSwipeOnUnknownCandidate_isRejected() {
        when(actors.findById(CANDIDATE)).thenReturn(Optional.empty());
        assertThrows(NotFoundException.class, () ->
            useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT));
    }

    @Test
    void recruiterSwipeOnOfferTheyDontOwn_isForbidden() {
        UUID intruder = UUID.fromString("33333333-3333-3333-3333-333333333333");
        assertThrows(ForbiddenException.class, () ->
            useCase.execute(intruder, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT));
    }

    @Test
    void recruiterCanSwipeSameCandidateForDifferentOffers() {
        UUID otherOffer = UUID.fromString("a0000000-0000-0000-0000-000000000002");
        when(jobOfferRepository.findById(otherOffer)).thenReturn(Optional.of(offer(otherOffer)));

        useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);

        assertDoesNotThrow(() ->
            useCase.execute(RECRUITER, otherOffer, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT));
    }

    @Test
    void reSwipingSameSide_isRejectedWithConflict() {
        useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT);

        assertThrows(ConflictException.class, () ->
            useCase.execute(RECRUITER, OFFER, CANDIDATE, SwipeSide.RECRUITER, SwipeDirection.RIGHT),
            "Re-swiper sans annuler d'abord doit être rejeté (pas de réécriture silencieuse)");
        assertEquals(1, swipeRepository.count(OFFER, CANDIDATE, SwipeSide.RECRUITER));
    }

    @Test
    void swipeOnAlreadyMatchedPair_isRejectedWithConflict() {
        Match existing = Match.rehydrate(UUID.randomUUID(), CANDIDATE, OFFER, RECRUITER, Instant.now());
        when(matchRepository.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER)).thenReturn(Optional.of(existing));

        assertThrows(ConflictException.class, () ->
            useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT));
    }

    @Test
    void swipeOnInactiveOffer_isRejectedWithConflict() {
        Instant now = Instant.now();
        JobOffer draftOffer = JobOffer.rehydrate(OFFER, RECRUITER, null, "Senior Backend Engineer",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.MID,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, null, false, JobOfferStatus.DRAFT, now, now);
        when(jobOfferRepository.findById(OFFER)).thenReturn(Optional.of(draftOffer));

        assertThrows(ConflictException.class, () ->
            useCase.execute(CANDIDATE, OFFER, CANDIDATE, SwipeSide.CANDIDATE, SwipeDirection.RIGHT));
    }

    private JobOffer offer(UUID id) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(id, RECRUITER, null, "Senior Backend Engineer",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.MID,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, null, false, JobOfferStatus.ACTIVE, now, now);
    }

    /** Faux repository en mémoire reproduisant la sémantique de l'adapter JPA. */
    private static class InMemorySwipeRepository implements SwipeRepository {
        private final Map<String, Swipe> store = new HashMap<>();

        private static String key(UUID jobOfferId, UUID candidateId, SwipeSide side) {
            return jobOfferId + "|" + candidateId + "|" + side;
        }

        @Override public Swipe save(Swipe swipe) {
            store.put(key(swipe.jobOfferId(), swipe.candidateId(), swipe.side()), swipe);
            return swipe;
        }

        @Override public Optional<Swipe> find(UUID jobOfferId, UUID candidateId, SwipeSide side) {
            return Optional.ofNullable(store.get(key(jobOfferId, candidateId, side)));
        }

        @Override public void delete(UUID jobOfferId, UUID candidateId, SwipeSide side) {
            store.remove(key(jobOfferId, candidateId, side));
        }

        @Override public Map<UUID, Long> countRightByJobOfferIds(java.util.List<UUID> jobOfferIds) {
            return Map.of();
        }

        long count(UUID jobOfferId, UUID candidateId, SwipeSide side) {
            return store.containsKey(key(jobOfferId, candidateId, side)) ? 1 : 0;
        }
    }
}
