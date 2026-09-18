package com.zennyt.analytics.application;

import com.zennyt.analytics.domain.repository.AnalyticsReadRepository;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AnalyticsQueryServiceTest {

    private static final UUID CANDIDATE = UUID.randomUUID();
    private static final UUID RECRUITER = UUID.randomUUID();
    private static final UUID OFFER = UUID.randomUUID();

    private final AnalyticsReadRepository read = mock(AnalyticsReadRepository.class);
    private final AnalyticsQueryService service = new AnalyticsQueryService(read);

    @Test
    void candidateApplicationsAreInterestedSwipesAndStatusesAreComplete() {
        when(read.candidateActivityByKind(CANDIDATE))
            .thenReturn(Map.of("INTERESTED", 3L, "MATCHED", 1L, "TEST_COMPLETED", 2L));

        var insights = service.candidateInsights(CANDIDATE);

        assertThat(insights.applicationsSubmitted()).isEqualTo(3);
        assertThat(insights.applicationsByStatus())
            .containsEntry("INTERESTED", 3)
            .containsEntry("MATCHED", 1)
            .containsEntry("TEST_COMPLETED", 2);
        // Not instrumented yet: zeroed rather than invented.
        assertThat(insights.profileViews()).isZero();
        assertThat(insights.profileCompleteness()).isZero();
    }

    @Test
    void missingActivityKindsDefaultToZero() {
        when(read.candidateActivityByKind(CANDIDATE)).thenReturn(Map.of());

        var insights = service.candidateInsights(CANDIDATE);

        assertThat(insights.applicationsSubmitted()).isZero();
        assertThat(insights.applicationsByStatus())
            .containsEntry("INTERESTED", 0)
            .containsEntry("MATCHED", 0)
            .containsEntry("TEST_COMPLETED", 0);
    }

    @Test
    void recruiterStatsAggregateOffersAndApplications() {
        when(read.countOffersByRecruiter(RECRUITER)).thenReturn(5L);
        when(read.countActiveOffersByRecruiter(RECRUITER)).thenReturn(3L);
        when(read.countApplicationsForRecruiter(RECRUITER)).thenReturn(12L);

        var stats = service.recruiterStats(RECRUITER);

        assertThat(stats.jobsPosted()).isEqualTo(5);
        assertThat(stats.activeJobs()).isEqualTo(3);
        assertThat(stats.totalApplications()).isEqualTo(12);
        assertThat(stats.avgResponseTimeHours()).isNull();
        assertThat(stats.responseRate()).isNull();
    }

    @Test
    void jobStatsCountApplicationsAndLeaveUntrackedViewsAtZero() {
        when(read.findRecruiterIdForOffer(OFFER)).thenReturn(java.util.Optional.of(RECRUITER));
        when(read.countApplicationsForOffer(OFFER)).thenReturn(7L);

        var stats = service.jobStats(RECRUITER, OFFER);

        assertThat(stats.applications()).isEqualTo(7);
        assertThat(stats.views()).isZero();
        assertThat(stats.conversionRate()).isNull();
        assertThat(stats.viewsTimeline()).isEmpty();
    }

    @Test
    void jobStatsOfAnotherRecruiterAreNotFound() {
        when(read.findRecruiterIdForOffer(OFFER)).thenReturn(java.util.Optional.of(UUID.randomUUID()));

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.jobStats(RECRUITER, OFFER))
            .isInstanceOf(com.zennyt.shared.application.exception.NotFoundException.class);
    }

    @Test
    void unknownJobIsNotFound() {
        when(read.findRecruiterIdForOffer(OFFER)).thenReturn(java.util.Optional.empty());

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.jobStats(RECRUITER, OFFER))
            .isInstanceOf(com.zennyt.shared.application.exception.NotFoundException.class);
    }
}
