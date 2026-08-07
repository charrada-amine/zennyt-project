import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;

import java.util.LinkedHashMap;
import java.util.Map;

public class FitScoreProbe {
    static final com.zennyt.recruitment.infrastructure.ai.DeterministicFitScoreCalculator CALC =
        new com.zennyt.recruitment.infrastructure.ai.DeterministicFitScoreCalculator();

    static JobRoleProfile p(JobProfileType t, ExperienceLevel l) { return FitScoreHarness.p(t, l); }
    static Map<String, Double> m(double f, double me, double d, double pl, double e) {
        return FitScoreHarness.modules(f, me, d, pl, e);
    }
    static Map<String, Double> reach(Map<String, Double> x) { return FitScoreHarness.reachable(x); }
    static FitScoreResult run(Map<String, Double> mo, JobRoleProfile pr, Integer h, int c) {
        return CALC.calculate(new FitScoreInputs(mo, "d", "c", pr, h, c));
    }

    public static void main(String[] a) {
        // 1) Courbe de niveau avec un ecart soft/hard important
        System.out.println("=== 1. Courbe de niveau : candidat soft FAIBLE (45), QCM FORT (90) ===");
        Map<String, Double> weakSoft = m(45, 45, 45, 45, 45);
        for (ExperienceLevel l : ExperienceLevel.values()) {
            JobRoleProfile pr = p(JobProfileType.TECHNIQUE, l);
            System.out.printf("  TECHNIQUE %-10s hard=%2d%%  soft=%d hard=90 -> fit %d%n",
                l, pr.hardWeight(), run(weakSoft, pr, 90, 100).softSkillScore(),
                run(weakSoft, pr, 90, 100).score());
        }
        System.out.println("  (pic attendu au niveau du hard le plus eleve = MID)");

        System.out.println("\n=== 1b. Meme chose, candidat soft FORT (90), QCM FAIBLE (45) ===");
        Map<String, Double> strongSoft = m(90, 90, 90, 90, 90);
        for (ExperienceLevel l : ExperienceLevel.values()) {
            JobRoleProfile pr = p(JobProfileType.TECHNIQUE, l);
            System.out.printf("  TECHNIQUE %-10s hard=%2d%% -> fit %d%n",
                l, pr.hardWeight(), run(strongSoft, pr, 45, 100).score());
        }

        // 2) Impact des modules manquants, par profil
        System.out.println("\n=== 2. Cout reel des 2 modules non mesurables, par profil ===");
        System.out.println("    candidat : flex 60, mem 55, decision 40, planif 65, regulation 95");
        Map<String, Double> cand = m(60, 55, 40, 65, 95);
        System.out.printf("    %-14s | %-9s | %-9s | %s%n", "PROFIL", "5 modules", "3 Games", "ecart");
        for (JobProfileType t : JobProfileType.values()) {
            JobRoleProfile pr = p(t, ExperienceLevel.MID);
            int five = run(cand, pr, null, 100).softSkillScore();
            int three = run(reach(cand), pr, null, 100).softSkillScore();
            System.out.printf("    %-14s | %9d | %9d | %+d%n", t, five, three, three - five);
        }

        // 3) Le meme, mais candidat faible en regulation
        System.out.println("\n    candidat inverse : flex 60, mem 55, decision 40, planif 65, regulation 20");
        Map<String, Double> cand2 = m(60, 55, 40, 65, 20);
        for (JobProfileType t : JobProfileType.values()) {
            JobRoleProfile pr = p(t, ExperienceLevel.MID);
            int five = run(cand2, pr, null, 100).softSkillScore();
            int three = run(reach(cand2), pr, null, 100).softSkillScore();
            System.out.printf("    %-14s | %9d | %9d | %+d%n", t, five, three, three - five);
        }

        // 4) Non-participation = avantage ?
        System.out.println("\n=== 3. Un candidat gagne-t-il a NE PAS jouer un mini-jeu ? ===");
        JobRoleProfile tech = p(JobProfileType.TECHNIQUE, ExperienceLevel.MID);
        Map<String, Double> full = new LinkedHashMap<>();
        full.put("MOVE_FAST", 80.0); full.put("MEMORY_QUEST", 75.0); full.put("PLANIFIK", 30.0);
        Map<String, Double> skipped = new LinkedHashMap<>(full);
        skipped.remove("PLANIFIK");
        System.out.printf("  joue les 3 (planif faible=30)  -> soft %d%n",
            run(full, tech, null, 100).softSkillScore());
        System.out.printf("  saute PLANIFIK                 -> soft %d   <=== ecart %+d%n",
            run(skipped, tech, null, 100).softSkillScore(),
            run(skipped, tech, null, 100).softSkillScore() - run(full, tech, null, 100).softSkillScore());

        // 5) Arrondi intermediaire
        System.out.println("\n=== 4. Perte de precision par arrondi intermediaire ===");
        JobRoleProfile art = p(JobProfileType.ARTISTIQUE, ExperienceLevel.MID);
        Map<String, Double> ux = m(91, 66, 74, 60 * 0.9, 80);
        FitScoreResult r = run(ux, art, 79, 100);
        double exactSoft = (91 * 40 + 66 * 15 + 74 * 15 + 54 * 15 + 80 * 15) / 100.0;
        double exactFit = exactSoft * 0.45 + 79 * 0.55;
        System.out.printf("  soft exact = %.2f -> code arrondit a %d%n", exactSoft, r.softSkillScore());
        System.out.printf("  fit  exact = %.2f -> code renvoie   %d  (ecart %+.2f)%n",
            exactFit, r.score(), r.score() - exactFit);

        // 6) Borne 0-100 et cas limites
        System.out.println("\n=== 5. Cas limites ===");
        System.out.printf("  aucun module joue          -> %s%n", run(new LinkedHashMap<>(), tech, 70, 100));
        System.out.printf("  modules inconnus seulement -> %s%n",
            run(Map.of("JEU_INCONNU", 90.0), tech, 70, 100));
        System.out.printf("  couverture 0%%              -> %s%n", run(m(90,90,90,90,90), tech, 70, 0));
        System.out.printf("  scores max + QCM max       -> %s%n", run(m(100,100,100,100,100), tech, 100, 100));
        System.out.printf("  scores nuls + QCM nul      -> %s%n", run(m(0,0,0,0,0), tech, 0, 100));
    }
}
