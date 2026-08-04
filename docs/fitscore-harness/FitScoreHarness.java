import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreResult;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import com.zennyt.recruitment.infrastructure.ai.DeterministicFitScoreCalculator;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Exécute le VRAI DeterministicFitScoreCalculator contre le référentiel seedé
 * par V42__job_role_profiles.sql (valeurs recopiées à l'identique).
 *
 * Modules Games -> modules CdC : MOVE_FAST=Flex.cogn, MEMORY_QUEST=Mém.travail,
 * DECISION=Prise décision, PLANIFIK=Planif.exéc, EMOTIONAL_REGULATION=Régul.émot.
 *
 * Niveaux : CdC Junior/Senior/Lead/Manager -> enum JUNIOR/MID/SENIOR/EXECUTIVE.
 */
public class FitScoreHarness {

    static final DeterministicFitScoreCalculator CALC = new DeterministicFitScoreCalculator();

    // ── Référentiel seedé V42 : soft, hard, expectedHard + 5 poids de module ──
    public static JobRoleProfile p(JobProfileType t, ExperienceLevel l) {
        int[] curve;   // JUNIOR, MID, SENIOR, EXECUTIVE  (hard weight)
        int[] mods;    // flex, mem, decision, planif, regul
        TypeEvaluationHard mode = TypeEvaluationHard.QCM;
        switch (t) {
            case TECHNIQUE     -> { curve = new int[]{35, 65, 55, 30}; mods = new int[]{30, 20, 30, 15,  5}; }
            case ANALYTIQUE    -> { curve = new int[]{30, 60, 50, 25}; mods = new int[]{25, 20, 30, 15, 10}; }
            case RELATIONNEL   -> { curve = new int[]{10, 25, 20, 10}; mods = new int[]{10, 10, 20, 15, 45}; }
            case MANAGERIAL    -> { curve = new int[]{20, 40, 35, 20}; mods = new int[]{10, 10, 20, 30, 30}; }
            case CONVENTIONNEL -> { curve = new int[]{25, 40, 35, 20}; mods = new int[]{15, 30, 15, 30, 10}; }
            case ARTISTIQUE    -> { curve = new int[]{30, 55, 45, 25}; mods = new int[]{40, 15, 15, 15, 15};
                                    mode = TypeEvaluationHard.PORTFOLIO; }
            default -> throw new IllegalStateException();
        }
        int hard = curve[l.ordinal()];
        return new JobRoleProfile(t, l, 100 - hard, hard, hard,
            mods[0], mods[1], mods[2], mods[3], mods[4], mode, false);
    }

    public static Map<String, Double> modules(double flex, double mem, double dec, double plan, double emo) {
        Map<String, Double> m = new LinkedHashMap<>();
        m.put("MOVE_FAST", flex);
        m.put("MEMORY_QUEST", mem);
        m.put("DECISION", dec);
        m.put("PLANIFIK", plan);
        m.put("EMOTIONAL_REGULATION", emo);
        return m;
    }

    /** Uniquement les 3 modules réellement produits par Games aujourd'hui. */
    public static Map<String, Double> reachable(Map<String, Double> all) {
        Map<String, Double> m = new LinkedHashMap<>(all);
        m.remove("DECISION");
        m.remove("EMOTIONAL_REGULATION");
        return m;
    }

    static FitScoreResult run(Map<String, Double> mods, JobRoleProfile prof, Integer hard, int cov) {
        return CALC.calculate(new FitScoreInputs(mods, "desc", "companyInfo", prof, hard, cov));
    }

    record Case(String name, JobProfileType type, ExperienceLevel level,
                double flex, double mem, double dec, double plan, double emo,
                double covFlex, double covMem, double covDec, double covPlan, double covEmo,
                Integer hardScore, Double handSoft, Double handFit) {}

    public static void main(String[] args) {
        Case[] cases = {
            // ── Les 5 exemples donnés plus tôt ──
            new Case("Ex1  Developpeur Senior (CdC) = TECHNIQUE/MID",
                JobProfileType.TECHNIQUE, ExperienceLevel.MID,
                82, 74, 68, 90, 55,  100, 90, 100, 80, 100,  78,  71.87, 75.85),
            new Case("Ex2  Commercial Junior, sans QCM = RELATIONNEL/JUNIOR",
                JobProfileType.RELATIONNEL, ExperienceLevel.JUNIOR,
                60, 65, 72, 58, 88,  100, 70, 100, 100, 100,  null, 73.25, 73.25),
            new Case("Ex3  Comptable Manager = CONVENTIONNEL/EXECUTIVE",
                JobProfileType.CONVENTIONNEL, ExperienceLevel.EXECUTIVE,
                55, 84, 62, 79, 70,  100, 100, 50, 100, 100,  61,  68.80, 67.24),
            new Case("Ex4  UX/UI Designer Senior = ARTISTIQUE/MID (Mixte 40/60)",
                JobProfileType.ARTISTIQUE, ExperienceLevel.MID,
                91, 66, 74, 60, 80,  100, 100, 100, 90, 100,  79,  77.50, 78.33),
            new Case("Ex5  Chef de projet Lead = MANAGERIAL/SENIOR (sans overrides)",
                JobProfileType.MANAGERIAL, ExperienceLevel.SENIOR,
                70, 72, 85, 78, 66,  100, 100, 100, 100, 60,  80,  65.40, 70.50),

            // ── Données synthetiques supplementaires, autres domaines/profils ──
            new Case("S1   Infirmier Senior (Health) = RELATIONNEL/MID",
                JobProfileType.RELATIONNEL, ExperienceLevel.MID,
                48, 52, 61, 55, 93,  100, 100, 100, 100, 100,  64,  null, null),
            new Case("S2   Analyste financier Lead (Finance) = ANALYTIQUE/SENIOR",
                JobProfileType.ANALYTIQUE, ExperienceLevel.SENIOR,
                88, 79, 91, 62, 40,  100, 100, 100, 100, 100,  55,  null, null),
            new Case("S3   Technicien maintenance Junior (Industry) = TECHNIQUE/JUNIOR",
                JobProfileType.TECHNIQUE, ExperienceLevel.JUNIOR,
                71, 68, 59, 74, 50,  100, 100, 100, 100, 100,  null, null, null),
            new Case("S4   Gestionnaire de stock Senior (Retail) = CONVENTIONNEL/MID",
                JobProfileType.CONVENTIONNEL, ExperienceLevel.MID,
                44, 90, 51, 86, 62,  100, 100, 100, 100, 100,  73,  null, null),
            new Case("S5   Directeur d'hotel Manager (Hotel) = MANAGERIAL/EXECUTIVE",
                JobProfileType.MANAGERIAL, ExperienceLevel.EXECUTIVE,
                57, 63, 70, 88, 84,  100, 100, 100, 100, 100,  null, null, null),
            new Case("S6   Photographe Senior (Media) = ARTISTIQUE/SENIOR, portfolio only",
                JobProfileType.ARTISTIQUE, ExperienceLevel.SENIOR,
                95, 58, 66, 54, 77,  100, 100, 100, 100, 100,  null, null, null),
        };

        System.out.println();
        System.out.printf("%-52s | %-13s | %-13s | %-13s | %-13s%n",
            "CAS", "A spec-emule", "B brut cov100", "C 3 modules", "main a la main");
        System.out.println("-".repeat(52) + "-+-" + "-".repeat(13) + "-+-" + "-".repeat(13)
            + "-+-" + "-".repeat(13) + "-+-" + "-".repeat(13));

        for (Case c : cases) {
            JobRoleProfile prof = p(c.type(), c.level());
            Map<String, Double> raw = modules(c.flex(), c.mem(), c.dec(), c.plan(), c.emo());
            // Variante A : mecanisme 1 du CdC emule a la main (score x couverture PAR MODULE)
            Map<String, Double> adj = modules(
                c.flex() * c.covFlex() / 100, c.mem() * c.covMem() / 100,
                c.dec() * c.covDec() / 100, c.plan() * c.covPlan() / 100,
                c.emo() * c.covEmo() / 100);

            FitScoreResult a = run(adj, prof, c.hardScore(), 100);
            FitScoreResult b = run(raw, prof, c.hardScore(), 100);
            FitScoreResult cc = run(reachable(raw), prof, c.hardScore(), 100);

            String hand = c.handFit() == null ? "  —"
                : String.format("%5.1f /%5.1f", c.handSoft(), c.handFit());

            System.out.printf("%-52s | %3d soft/%3d fit | %3d soft/%3d fit | %3d soft/%3d fit | %s%n",
                c.name(), a.softSkillScore(), a.score(), b.softSkillScore(), b.score(),
                cc.softSkillScore(), cc.score(), hand);
        }

        System.out.println("""

            A = 5 modules, couverture appliquee par module a la main (au plus pres du CdC)
            B = 5 modules, scores bruts, coverageRatio=100 (aucune couverture)
            C = 3 modules reellement produits par Games (MOVE_FAST/MEMORY_QUEST/PLANIFIK)
            main = mes chiffres calcules a la main avec la formule du CdC (Sigma poids = 100)
            """);

        // ── Verification ciblee : renormalisation ──
        System.out.println("=== Effet de la renormalisation, TECHNIQUE/MID, memes scores ===");
        JobRoleProfile tech = p(JobProfileType.TECHNIQUE, ExperienceLevel.MID);
        Map<String, Double> five = modules(82, 74, 68, 90, 55);
        System.out.printf("  5 modules            -> soft %d%n", run(five, tech, null, 100).softSkillScore());
        System.out.printf("  4 (sans DECISION)    -> soft %d%n",
            run(drop(five, "DECISION"), tech, null, 100).softSkillScore());
        System.out.printf("  3 (Games reel)       -> soft %d%n",
            run(reachable(five), tech, null, 100).softSkillScore());
        System.out.printf("  1 (MOVE_FAST seul)   -> soft %d   <- poids sans effet%n",
            run(drop(drop(drop(drop(five, "DECISION"), "EMOTIONAL_REGULATION"), "MEMORY_QUEST"), "PLANIFIK"),
                tech, null, 100).softSkillScore());

        // ── Verification ciblee : couverture globale ──
        System.out.println("\n=== coverageRatio global (mecanisme 1 tel qu'implemente) ===");
        for (int cov : new int[]{100, 80, 60, 40}) {
            FitScoreResult r = run(five, tech, 78, cov);
            System.out.printf("  couverture %3d%% -> soft %3d, fit %3d%n", cov, r.softSkillScore(), r.score());
        }

        // ── Verification ciblee : la courbe de niveau ──
        System.out.println("\n=== Meme candidat, meme QCM(78), TECHNIQUE aux 4 niveaux ===");
        for (ExperienceLevel l : ExperienceLevel.values()) {
            JobRoleProfile pr = p(JobProfileType.TECHNIQUE, l);
            FitScoreResult r = run(five, pr, 78, 100);
            System.out.printf("  %-10s hard=%2d%% -> soft %d, fit %d%n",
                l, pr.hardWeight(), r.softSkillScore(), r.score());
        }

        // ── Verification ciblee : meme candidat, les 6 profils au meme niveau ──
        System.out.println("\n=== Meme candidat (5 modules), 6 profils, niveau MID, sans QCM ===");
        for (JobProfileType t : JobProfileType.values()) {
            JobRoleProfile pr = p(t, ExperienceLevel.MID);
            System.out.printf("  %-14s -> soft %d  (5 mod) | soft %d  (3 mod Games)%n", t,
                run(five, pr, null, 100).softSkillScore(),
                run(reachable(five), pr, null, 100).softSkillScore());
        }

        // ── Profil non resolu ──
        System.out.println("\n=== Offre sans metier approuve ===");
        System.out.println("  resultat = " + run(five, null, 78, 100) + "  (null => rien n'est ecrit)");
    }

    static Map<String, Double> drop(Map<String, Double> m, String k) {
        Map<String, Double> c = new LinkedHashMap<>(m);
        c.remove(k);
        return c;
    }
}
