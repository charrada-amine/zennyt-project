package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.config.IstProvisionalRules;
import com.zennyt.games.domain.vo.IstColor;

/**
 * P(correct) — probabilité que la couleur choisie soit majoritaire, au vu des cases
 * ouvertes, sous la loi de génération RÉELLE des grilles.
 *
 * <p>Postérieur exact par énumération sur le nombre total de cases bleues {@code k} :
 * <pre>
 *   P(k | a bleues, b orange vues) ∝ prior(k) × C(25 − n, k − a) / C(25, k)
 * </pre>
 * où {@code C(25 − n, k − a) / C(25, k)} est la probabilité que CES n cases précises
 * montrent ces couleurs quand {@code k} bleues sont placées uniformément. Le
 * placement étant uniforme, la vraisemblance ne dépend que des comptes (a, b) :
 * l'ordre d'ouverture n'y change rien POUR NOTRE GÉNÉRATEUR.
 *
 * <p>Pourquoi pas la formule publiée : le calcul conventionnel est contesté (Bennett
 * et al., 2017) et le débat porte sur l'a priori (Axelsen, Jepsen &amp; Bak, 2018).
 * Nous connaissons l'a priori exact puisque nous générons les grilles : le calcul
 * ci-dessus est correct par construction pour cette tâche. À confirmer par le
 * psychologue (preuves §3.3, §9).
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : même boucle, même ordre d'accumulation dans
 * {@code mobile/lib/features/games/data/decision_behavioral_scoring.dart}. Les
 * coefficients binomiaux ≤ C(25, 12) = 5 200 300 sont exacts en double.
 */
public final class IstPosteriorModel {

    private static final double[][] BINOMIAL = pascal(IstConfig.BOX_COUNT);

    public double pCorrect(int blueSeen, int orangeSeen, IstColor chosen) {
        int opened = blueSeen + orangeSeen;
        if (blueSeen < 0 || orangeSeen < 0 || opened > IstConfig.BOX_COUNT) {
            throw new IllegalArgumentException("Comptes de cases invalides");
        }
        int remaining = IstConfig.BOX_COUNT - opened;
        double[] prior = IstProvisionalRules.blueCountPrior();
        double favourable = 0.0;
        double total = 0.0;
        for (int k = 0; k <= IstConfig.BOX_COUNT; k++) {
            if (prior[k] == 0.0) continue;
            int blueRemaining = k - blueSeen;
            if (blueRemaining < 0 || blueRemaining > remaining) continue;
            double weight = prior[k] * BINOMIAL[remaining][blueRemaining]
                / BINOMIAL[IstConfig.BOX_COUNT][k];
            total += weight;
            IstColor majority = k >= IstConfig.MAJORITY_THRESHOLD
                ? IstColor.BLUE : IstColor.ORANGE;
            if (majority == chosen) favourable += weight;
        }
        if (total == 0.0) {
            throw new IllegalArgumentException(
                "Observation impossible sous la loi de génération des grilles");
        }
        return favourable / total;
    }

    private static double[][] pascal(int size) {
        double[][] table = new double[size + 1][size + 1];
        for (int n = 0; n <= size; n++) {
            table[n][0] = 1.0;
            for (int k = 1; k <= n; k++) {
                table[n][k] = table[n - 1][k - 1] + (k <= n - 1 ? table[n - 1][k] : 0.0);
            }
        }
        return table;
    }
}
