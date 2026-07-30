package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Mesures brutes de « Je Décide » (prise de décision).
 *
 * <p>Le client envoie des <b>mesures</b> par item (jamais de points) + le contexte
 * de session. Le domaine ({@code DecisionScoringService}) note chaque item /3 via
 * le catalogue (qualité de l'option), agrège /18 puis /90, standardise en SCW /100
 * et dérive les indicateurs. La règle DT (temps) et le calibrage appareil
 * (existant) affectent la note des items DT.
 *
 * @param items              réponses mesurées, un élément par item (répondus + non répondus)
 * @param sessionLanguage    code langue de passation (multiplicateur DT ; en/fr/de fournis)
 * @param administrationMode passation supervisée/autonome (contrôles renforcés si autonome)
 * @param age                post-test — âge (⚠️ échelle à préciser, tracé)
 * @param educationLevel     post-test — niveau d'éducation (⚠️ échelle à préciser, tracé)
 * @param fatigue            post-test — fatigue auto-rapportée (⚠️ échelle à préciser, tracé)
 * @param motivation         post-test — motivation auto-rapportée (⚠️ échelle à préciser, tracé)
 */
public record DecisionMetrics(
    List<DecisionItemResponse> items,
    String sessionLanguage,
    AdministrationMode administrationMode,
    Integer age,
    String educationLevel,
    Integer fatigue,
    Integer motivation
) implements GameMetrics {

    public DecisionMetrics {
        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException("items requis (au moins un item)");
        }
        items = List.copyOf(items);
        if (administrationMode == null) {
            administrationMode = AdministrationMode.SUPERVISED;
        }
    }

    /** Fabrique minimale (langue en, supervisé, sans post-test) — parité mock/tests. */
    public static DecisionMetrics of(List<DecisionItemResponse> items, String sessionLanguage) {
        return new DecisionMetrics(items, sessionLanguage, AdministrationMode.SUPERVISED,
            null, null, null, null);
    }

    /** Items répondus (les non répondus déclenchent l'imputation). */
    public List<DecisionItemResponse> answeredItems() {
        return items.stream().filter(DecisionItemResponse::answered).toList();
    }
}
