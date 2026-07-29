package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.JobRoleProfile;

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
 * vaut toujours 100 en pratique. Pour la même raison, les 5 poids de module de
 * {@link JobRoleProfile} ne sont pas appliqués ici : tant qu'un seul score
 * soft-skills agrégé existe (pas de score distinct par module CdC), leur somme
 * pondérée sur un score identique équivaut mathématiquement à ce score lui-même
 * — les appliquer ajouterait du calcul sans changer le résultat. Ils
 * s'activeront d'eux-mêmes le jour où Games exposera un score par module.
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

        int rawSoftScore = bounded((int) Math.round(inputs.softSkills().values().stream()
            .mapToDouble(Double::doubleValue).average().orElse(0)));
        // Mécanisme 1 (CdC §3.3) : scoreAjusté = score × couverture. Ex. 90×1.0=90, 90×0.4=36.
        int softScore = bounded(Math.round(rawSoftScore * inputs.coverageRatio() / 100f));

        boolean hasHardScore = inputs.hardSkillScore() != null;
        int hardWeight = hasHardScore ? roleProfile.hardWeight() : 0;
        int softWeight = 100 - hardWeight;
        int hardScore = hasHardScore ? inputs.hardSkillScore() : 0;

        int score = bounded(Math.round((softScore * softWeight + hardScore * hardWeight) / 100f));
        return new FitScoreResult(score, softScore);
    }

    private int bounded(int value) { return Math.max(0, Math.min(100, value)); }
}
