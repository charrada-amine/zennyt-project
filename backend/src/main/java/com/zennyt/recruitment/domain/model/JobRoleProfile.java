package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.HardSkillsAlertLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;

/**
 * Pondération de référence (Couche A + Couche B, CdC Fit Score v3 §4.3) pour
 * un couple (profil métier, niveau) — jamais par métier individuel : la
 * matrice v4.1 confirme que tous les métiers partageant un même profil ont
 * exactement la même pondération, quel que soit leur secteur (le secteur ne
 * détermine que le contenu du QCM hard skills, jamais le poids).
 */
public record JobRoleProfile(JobProfileType profileType, ExperienceLevel level,
                             int softWeight, int hardWeight, int expectedHardWeight,
                             int cognitiveFlexibilityWeight, int workingMemoryWeight,
                             int decisionMakingWeight, int executivePlanningWeight,
                             int emotionalRegulationWeight,
                             TypeEvaluationHard typeEvaluationHard, boolean calibrated) {
    public JobRoleProfile {
        if (profileType == null) throw new IllegalArgumentException("Le profil métier est obligatoire");
        if (level == null) throw new IllegalArgumentException("Le niveau est obligatoire");
        if (typeEvaluationHard == null) {
            throw new IllegalArgumentException("Le mode d'évaluation hard skills est obligatoire");
        }
        if (softWeight + hardWeight != 100) {
            throw new IllegalArgumentException("poids_soft + poids_hard doit valoir 100");
        }
        int moduleSum = cognitiveFlexibilityWeight + workingMemoryWeight + decisionMakingWeight
            + executivePlanningWeight + emotionalRegulationWeight;
        if (moduleSum != 100) {
            throw new IllegalArgumentException("La somme des poids de module doit valoir 100");
        }
    }

    /**
     * Niveau d'alerte « hard skills manquant » (CdC §6) dérivé de
     * {@code expectedHardWeight} — à combiner par l'appelant avec la présence
     * d'un QCM sur l'offre (aucune alerte à afficher si un QCM existe déjà).
     * Le profil ARTISTIQUE reste toujours en INFO : l'absence de QCM est son
     * fonctionnement normal (évaluation par portfolio), jamais une anomalie.
     */
    public HardSkillsAlertLevel hardSkillsAlert() {
        if (profileType == JobProfileType.ARTISTIQUE) return HardSkillsAlertLevel.INFO;
        if (expectedHardWeight < 20) return HardSkillsAlertLevel.NONE;
        if (expectedHardWeight < 35) return HardSkillsAlertLevel.INFO;
        if (expectedHardWeight < 50) return HardSkillsAlertLevel.MODERATE;
        return HardSkillsAlertLevel.STRONG;
    }
}
