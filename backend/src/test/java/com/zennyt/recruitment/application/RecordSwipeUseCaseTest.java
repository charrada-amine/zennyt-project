package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecordSwipeUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Tests du cas d'usage de swipe — centrés sur la détection de match mutuel.
 *
 * <p>Le {@link SwipeRepository} est un faux en mémoire (et non un mock) afin que le
 * test prouve réellement l'appariement entre deux swipes opposés : un Match n'est
 * créé que lorsque les DEUX côtés ont swipé LIKE sur la même paire
 * {@code (candidateId, jobOfferId)}, et jamais sur un seul swipe.
 */
class RecordSwipeUseCaseTest {

    private static final UUID RECRUITER = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID CANDIDATE = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID OFFER = UUID.fromString("a0000000-0000-0000-0000-000000000001");

    private InMemorySwipeRepository swipeRepository;
    private MatchRepository matchRepository;
    private JobOfferRepository jobOfferRepository;
    private ApplicationEventPublisher eventPublisher;
    private RecordSwipeUseCase useCase;

    @BeforeEach
    void setUp() {
        swipeRepository = new InMemorySwipeRepository();
        matchRepository = mock(MatchRepository.class);
        when(matchRepository.save(any(Match.class))).thenAnswer(inv -> inv.getArgument(0));
        jobOfferRepository = mock(JobOfferRepository.class);
        when(jobOfferRepository.findById(OFFER)).thenReturn(Optional.of(offer()));
        eventPublisher = mock(ApplicationEventPublisher.class);
        useCase = new RecordSwipeUseCase(swipeRepository, matchRepository, jobOfferRepository, eventPublisher);
    }

    @Test
    void singleCandidateLike_doesNotCreateMatch() {
        var result = useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);

        assertNull(result.match(), "Un seul swipe (candidat) ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void singleRecruiterLike_doesNotCreateMatch() {
        var result = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);

        assertNull(result.match(), "Un seul swipe (recruteur) ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void bothSidesLike_createsMatchOnSecondSwipe() {
        // 1) Le candidat swipe LIKE sur l'offre → pas encore de match.
        var first = useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);
        assertNull(first.match());

