package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.vo.*;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO de réponse détail pour une offre d'emploi (contrat squad web, §3.4).
 *
 * <p>{@code companyName}/{@code companyInfo} ne sont plus des champs de
 * l'offre : ils sont joints à la lecture dans l'objet {@code recruiter}
 * (source : projection {@code recruitment.actors}, alimentée par Identity —
 * voir {@code RecruitmentActorRepository}). {@code hiringContactId},
 * {@code jobPositionId}, {@code shareableLink} et le fit score restent
 * présents au-delà de l'exemple minimal du contrat : fonctionnalités déjà en
 * production qui en dépendent. Plus de {@code passingScore} : le seuil de
 * réussite est un taux fixe global désormais (contrat squad web §7.1).
 */
public record JobOfferResponse(
    UUID id, UUID recruiterId, RecruiterSummary recruiter, UUID hiringContactId, String title,
    String city, String country,
    Double salaryMin, Double salaryMax,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    String description, String responsibilities,
    String minimumQualifications, String preferredQualifications,
    String whatWeOffer, String howToApply,
    UUID assessmentId, UUID jobPositionId, String shareableLink, boolean openToInternational,
    JobOfferStatus status, long applicantCount, Integer fitScore, Boolean goodFit,
    Integer softSkillScore, Integer cvMatchScore, Integer hardSkillScore, Boolean partialData,
    HardSkillsAlertLevel hardSkillsAlert, Instant postedAt, Instant updatedAt
) {
    public record RecruiterSummary(UUID id, String companyName, String companyInfo) {}

    public static JobOfferResponse from(JobOffer o) {
        return from(o, 0, null, null, null, null, HardSkillsAlertLevel.NONE);
    }

    public static JobOfferResponse from(JobOffer o, long applicantCount, String shareableLink,
                                        com.zennyt.recruitment.domain.model.FitScore fitScore,
                                        String recruiterCompanyName, String recruiterCompanyInfo,
                                        HardSkillsAlertLevel hardSkillsAlert) {
        return new JobOfferResponse(
            o.id(), o.recruiterId(),
            new RecruiterSummary(o.recruiterId(), recruiterCompanyName, recruiterCompanyInfo),
            o.hiringContactId(), o.title(),
            o.location() != null ? o.location().city() : null,
            o.location() != null ? o.location().country() : null,
            o.salaryMin(), o.salaryMax(),
            o.contractType(), o.workplaceType(), o.experienceLevel(),
            o.description(), o.responsibilities(),
            o.minimumQualifications(), o.preferredQualifications(),
            o.whatWeOffer(), o.howToApply(), o.assessmentId(), o.jobPositionId(),
            shareableLink, o.openToInternational(), o.status(), applicantCount,
            fitScore != null ? fitScore.score() : null,
            fitScore != null ? fitScore.goodFit() : null,
            fitScore != null ? fitScore.softSkillScore() : null,
            fitScore != null ? fitScore.cvMatchScore() : null,
            fitScore != null ? fitScore.hardSkillScore() : null,
            fitScore != null ? fitScore.partialData() : null,
            hardSkillsAlert,
            o.postedAt(), o.updatedAt()
        );
    }
}
