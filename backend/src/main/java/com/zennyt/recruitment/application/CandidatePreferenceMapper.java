package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.WorkplaceType;

/**
 * Rapproche le vocabulaire des préférences candidat côté Identity
 * ({@code identity.domain.model.WorkplaceType}/{@code JobType}, reçues en
 * texte brut via {@link com.zennyt.identity.domain.event.UserAccessStateChangedEvent})
 * avec les enums recruitment correspondantes.
 *
 * <p>Les deux vocabulaires ont été créés indépendamment et ne coïncident pas
 * totalement : {@code null} signifie "pas d'équivalent raisonnable" — traité
 * comme une absence de préférence pour ce critère, jamais comme un filtre
 * bloquant (FLEXIBLE et FREELANCE n'ont pas d'équivalent réel côté offres ;
 * INTERNSHIP est rapproché d'APPRENTICESHIP, le plus proche des deux).
 */
public final class CandidatePreferenceMapper {
    private CandidatePreferenceMapper() {}

    public static WorkplaceType toWorkplaceType(String identityWorkplaceType) {
        if (identityWorkplaceType == null) return null;
        return switch (identityWorkplaceType) {
            case "ONSITE" -> WorkplaceType.ON_SITE;
            case "REMOTE" -> WorkplaceType.REMOTE;
            case "HYBRID" -> WorkplaceType.HYBRID;
            default -> null; // FLEXIBLE (ou toute valeur inconnue) -> pas de préférence
        };
    }

    public static ContractType toContractType(String identityJobType) {
        if (identityJobType == null) return null;
        return switch (identityJobType) {
            case "FULL_TIME" -> ContractType.FULL_TIME;
            case "PART_TIME" -> ContractType.PART_TIME;
            case "CONTRACT" -> ContractType.CONTRACT;
            case "INTERNSHIP" -> ContractType.APPRENTICESHIP;
            default -> null; // FREELANCE (ou toute valeur inconnue) -> pas de préférence
        };
    }
}
