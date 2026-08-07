package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : lire le résumé IA ("Resume AI") d'un candidat pour une offre — combine le
 * résumé soft skills (candidat-level) et le résumé hard skills (par <b>métier</b> depuis
 * D1). Chaque section a son propre repli statique bilingue quand l'IA n'a encore rien à
 * montrer.
 *
 * <p>Deux entrées, un seul corps de lecture : le recruteur propriétaire de l'offre lit la
 * version {@code RECRUITER}, le candidat lit la sienne. C'est le seul point de variation —
 * les replis et la logique de disponibilité sont communs, faute de quoi les deux vues
 * pourraient diverger sur ce qu'elles considèrent « disponible ».
 */
@Service
@Transactional(readOnly = true)
public class GetCandidateResumeUseCase {

    /**
     * P3 — le message ne dit plus seulement « il manque un test », il explique <b>ce que le
     * Fit Score affiché vaut alors</b>. Sans cette précision, un recruteur compare un score
     * soft-seul à un score mixte sans savoir qu'ils ne mesurent pas la même chose.
     */
    public static final String HARD_SKILLS_NOT_TESTED_FR =
        "Ce candidat n'a pas encore passé de test de validation des compétences techniques "
        + "(hard skills). Le Fit Score affiché est basé uniquement sur l'évaluation de ses "
        + "compétences comportementales (soft skills).";
    public static final String HARD_SKILLS_NOT_TESTED_EN =
        "This candidate has not taken a hard skills validation test yet. The Fit Score shown "
        + "is based solely on the assessment of their behavioural skills (soft skills).";

    /** Version candidat des mêmes faits — même fond, adressé à la personne concernée (P5). */
    public static final String HARD_SKILLS_NOT_TESTED_SELF_FR =
        "Vous n'avez pas encore passé de test de validation des compétences techniques "
        + "(hard skills). Votre Fit Score est donc calculé uniquement à partir de vos "
        + "compétences comportementales (soft skills).";
    public static final String HARD_SKILLS_NOT_TESTED_SELF_EN =
        "You have not taken a hard skills validation test yet. Your Fit Score is therefore "
        + "based solely on your behavioural skills (soft skills).";

    public static final String HARD_SKILLS_PENDING_FR = "Le résumé est en cours de génération…";
    public static final String HARD_SKILLS_PENDING_EN = "The summary is being generated…";
    public static final String SOFT_SKILLS_NOT_PLAYED_FR = "Aucun jeu psychométrique n'a encore été joué.";
    public static final String SOFT_SKILLS_NOT_PLAYED_EN = "No psychometric games have been completed yet.";
    public static final String SOFT_SKILLS_NOT_PLAYED_SELF_FR =
        "Vous n'avez encore joué à aucun jeu psychométrique.";
    public static final String SOFT_SKILLS_NOT_PLAYED_SELF_EN =
        "You have not played any psychometric games yet.";

    /**
     * Distinct de « jamais joué ». Déduire l'absence de partie de l'absence de ligne de
     * résumé était faux : un candidat peut avoir des scores par module — et donc un Fit
     * Score construit dessus — sans que le résumé ait encore été écrit. Le recruteur lisait
     * alors « aucun jeu joué » juste à côté d'un score qui repose entièrement sur ces jeux.
     * Même distinction que côté hard skills, où « testé » se juge sur l'historique réel.
     */
    public static final String SOFT_SKILLS_PENDING_FR = HARD_SKILLS_PENDING_FR;
    public static final String SOFT_SKILLS_PENDING_EN = HARD_SKILLS_PENDING_EN;

    private final JobOfferRepository jobOffers;
    private final TestResultRepository testResults;
    private final SoftSkillsProjectionRepository softSkillsProjections;
    private final SoftSkillsSummaryRepository softSkillsSummaries;
    private final HardSkillsSummaryRepository hardSkillsSummaries;

    public record Section(boolean available, String textFr, String textEn, Instant updatedAt) {}
    public record Result(Section softSkills, Section hardSkills) {}

