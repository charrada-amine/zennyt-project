package com.zennyt.recruitment.infrastructure.ai;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.SoftSkillModule;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
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
 * <p>Au mieux 4 des 5 poids contribuent aujourd'hui : voir
 * {@link SoftSkillModule} pour l'état réel de ce que Games mesure. Ce n'est
 * pas un cas limite, c'est la situation permanente tant que Games n'expose pas
 * Prise de décision (mini-jeu non jouable, catalogue de scénarios vide).
 *
 * <p>Le CV n'intervient pas dans la formule (décision D1 enfin tranchée) : le CdC
 * v3 ne le mentionne nulle part, et {@code cvMatchScore} a été supprimé plutôt
 * que conservé en champ toujours nul. L'extraction de texte de CV reste utilisée
 * ailleurs, pour le résumé IA du profil candidat.
 */
public class DeterministicFitScoreCalculator implements FitScoreCalculatorPort {

    /**
     * @return {@code null} si la paire est incalculable — pas de pondération résolue,
     *         ou aucun module pesant pour ce métier n'a été mesuré (F02). Dans les deux
     *         cas rien n'est écrit : une absence de donnée n'est pas un score de 0.
     */
    @Override
    public FitScoreResult calculate(FitScoreInputs inputs) {
        JobRoleProfile roleProfile = inputs.roleProfile();
        if (roleProfile == null) return null;

        SoftAggregate soft = weightedSoftScore(inputs.softSkills(), roleProfile);
        if (soft == null) return null;

        boolean hasHardScore = inputs.hardSkillScore() != null;
        int hardWeight = hasHardScore ? roleProfile.hardWeight() : 0;
        int softWeight = 100 - hardWeight;
        int hardScore = hasHardScore ? inputs.hardSkillScore() : 0;

        // F21 : le soft reste en double jusqu'au blend final. L'arrondir avant faisait
        // dériver le Fit Score de jusqu'à 0,67 point et le rendait non reproductible
        // à partir des sous-scores affichés.
        int score = boundedInt(Math.round((soft.score() * softWeight + hardScore * hardWeight) / 100d));
        return new FitScoreResult(score, boundedInt(Math.round(soft.score())), soft.coverage());
    }

    /** Score soft agrégé et couverture agrégée, tous deux pondérés par le métier. */
    private record SoftAggregate(double score, int coverage) {}

    /**
     * CdC §3.2 : {@code Score_Soft = Σ(Score_module_i × Poids_module_i)}, avec
     * {@code Σ Poids_module_i = 100}. Une entrée dont la clé ne correspond à aucun
     * module CdC connu ({@code fromGamesModule} renvoie {@code null}) est ignorée.
     *
     * <p><b>F07/F08, décision D-D</b> — la division se fait par <b>100</b>, plus par la
     * somme des poids des seuls modules joués. L'ancienne renormalisation redistribuait
     * le poids des modules manquants sur ceux qui restaient, avec deux conséquences
     * mesurées : sur un profil RELATIONNEL, deux candidats aux régulations émotionnelles
     * opposées (95 et 20, sur une dimension pesant 45 %) obtenaient le <b>même</b> score ;
     * et sauter un mini-jeu qu'on rate rapportait <b>+11 points</b> par rapport au fait
     * de le jouer. Un module non joué compte désormais pour 0 — sa couverture est nulle,
     * donc sa contribution aussi — et c'est la couverture agrégée qui signale au
     * recruteur que la mesure est incomplète (seuils 60 %/70 %, mécanisme 2).
     *
     * <p>F13/F15 — le mécanisme 1 du CdC §3.3 est appliqué <b>par module et avant
     * l'agrégation</b> ({@code Score_module_i × Couverture_i}), et non plus globalement
     * sur le score déjà agrégé. Les deux ne coïncident que si tous les modules partagent
     * la même couverture ; c'est précisément l'hypothèse que le CdC ne fait pas.
     */
    private static SoftAggregate weightedSoftScore(Map<String, ModuleScore> softSkills,
                                                   JobRoleProfile profile) {
        // Étape 1 — regrouper les jeux par module CdC. Un module peut être alimenté par
        // PLUSIEURS jeux (Flexibilité cognitive = Move Fast + Je continue + Je coordonne).
        // Sans ce regroupement, son poids serait compté une fois par jeu : 30 + 30 + 30
        // = 90 points sur 100 au lieu de 30, et le module écraserait tous les autres.
        Map<SoftSkillModule, List<ModuleScore>> playedByModule = new EnumMap<>(SoftSkillModule.class);
        for (Map.Entry<String, ModuleScore> entry : softSkills.entrySet()) {
            SoftSkillModule module = SoftSkillModule.fromGamesModule(entry.getKey());
            if (module == null) continue;   // jeu pas encore rattaché : ignoré, jamais promu
            playedByModule.computeIfAbsent(module, m -> new ArrayList<>()).add(entry.getValue());
        }

        // Étape 2 — un module, un poids, une fois.
        double weightedSum = 0;
        double weightedCoverage = 0;
        int denominator = 0;
        for (SoftSkillModule module : SoftSkillModule.values()) {
            // Aucun jeu de ce module n'existe encore (« Je Décide » et ses 30 scénarios
            // manquants) : il sort du numérateur ET du dénominateur. Personne n'est
            // pénalisé pour un jeu qui n'existe pour personne.
            if (module.unmeasurable()) continue;

            int weight = moduleWeight(module, profile);
            denominator += weight;

            List<ModuleScore> played = playedByModule.get(module);
            if (played == null) continue;   // jeu disponible mais non joué : contribue 0

            // Couverture du module = somme des couvertures des jeux joués, rapportée au
            // nombre de jeux DISPONIBLES. Avoir joué 1 des 3 jeux de la Flexibilité
            // cognitive couvre le module à un tiers, pas entièrement.
            double moduleCoverage = Math.min(100d,
                played.stream().mapToInt(ModuleScore::coverageRatio).sum()
                    / (double) module.availableGameCount());
            double moduleScore = played.stream().mapToDouble(ModuleScore::score).average().orElse(0);

            weightedSum += moduleScore * moduleCoverage / 100d * weight;
            weightedCoverage += moduleCoverage * weight;
        }

        // F01/F02 : aucun module pesant pour ce métier n'est mesurable. L'ancien repli
        // moyennait `softSkills.values()` — c'est-à-dire la map ENTIÈRE, y compris les
        // clés que la boucle venait d'écarter. Une clé inconnue devenait ainsi la
        // totalité du Score_Soft, sans aucune pondération métier ({FUTUR_JEU: 90} -> 90),
        // et une map vide produisait un 0 persisté comme une mesure réelle.
        // Une absence de donnée n'est pas un score : rien n'est calculé ni écrit.
        if (denominator == 0 || playedByModule.isEmpty()) return null;
        return new SoftAggregate(
            bounded(weightedSum / denominator),
            boundedInt(Math.round(weightedCoverage / denominator)));
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

    private static double bounded(double value) { return Math.max(0d, Math.min(100d, value)); }

    private static int boundedInt(long value) { return (int) Math.max(0L, Math.min(100L, value)); }
}
