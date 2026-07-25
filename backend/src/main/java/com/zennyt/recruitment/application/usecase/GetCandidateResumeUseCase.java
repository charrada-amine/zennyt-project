package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : lire le résumé IA ("Resume AI") d'un candidat pour une offre —
 * combine le résumé soft skills (candidat-level) et le résumé hard skills
 * (par offre). Chaque section a son propre repli statique bilingue quand
 * l'IA n'a encore rien à montrer — voir décision du 20/07.
 */
@Service
@Transactional(readOnly = true)
public class GetCandidateResumeUseCase {

    public static final String HARD_SKILLS_NOT_TESTED_FR =
        "Un test de compétences techniques doit être passé pour cette offre.";
    public static final String HARD_SKILLS_NOT_TESTED_EN =
        "A hard skill test should be taken for this job opportunity.";
    public static final String HARD_SKILLS_PENDING_FR = "Le résumé est en cours de génération…";
    public static final String HARD_SKILLS_PENDING_EN = "The summary is being generated…";
    public static final String SOFT_SKILLS_NOT_PLAYED_FR = "Aucun jeu psychométrique n'a encore été joué.";
    public static final String SOFT_SKILLS_NOT_PLAYED_EN = "No psychometric games have been completed yet.";

    private final JobOfferRepository jobOffers;
    private final TestResultRepository testResults;
    private final SoftSkillsSummaryRepository softSkillsSummaries;
    private final HardSkillsSummaryRepository hardSkillsSummaries;

    public record Section(boolean available, String textFr, String textEn, Instant updatedAt) {}
    public record Result(Section softSkills, Section hardSkills) {}

    public GetCandidateResumeUseCase(JobOfferRepository jobOffers,
                                     TestResultRepository testResults,
                                     SoftSkillsSummaryRepository softSkillsSummaries,
                                     HardSkillsSummaryRepository hardSkillsSummaries) {
        this.jobOffers = jobOffers;
        this.testResults = testResults;
        this.softSkillsSummaries = softSkillsSummaries;
        this.hardSkillsSummaries = hardSkillsSummaries;
    }

    public Result execute(UUID candidateId, UUID jobOfferId, UUID recruiterId) {
        var offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }

        Section softSkills = softSkillsSummaries.findByCandidateId(candidateId)
            .map(s -> new Section(true, s.textFr(), s.textEn(), s.updatedAt()))
            .orElseGet(() -> new Section(false, SOFT_SKILLS_NOT_PLAYED_FR, SOFT_SKILLS_NOT_PLAYED_EN, null));

        boolean tested = testResults.existsByCandidateIdAndJobOfferId(candidateId, jobOfferId);
        Section hardSkills = hardSkillsSummaries.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(s -> new Section(true, s.textFr(), s.textEn(), s.updatedAt()))
            .orElseGet(() -> tested
                ? new Section(false, HARD_SKILLS_PENDING_FR, HARD_SKILLS_PENDING_EN, null)
                : new Section(false, HARD_SKILLS_NOT_TESTED_FR, HARD_SKILLS_NOT_TESTED_EN, null));

        return new Result(softSkills, hardSkills);
    }
}
