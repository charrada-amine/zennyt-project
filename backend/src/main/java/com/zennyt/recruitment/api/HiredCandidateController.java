package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.CancelHireUseCase;
import com.zennyt.recruitment.application.usecase.ListHiredCandidatesUseCase;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Recrutements confirmés du recruteur (maquette 258 « Hired Candidates ») :
 * liste + annulation tant que la période d'essai court.
 */
@RestController
@RequestMapping("/api/v1")
public class HiredCandidateController {

    private final ListHiredCandidatesUseCase listHiredCandidates;
    private final CancelHireUseCase cancelHire;
    private final RecruitmentActorRepository actors;

    public HiredCandidateController(ListHiredCandidatesUseCase listHiredCandidates,
                                    CancelHireUseCase cancelHire,
                                    RecruitmentActorRepository actors) {
        this.listHiredCandidates = listHiredCandidates;
        this.cancelHire = cancelHire;
        this.actors = actors;
    }

    record HiredCandidateResponse(UUID id, UUID candidateId, String fullName, String avatarUrl,
                                  String title, Double salaryMin, Double salaryMax, String salaryCurrency,
                                  String status, Instant hiredAt, Instant probationEndsAt,
                                  Long daysRemaining, boolean cancellable) {
        static HiredCandidateResponse from(JobOpportunityOffer offer, String fullName,
                                           String avatarUrl, Instant now) {
            Instant probationEndsAt = offer.respondedAt() == null ? null : offer.probationEndsAt();
            Long daysRemaining = probationEndsAt == null ? null
                : Math.max(0, Duration.between(now, probationEndsAt).toDays());
            boolean cancellable = offer.status() == JobOpportunityStatus.CONFIRMED
                && (probationEndsAt == null || now.isBefore(probationEndsAt));
            var salary = offer.salary();
            return new HiredCandidateResponse(offer.id(), offer.candidateId(), fullName, avatarUrl,
                offer.title(),
                salary == null ? null : salary.min(),
                salary == null ? null : salary.max(),
                salary == null ? null : salary.currency(),
                offer.status().name(), offer.respondedAt(), probationEndsAt, daysRemaining,
                cancellable);
        }
    }

    @GetMapping("/recruiters/me/hired-candidates")
    @RecruiterOnly
    public List<HiredCandidateResponse> list(Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Instant now = Instant.now();
        return listHiredCandidates.execute(recruiterId).stream()
            .map(offer -> {
                var actor = actors.findById(offer.candidateId());
                return HiredCandidateResponse.from(offer,
                    actor.map(a -> a.fullName()).orElse(null),
                    actor.map(a -> a.avatarUrl()).orElse(null), now);
            })
            .toList();
    }

    @PostMapping("/hired-candidates/{id}/cancel")
    @RecruiterOnly
    public HiredCandidateResponse cancel(@PathVariable UUID id, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOpportunityOffer cancelled = cancelHire.execute(recruiterId, id);
        var actor = actors.findById(cancelled.candidateId());
        return HiredCandidateResponse.from(cancelled,
            actor.map(a -> a.fullName()).orElse(null),
            actor.map(a -> a.avatarUrl()).orElse(null), Instant.now());
    }
}
