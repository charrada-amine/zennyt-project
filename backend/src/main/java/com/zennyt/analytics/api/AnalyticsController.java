package com.zennyt.analytics.api;

import com.zennyt.analytics.application.AnalyticsQueryService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Tableaux de bord Analytics (contrat `analytics.openapi.yaml`). Chaque endpoint
 * ne renvoie que les statistiques de l'appelant (identité lue dans le JWT),
 * jamais d'un tiers.
 */
@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private final AnalyticsQueryService analytics;

    public AnalyticsController(AnalyticsQueryService analytics) {
        this.analytics = analytics;
    }

    record CandidateInsightsResponse(int profileViews, int profileViewsLast30Days,
                                     int applicationsSubmitted, Map<String, Integer> applicationsByStatus,
                                     int profileCompleteness) {}

    record RecruiterStatsResponse(int jobsPosted, int activeJobs, int totalApplications,
                                  Double avgResponseTimeHours, Double responseRate) {}

    record ViewPointResponse(LocalDate date, int count) {}

    record JobStatsResponse(UUID jobId, int views, int applications, Double conversionRate,
                            List<ViewPointResponse> viewsTimeline) {}

    /** Réservé aux candidats/étudiants : le contrat déclare 403 pour les autres rôles. */
    @GetMapping("/candidate/me")
    @PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT')")
    public CandidateInsightsResponse candidateInsights(Authentication authentication) {
        var insights = analytics.candidateInsights(subject(authentication));
        return new CandidateInsightsResponse(insights.profileViews(),
            insights.profileViewsLast30Days(), insights.applicationsSubmitted(),
            insights.applicationsByStatus(), insights.profileCompleteness());
    }

    /** Réservé aux recruteurs : le contrat déclare 403 pour les autres rôles. */
    @GetMapping("/recruiter/me")
    @PreAuthorize("hasRole('RECRUITER')")
    public RecruiterStatsResponse recruiterStats(Authentication authentication) {
        var stats = analytics.recruiterStats(subject(authentication));
        return new RecruiterStatsResponse(stats.jobsPosted(), stats.activeJobs(),
            stats.totalApplications(), stats.avgResponseTimeHours(), stats.responseRate());
    }

    /** Réservé au recruteur propriétaire de l'offre (service : 404 sinon). */
    @GetMapping("/jobs/{jobId}")
    @PreAuthorize("hasRole('RECRUITER')")
    public JobStatsResponse jobStats(@PathVariable UUID jobId, Authentication authentication) {
        var stats = analytics.jobStats(subject(authentication), jobId);
        return new JobStatsResponse(stats.jobId(), stats.views(), stats.applications(),
            stats.conversionRate(),
            stats.viewsTimeline().stream()
                .map(v -> new ViewPointResponse(v.date(), v.count()))
                .toList());
    }

    private static UUID subject(Authentication authentication) {
        return UUID.fromString(((Jwt) authentication.getPrincipal()).getSubject());
    }
}
