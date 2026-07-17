package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Vue recruteur des candidatures et du meilleur résultat QCM par candidat. */
@Service
@Transactional(readOnly = true)
public class GetOfferApplicationsUseCase {

    public record BestAttempt(int scorePercent, boolean passed,
                              IntegrityStatus integrityStatus, Instant submittedAt) {}
    public record Row(UUID applicationId, UUID candidateId,
                      ApplicationStatus applicationStatus, BestAttempt bestAttempt) {}
    public record Result(long applicantCount, double successRate, List<Row> applications) {}

    private final JobOfferRepository offers;
    private final ApplicationRepository applications;
    private final AssessmentAttemptRepository attempts;

    public GetOfferApplicationsUseCase(JobOfferRepository offers,
                                       ApplicationRepository applications,
                                       AssessmentAttemptRepository attempts) {
        this.offers = offers;
        this.applications = applications;
        this.attempts = attempts;
    }

    public Result execute(UUID jobOfferId, UUID recruiterId, ApplicationStatus status,
                          int page, int size) {
        var offer = offers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }

        List<AssessmentAttempt> allAttempts = attempts.findAllByJobOfferId(jobOfferId);
        Map<UUID, AssessmentAttempt> bestByCandidate = allAttempts.stream()
            .collect(Collectors.toMap(AssessmentAttempt::candidateId, Function.identity(),
                (left, right) -> Comparator
                    .comparingInt(AssessmentAttempt::score)
                    .thenComparing(AssessmentAttempt::submittedAt)
                    .compare(left, right) >= 0 ? left : right));

        List<Application> pageApplications = applications
            .findByJobOfferId(jobOfferId, status, page, size);
        List<Row> rows = pageApplications.stream().map(application -> {
            AssessmentAttempt attempt = bestByCandidate.get(application.candidateId());
            BestAttempt best = attempt == null ? null : new BestAttempt(
                attempt.score(), attempt.passed(), attempt.integrityStatus(), attempt.submittedAt());
            return new Row(application.id(), application.candidateId(), application.status(), best);
        }).toList();

        List<AssessmentAttempt> rateEligible = bestByCandidate.values().stream()
            .filter(attempt -> attempt.integrityStatus() != IntegrityStatus.NOT_VALIDATED)
            .toList();
        long passed = rateEligible.stream().filter(AssessmentAttempt::passed).count();
        double successRate = rateEligible.isEmpty() ? 0.0 : passed * 100.0 / rateEligible.size();
        return new Result(applications.countByJobOfferId(jobOfferId, null), successRate, rows);
    }
}
