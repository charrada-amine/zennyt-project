package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.*;

import java.util.UUID;

/**
 * DTO de requête pour créer (POST) ou remplacer intégralement (PUT) une offre
 * d'emploi — même forme pour les deux (contrat squad web, §3.3).
 *
 * <p>Ni {@code recruiterId} (dérivé du JWT), ni {@code companyName}/
 * {@code companyInfo} (portés par le recruteur, joints à la lecture), ni
 * {@code status}/{@code postedAt}/{@code assessmentId} (server-owned ou gérés
 * via PATCH). {@code jobPositionId} reste accepté en plus du contrat minimal
 * — référentiel de métiers non mentionné par le contrat squad web. Plus de
 * {@code passingScore} : le seuil de réussite est désormais un taux fixe
 * global (contrat squad web §7.1), pas un réglage par offre.
 */
public record CreateJobOfferRequest(
    String title,
    String city, String country,
    Double salaryMin, Double salaryMax,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    String description, String responsibilities,
    String minimumQualifications, String preferredQualifications,
    String whatWeOffer, String howToApply,
    UUID jobPositionId, Boolean openToInternational
) {}
