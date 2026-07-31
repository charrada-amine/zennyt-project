package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.SoftSkillModule;

import java.util.Map;

/**
 * Calcul déterministe du Fit Score (CdC Fit Score v3 §3, §4.3) — remplace
 * l'estimation Groq par la formule pondérée profil métier × niveau (D3,
 * PLAN_FITSCORE_V3.md) dès qu'une offre est reliée au référentiel de métiers.
 *
 * <p>Aucun repli : si l'offre n'est reliée à aucun métier du référentiel (ou à un
 * métier pas encore approuvé, donc sans profil), le calcul renvoie {@code null} et
 * <b>rien n'est écrit</b>. L'ancien repli sur un moteur IA externe a été supprimé :
 * il produisait, de façon invisible, des scores calculés selon une logique
 * complètement différente des autres, ~12× plus lents (mesuré : ~361 ms contre
 * ~29 ms) et dépendants d'un service tiers. Une paire incalculable est désormais
 * simplement en attente de l'approbation de son métier par un admin — le balayage
 * de rattrapage la calculera dès que ce sera fait.
 *
 * <p>Le mécanisme de couverture (CdC §3.3, mécanisme 1 — {@code score ×
 * couverture}) est câblé mais actuellement un no-op : aucun suivi de
 * couverture par module n'existe côté Games (D5), donc {@code coverageRatio}
 * vaut toujours 100 en pratique. Il s'applique de façon globale, sur le score
 * soft déjà agrégé — pas par module — car il n'existe rien de plus fin à
 * appliquer tant que D5 n'est pas résolu.
 *
 * <p>Les 5 poids de module de {@link JobRoleProfile} (CdC §3.2, §4.3 Couche A)
 * <b>sont</b> appliqués ici, via {@link #weightedSoftScore} : chaque entrée de
 * {@code inputs.softSkills()} est rattachée à son module CdC
 * ({@link SoftSkillModule#fromGamesModule}) puis pondérée par le poids que ce
 * module porte dans le {@code JobRoleProfile} de l'offre. Un correctif d'un
 * bug réel : la version précédente aplatissait d'abord tous les modules du
 * candidat en une seule moyenne avant que la pondération ne puisse s'exercer,
 * ce qui rendait le Score_Soft strictement identique quel que soit le métier
 * de l'offre — en contradiction avec le CdC §3.2, qui prévoit un score par
 * module pondéré par métier, indépendamment de la présence d'un QCM (D2 ne
 * met à 0 que le poids du hard, jamais celui des modules soft).
 *
 * <p>Au mieux 3 des 5 poids contribuent aujourd'hui : voir
 * {@link SoftSkillModule} pour l'état réel de ce que Games mesure. Ce n'est
 * pas un cas limite, c'est la situation permanente tant que Games n'expose pas
 * Prise de décision ni Régulation émotionnelle.
 *
 * <p>Le CV n'intervient pas dans la formule (décision D1 enfin tranchée) : le CdC
 * v3 ne le mentionne nulle part, et {@code cvMatchScore} a été supprimé plutôt
 * que conservé en champ toujours nul. L'extraction de texte de CV reste utilisée
 * ailleurs, pour le résumé IA du profil candidat.
 */
public class DeterministicFitScoreCalculator implements FitScoreCalculatorPort {

    /** @return {@code null} si l'offre n'a pas de pondération résolue — rien à écrire. */
    @Override
    public FitScoreResult calculate(FitScoreInputs inputs) {
        JobRoleProfile roleProfile = inputs.roleProfile();
        if (roleProfile == null) return null;

        int rawSoftScore = bounded(weightedSoftScore(inputs.softSkills(), roleProfile));
        // Mécanisme 1 (CdC §3.3) : scoreAjusté = score × couverture. Ex. 90×1.0=90, 90×0.4=36.
        int softScore = bounded(Math.round(rawSoftScore * inputs.coverageRatio() / 100f));

        boolean hasHardScore = inputs.hardSkillScore() != null;
        int hardWeight = hasHardScore ? roleProfile.hardWeight() : 0;
        int softWeight = 100 - hardWeight;
        int hardScore = hasHardScore ? inputs.hardSkillScore() : 0;

        int score = bounded(Math.round((softScore * softWeight + hardScore * hardWeight) / 100f));
        return new FitScoreResult(score, softScore);
    }

    /**
     * CdC §3.2 : Score_Soft = Σ(Score_module_i × Poids_module_i), renormalisé sur les
     * seuls modules dont un score existe — un candidat n'a pas forcément joué les 5
     * mini-jeux, et 2 des 5 modules CdC n'ont aujourd'hui aucun moyen d'être mesurés
     * (voir {@link SoftSkillModule}). Une entrée dont la clé ne correspond à aucun
     * module CdC connu ({@code fromGamesModule} renvoie {@code null}) est ignorée
     * plutôt que de faire échouer le calcul — même principe défensif que
     * {@code GenerateSoftSkillsSummaryUseCase.MODULE_LABELS.getOrDefault(...)}.
     */
    private static int weightedSoftScore(Map<String, Double> softSkills, JobRoleProfile profile) {
        double weightedSum = 0;
        int weightTotal = 0;
        for (Map.Entry<String, Double> entry : softSkills.entrySet()) {
            SoftSkillModule module = SoftSkillModule.fromGamesModule(entry.getKey());
            if (module == null) continue;
            int weight = moduleWeight(module, profile);
            weightedSum += entry.getValue() * weight;
            weightTotal += weight;
        }
        if (weightTotal == 0) {
            // Aucun module reconnu n'a de poids > 0 dans ce profil (ou aucune donnée
            // reconnue) : repli sur la moyenne brute plutôt qu'un 0 artificiel.
            return (int) Math.round(softSkills.values().stream()
                .mapToDouble(Double::doubleValue).average().orElse(0));
        }
        return Math.round((float) (weightedSum / weightTotal));
    }

    private static int moduleWeight(SoftSkillModule module, JobRoleProfile profile) {
        return switch (module) {
            case COGNITIVE_FLEXIBILITY -> profile.cognitiveFlexibilityWeight();
            case WORKING_MEMORY -> profile.workingMemoryWeight();
            case DECISION_MAKING -> profile.decisionMakingWeight();
            case EXECUTIVE_PLANNING -> profile.executivePlanningWeight();
            case EMOTIONAL_REGULATION -> profile.emotionalRegulationWeight();
        };
    }

    private int bounded(int value) { return Math.max(0, Math.min(100, value)); }
}