        // 2) Le recruteur swipe LIKE sur le candidat pour la même offre → match !
        var second = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);

        assertNotNull(second.match(), "Le second swipe opposé doit créer le match mutuel");
        assertEquals(CANDIDATE, second.match().candidateId());
        assertEquals(OFFER, second.match().jobOfferId());
        assertEquals(RECRUITER, second.match().recruiterId());
        verify(matchRepository, times(1)).save(any(Match.class));
    }

    @Test
    void bothSidesLike_recruiterFirst_createsMatchOnSecondSwipe() {
        var first = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);
        assertNull(first.match());

        var second = useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);

        assertNotNull(second.match());
        assertEquals(CANDIDATE, second.match().candidateId());
        assertEquals(OFFER, second.match().jobOfferId());
        assertEquals(RECRUITER, second.match().recruiterId());
        verify(matchRepository, times(1)).save(any(Match.class));
    }

    @Test
    void likesOnDifferentOffers_doNotMatch() {
        UUID otherOffer = UUID.fromString("a0000000-0000-0000-0000-000000000002");
        when(jobOfferRepository.findById(otherOffer)).thenReturn(Optional.of(offer()));

        // Candidat aime l'offre OFFER, recruteur aime le candidat mais pour une AUTRE offre.
        useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);
        var second = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, otherOffer, SwipeDirection.LIKE);

        assertNull(second.match(), "Des LIKE sur des offres différentes ne doivent pas matcher");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void candidateLikeThenRecruiterPass_doesNotMatch() {
        useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);
        var second = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.PASS);

        assertNull(second.match(), "Un PASS du côté opposé ne doit pas créer de match");
        verify(matchRepository, never()).save(any());
    }

    @Test
    void recruiterSwipeWithoutJobOffer_isRejected() {
        assertThrows(IllegalArgumentException.class, () ->
            useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, null, SwipeDirection.LIKE));
    }

    @Test
    void recruiterCanSwipeSameCandidateForDifferentOffers() {
        UUID otherOffer = UUID.fromString("a0000000-0000-0000-0000-000000000002");
        when(jobOfferRepository.findById(otherOffer)).thenReturn(Optional.of(offer()));

        useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);

        // Même candidat mais autre offre → pas de doublon, donc autorisé.
        assertDoesNotThrow(() ->
            useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, otherOffer, SwipeDirection.LIKE));
    }

    @Test
    void sameActorSameCandidateSameOffer_sameDirection_isIdempotent() {
        var first = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);
        var second = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);

        assertEquals(first.swipe().id(), second.swipe().id(),
            "Re-swiper dans la même direction doit renvoyer le swipe existant, pas en créer un second");
        assertEquals(1, swipeRepository.count(RECRUITER, CANDIDATE, OFFER));
    }

    @Test
    void reSwipeWithNewDirection_replacesSwipeAndCleansOrphanMatch() {
        // Match mutuel créé…
        useCase.execute(CANDIDATE, OFFER, Swipe.TARGET_JOB_OFFER, null, SwipeDirection.LIKE);
        var matched = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.LIKE);
        assertNotNull(matched.match());
        when(matchRepository.findByCandidateIdAndJobOfferId(CANDIDATE, OFFER))
            .thenReturn(Optional.of(matched.match()));

        // …puis le recruteur change d'avis : PASS remplace le LIKE et le match est supprimé.
        var reversed = useCase.execute(RECRUITER, CANDIDATE, Swipe.TARGET_CANDIDATE, OFFER, SwipeDirection.PASS);

        assertNull(reversed.match());
        assertEquals(SwipeDirection.PASS, reversed.swipe().direction());
        assertEquals(1, swipeRepository.count(RECRUITER, CANDIDATE, OFFER));
        verify(matchRepository).deleteById(matched.match().id());
    }

    private JobOffer offer() {
        return JobOffer.rehydrate(OFFER, RECRUITER, null, "Senior Backend Engineer", "Zennyt Inc.",
            new Location("Tunis", "TN", true), new SalaryRange(40000, 70000, "EUR"),
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR, "Software",
            "desc", "resp", "min", "pref", "offer", "apply", "info",
            null, false, JobOfferStatus.ACTIVE, Instant.now());
    }

    /**
     * Faux repository en mémoire reproduisant la sémantique de l'adapter JPA :
     * {@code findMutualLike} apparie sur {@code (candidateId, jobOfferId, targetType, direction)}.
     */
    private static class InMemorySwipeRepository implements SwipeRepository {
        private final List<Swipe> store = new ArrayList<>();

        @Override public Swipe save(Swipe swipe) {
            store.add(swipe);
            return swipe;
        }

        @Override public boolean existsByActorIdAndCandidateIdAndJobOfferId(UUID actorId, UUID candidateId, UUID jobOfferId) {
            return store.stream().anyMatch(s ->
                s.actorId().equals(actorId)
                    && s.candidateId().equals(candidateId)
                    && s.jobOfferId().equals(jobOfferId));
        }

        @Override public Optional<Swipe> findById(UUID id) {
            return store.stream().filter(s -> s.id().equals(id)).findFirst();
        }

        @Override public Optional<Swipe> findByActorAndPair(UUID actorId, UUID candidateId, UUID jobOfferId) {
            return store.stream()
                .filter(s -> s.actorId().equals(actorId)
                    && s.candidateId().equals(candidateId)
                    && s.jobOfferId().equals(jobOfferId))
                .findFirst();
        }

        @Override public void deleteById(UUID id) {
            store.removeIf(s -> s.id().equals(id));
        }

        @Override public List<UUID> findTargetIdsByActorId(UUID actorId, UUID jobOfferId) {
            return store.stream()
                .filter(s -> s.actorId().equals(actorId)
                    && (jobOfferId == null || s.jobOfferId().equals(jobOfferId)))
                .map(Swipe::targetId)
                .toList();
        }

        long count(UUID actorId, UUID candidateId, UUID jobOfferId) {
            return store.stream().filter(s -> s.actorId().equals(actorId)
                && s.candidateId().equals(candidateId)
                && s.jobOfferId().equals(jobOfferId)).count();
        }

        @Override public Optional<Swipe> findMutualLike(UUID candidateId, UUID jobOfferId,
                                                        String mutualTargetType, SwipeDirection direction) {
            return store.stream()
                .filter(s -> s.candidateId().equals(candidateId)
                    && s.jobOfferId().equals(jobOfferId)
                    && s.targetType().equals(mutualTargetType)
                    && s.direction() == direction)
                .findFirst();
        }
    }
}
