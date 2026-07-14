package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.vo.*;

import java.time.Instant;
import java.util.UUID;

/** DTO de réponse pour une offre d'emploi (noms alignés sur le contrat frontend). */
public record JobOfferResponse(
    UUID id, UUID recruiterId, String title, String companyName,
    String city, String country, boolean remote,
    Double salaryMin, Double salaryMax, String currency,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    String fieldOfWork, String description, String responsibilities,
    String minimumQualifications, String preferredQualifications,
    String whatWeOffer, String howToApply, String companyInfo,
    UUID assessmentId, boolean openToInternational,
    JobOfferStatus status, Instant postedAt
) {
    public static JobOfferResponse from(JobOffer o) {
        return new JobOfferResponse(
            o.id(), o.recruiterId(), o.title(), o.companyName(),
            o.location() != null ? o.location().city() : null,
            o.location() != null ? o.location().country() : null,
            o.location() != null && o.location().remote(),
            o.salary() != null ? o.salary().min() : null,
            o.salary() != null ? o.salary().max() : null,
            o.salary() != null ? o.salary().currency() : null,
            o.contractType(), o.workplaceType(), o.experienceLevel(),
            o.fieldOfWork(), o.description(), o.responsibilities(),
            o.minimumQualifications(), o.preferredQualifications(),
            o.whatWeOffer(), o.howToApply(), o.companyInfo(),
            o.assessmentId(), o.openToInternational(),
            o.status(), o.postedAt()
        );
    }
}
