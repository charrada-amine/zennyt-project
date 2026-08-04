import com.zennyt.recruitment.application.port.FitScoreCalculatorPort.FitScoreInputs;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.recruitment.infrastructure.ai.DeterministicFitScoreCalculator;
import java.util.*;

public class Bug {
    static final DeterministicFitScoreCalculator C = new DeterministicFitScoreCalculator();
    static int soft(Map<String,Double> m, JobRoleProfile p) {
        return C.calculate(new FitScoreInputs(m, "d", "c", p, null, 100)).softSkillScore();
    }
    public static void main(String[] a) {
        JobRoleProfile tech = FitScoreHarness.p(JobProfileType.TECHNIQUE, ExperienceLevel.MID);
        System.out.println("Profil TECHNIQUE/MID, modules 30/20/30/15/5\n");
        System.out.println("A) cle de module NON reconnue, seule :");
        System.out.println("   {FUTUR_JEU: 90}                -> soft " + soft(Map.of("FUTUR_JEU",90.0), tech));
        System.out.println("   {FUTUR_JEU: 10}                -> soft " + soft(Map.of("FUTUR_JEU",10.0), tech));
        System.out.println("   => la cle inconnue pilote INTEGRALEMENT le score, sans ponderation\n");

        System.out.println("B) melange connu + inconnu (le connu doit dominer) :");
        Map<String,Double> mix = new LinkedHashMap<>();
        mix.put("MOVE_FAST", 40.0); mix.put("FUTUR_JEU", 90.0);
        System.out.println("   {MOVE_FAST:40, FUTUR_JEU:90}   -> soft " + soft(mix, tech) + "   (correct : 40)\n");

        System.out.println("C) aucune donnee du tout :");
        System.out.println("   {}                             -> soft " + soft(Map.of(), tech)
            + "   (absence traitee comme un 0 mesure)");
    }
}
