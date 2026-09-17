package com.zennyt.analytics.application;

import com.zennyt.analytics.domain.repository.AnalyticsReadRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Agrégats des tableaux de bord, lus depuis le read-model alimenté par les
 * Domain Events.
 *
 * <p><b>Décision produit (à valider)</b> — une « candidature » est un swipe
 * RIGHT du candidat (intérêt exprimé) : l'entité {@code Application} n'existe
 * plus depuis la refonte squad web (V34). Les vues de profil/offre et le taux de
 * réponse ne sont pas encore instrumentés : ils sont renvoyés à zéro plutôt
 * qu'inventés.
 */
@Service
@Transactional(readOnly = true)
public class AnalyticsQueryService {

    private static final String INTERESTED = "INTERESTED";
    private static final String MATCHED = "MATCHED";
    private static final String TEST_COMPLETED = "TEST_COMPLETED";

    private final AnalyticsReadRepository read;

    public AnalyticsQueryService(AnalyticsReadRepository read) {
        this.read = read;
    }

    public record CandidateInsights(int profileViews, int profileViewsLast30Days,
                                    int applicationsSubmitted, Map<String, Integer> applicationsByStatus,
                                    int profileCompleteness) {}

    public record RecruiterStats(int jobsPosted, int activeJobs, int totalApplications,
                                 Double avgResponseTimeHours, Double responseRate) {}

    public record JobStats(UUID jobId, int views, int applications, Double conversionRate,
                           List<ViewPoint> viewsTimeline) {
        public record ViewPoint(LocalDate date, int count) {}
    }

    public CandidateInsights candidateInsights(UUID candidateId) {
        Map<String, Long> byKind = read.candidateActivityByKind(candidateId);
        int interested = intOf(byKind.get(INTERESTED));
        Map<String, Integer> byStatus = new LinkedHashMap<>();
        byStatus.put(INTERESTED, interested);
        byStatus.put(MATCHED, intOf(byKind.get(MATCHED)));
        byStatus.put(TEST_COMPLETED, intOf(byKind.get(TEST_COMPLETED)));
        return new CandidateInsights(0, 0, interested, byStatus, 0);
    }

    public RecruiterStats recruiterStats(UUID recruiterId) {
        return new RecruiterStats(
            (int) read.countOffersByRecruiter(recruiterId),
            (int) read.countActiveOffersByRecruiter(recruiterId),
            (int) read.countApplicationsForRecruiter(recruiterId),
            null, null);
    }

    /**
     * Stats d'une offre, réservées à son recruteur propriétaire : une offre
     * inconnue ou appartenant à un tiers est un 404 (on ne révèle pas
     * l'existence d'une offre à un tiers — contrat §GET /jobs/{jobId}).
     */
    public JobStats jobStats(UUID callerId, UUID jobId) {
        UUID ownerId = read.findRecruiterIdForOffer(jobId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!ownerId.equals(callerId)) {
            throw new NotFoundException("Offre introuvable");
        }
        int applications = (int) read.countApplicationsForOffer(jobId);
        return new JobStats(jobId, 0, applications, null, List.of());
    }

    private static int intOf(Long value) {
        return value == null ? 0 : Math.toIntExact(value);
    }
}
