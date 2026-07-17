package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.*;

import java.util.UUID;

/**
 * DTO de requête pour créer une offre d'emploi.
 *
 * <p>Noms de champs alignés sur le contrat convenu avec le frontend
 * (city/country/remote/currency, assessmentId simple et optionnel).
 * L'identité du recruteur vient exclusivement du contexte d'authentification.
 */
public record CreateJobOfferRequest(
    String title, String companyName,
    String city, String country, Boolean remote,
    Double salaryMin, Double salaryMax, String currency,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    String fieldOfWork, String description, String responsibilities,
    String minimumQualifications, String preferredQualifications,
    String whatWeOffer, String howToApply, String companyInfo,
    UUID assessmentId, Integer passingScore, Boolean openToInternational
) {}