    public GetCandidateResumeUseCase(JobOfferRepository jobOffers,
                                     TestResultRepository testResults,
                                     SoftSkillsProjectionRepository softSkillsProjections,
                                     SoftSkillsSummaryRepository softSkillsSummaries,
                                     HardSkillsSummaryRepository hardSkillsSummaries) {
        this.jobOffers = jobOffers;
        this.testResults = testResults;
        this.softSkillsProjections = softSkillsProjections;
        this.softSkillsSummaries = softSkillsSummaries;
        this.hardSkillsSummaries = hardSkillsSummaries;
    }

    /** Lecture recruteur — réservée au propriétaire de l'offre. */
    public Result execute(UUID candidateId, UUID jobOfferId, UUID recruiterId) {
        JobOffer offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        return read(candidateId, offer, ResumeAudience.RECRUITER);
    }

    /**
     * Lecture candidat — sur son propre profil.
     *
     * <p>Pas de contrôle de propriété d'offre ici : celui de la lecture recruteur protège
     * <i>l'offre</i>, notion qui n'a pas de sens pour un candidat. Ce qui est protégé, c'est
     * l'identité du candidat, et elle vient du jeton — jamais de l'URL.
     *
     * @param jobOfferId l'offre consultée, qui ne sert qu'à désigner le métier ;
     *                   {@code null} pour n'obtenir que la section soft skills
     */
    public Result executeForSelf(UUID candidateId, UUID jobOfferId) {
        JobOffer offer = jobOfferId == null ? null
            : jobOffers.findById(jobOfferId)
                .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        return read(candidateId, offer, ResumeAudience.CANDIDATE);
    }

    private Result read(UUID candidateId, JobOffer offer, ResumeAudience audience) {
        boolean self = audience == ResumeAudience.CANDIDATE;

        // « A joué » se juge sur les projections, pas sur l'existence du résumé : ce sont
        // elles qui alimentent le Fit Score, et elles peuvent exister avant que le texte
        // ait été écrit. Sans cette lecture, le recruteur voyait « aucun jeu joué » à côté
        // d'un Fit Score entièrement construit sur ces jeux.
        boolean aJoue = !softSkillsProjections.findByCandidateId(candidateId).isEmpty();
        Section softSkills = softSkillsSummaries.findByCandidateIdAndAudience(candidateId, audience)
            .map(s -> new Section(true, s.textFr(), s.textEn(), s.updatedAt()))
            .orElseGet(() -> aJoue
                ? new Section(false, SOFT_SKILLS_PENDING_FR, SOFT_SKILLS_PENDING_EN, null)
                : new Section(false,
                    self ? SOFT_SKILLS_NOT_PLAYED_SELF_FR : SOFT_SKILLS_NOT_PLAYED_FR,
                    self ? SOFT_SKILLS_NOT_PLAYED_SELF_EN : SOFT_SKILLS_NOT_PLAYED_EN, null));

        UUID jobPositionId = offer == null ? null : offer.jobPositionId();
        // « Testé » se juge désormais sur le métier, pas sur l'offre : c'est ce qui distingue
        // « résumé en cours de génération » de « aucun test, score soft seul ».
        boolean tested = jobPositionId != null
            && !testResults.findHardSkillHistory(candidateId, jobPositionId).isEmpty();
        Section hardSkills = hardSkillsSummaries
            .findByCandidateIdAndJobPositionIdAndAudience(candidateId, jobPositionId, audience)
            .map(s -> new Section(true, s.textFr(), s.textEn(), s.updatedAt()))
            .orElseGet(() -> tested
                ? new Section(false, HARD_SKILLS_PENDING_FR, HARD_SKILLS_PENDING_EN, null)
                : new Section(false,
                    self ? HARD_SKILLS_NOT_TESTED_SELF_FR : HARD_SKILLS_NOT_TESTED_FR,
                    self ? HARD_SKILLS_NOT_TESTED_SELF_EN : HARD_SKILLS_NOT_TESTED_EN, null));

        return new Result(softSkills, hardSkills);
    }
}
