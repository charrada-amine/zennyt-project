package com.zennyt.recruitment.application.port;

import com.zennyt.recruitment.domain.model.JobRoleProfile;

import java.util.Map;

/** Port interchangeable du calcul de compatibilité candidat/offre. */
public interface FitScoreCalculatorPort {
    /** @return {@code null} si la paire est incalculable (pas de pondération résolue). */
    FitScoreResult calculate(FitScoreInputs inputs);

    /**
     * Score d'un module psychométrique et part de ce module réellement mesurée.
     *
     * <p>F13/F15 — le CdC §3.3 définit la couverture PAR MODULE
     * (`Score_module_i × f(Couverture_i)`), appliquée avant l'agrégation. Le port
     * ne transportait qu'un {@code Map<String, Double>} de scores plus un ratio
     * global unique : deux modules aux couvertures différentes étaient
     * inexprimables, et le ratio global était de toute façon figé à 100.
     *
     * @param score          score du module sur 100
     * @param coverageRatio  part du module mesurée (0-100) — combien a été joué,
     *                       pas à quel point ça a été réussi
     */
    record ModuleScore(double score, int coverageRatio) {
        public ModuleScore {
            if (coverageRatio < 0 || coverageRatio > 100) {
                throw new IllegalArgumentException("La couverture doit être entre 0 et 100");
            }
        }

        /** Module entièrement couvert — raccourci pour les tests et les données seedées. */
        public static ModuleScore fullyCovered(double score) {
            return new ModuleScore(score, 100);
        }
    }

    /**
     * <p>F22 — {@code jobDescription} et {@code companyDescription} ont été retirés.
     * Vestiges du moteur Groq supprimé, ils n'étaient plus lus par personne mais
     * coûtaient une lecture BDD par paire côté appelant. Surtout, les garder invitait
     * à s'en servir : le CdC §2 interdit explicitement que la description textuelle
     * libre pilote la pondération.
     *
     * <p>F13 — le {@code coverageRatio} global a disparu : la couverture est portée
     * par chaque {@link ModuleScore}, comme le prévoit le CdC.
     *
     * @param roleProfile pondération résolue (profil métier × niveau) — {@code null} si
     *                    l'offre n'est reliée à aucun métier approuvé, auquel cas la paire
     *                    est incalculable (plus de repli IA, voir {@code FitScoreAiConfig})
     * @param hardSkillScore pourcentage de réussite au QCM, {@code null} si aucune tentative complétée
     */
    record FitScoreInputs(Map<String, ModuleScore> softSkills,
                          JobRoleProfile roleProfile, Integer hardSkillScore) {
        public FitScoreInputs {
            softSkills = softSkills == null ? Map.of() : Map.copyOf(softSkills);
        }
    }

    /**
     * @param coverageRatio couverture agrégée, pondérée par le poids des modules du
     *                      métier — c'est elle qui alimente les seuils 60 %/70 % du
     *                      mécanisme 2 (CdC §3.3) et la colonne {@code fit_scores.coverage_ratio}
     */
    record FitScoreResult(int score, int softSkillScore, int coverageRatio) {}
}
