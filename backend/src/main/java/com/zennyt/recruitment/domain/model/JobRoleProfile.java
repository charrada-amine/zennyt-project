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
                             boolean calibrated,
                             java.time.Instant updatedAt) {
    public JobRoleProfile {
        if (profileType == null) throw new IllegalArgumentException("Le profil métier est obligatoire");
        if (level == null) throw new IllegalArgumentException("Le niveau est obligatoire");
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
     *
     * <p>Un métier en {@link TypeEvaluationHard#PORTFOLIO} reçoit toujours
     * {@code PORTFOLIO_BASED} (F19) : l'absence de QCM est son fonctionnement normal,
     * jamais une anomalie — un jeton dédié, distinct d'{@code INFO}, pour que le client
     * ne le confonde pas avec « pensez à ajouter un QCM ».
     *
     * <p><b>Le mode se lit sur le MÉTIER, pas sur le profil.</b> La décision se prenait
     * sur {@code profileType == ARTISTIQUE}, ce qui était exact tant que le mode vivait
     * sur la matrice — mais F32 l'a déplacé sur {@code job_positions} précisément parce
     * que le CdC §4.3 veut UX/UI Designer en Mixte et Photographe en Portfolio, tous deux
     * ARTISTIQUE. Décider sur la famille rendait donc les trois métiers Mixte muets :
     * ils recevaient « pas de QCM attendu » alors qu'ils en réclament un, et leur
     * recruteur n'était jamais alerté du test manquant. {@code MIXTE} et {@code QCM}
     * suivent la dérivation par poids ; seul {@code PORTFOLIO} y échappe.
     *
     * <p><b>F05 (FITSCORE_REMEDIATION.md §2 décision D-B).</b> Deux correctifs sur
     * la dérivation par poids, la table du CdC §6 elle-même étant non monotone
     * (Junior ~30 % → aucune alerte, Manager ~25 % → alerte modérée) et donc
     * impossible à reproduire par une seule fonction de seuil :
     * <ul>
     *   <li>la borne haute du bucket INFO inclut désormais 35 (`<=`), pour que
     *       TECHNIQUE/JUNIOR (poids 35, probablement le plus gros volume de la
     *       plateforme) n'échappe plus dans MODERATE ;</li>
     *   <li>le niveau MANAGER porte un plancher explicite à MODERATE — son poids
     *       hard réel est souvent inférieur à celui de JUNIOR (ex. TECHNIQUE
     *       MANAGER = 30 &lt; TECHNIQUE JUNIOR = 35), donc la seule dérivation par
     *       poids ne peut pas produire l'alerte modérée que le CdC exige pour ce
     *       niveau.</li>
     * </ul>
     */
    public HardSkillsAlertLevel hardSkillsAlert(TypeEvaluationHard evaluationMode) {
        if (evaluationMode == TypeEvaluationHard.PORTFOLIO) return HardSkillsAlertLevel.PORTFOLIO_BASED;
        if (level == ExperienceLevel.MANAGER) return HardSkillsAlertLevel.MODERATE;
        if (expectedHardWeight < 20) return HardSkillsAlertLevel.NONE;
        if (expectedHardWeight <= 35) return HardSkillsAlertLevel.INFO;
        if (expectedHardWeight < 50) return HardSkillsAlertLevel.MODERATE;
        return HardSkillsAlertLevel.STRONG;
    }
}
