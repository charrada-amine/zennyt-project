package com.zennyt.recruitment.domain.vo;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Estime le niveau hard skills d'un candidat sur un métier, à partir de <b>tout</b> son
 * historique de tests sur ce métier (décisions D1 à D4).
 *
 * <p><b>Pondération par rang, jamais par âge.</b> Le poids d'un test dépend de sa position
 * dans l'historique (1, ½, ¼, …), pas de son ancienneté en jours. Ce n'est pas une
 * simplification : une pondération par l'âge ferait changer le score <b>tous les jours sans
 * qu'aucun événement ne survienne</b>, or la détection de péremption compare
 * {@code fit_scores.computed_at} aux horodatages des sources. Chaque score deviendrait
 * périmé en permanence et la file de travail ne se viderait jamais. Le poids par rang ne
 * bouge qu'à la soumission d'un test — un événement déjà géré.
 *
 * <p><b>Propriété tenue par la suite géométrique</b> : la somme des poids des tests plus
 * anciens est toujours strictement inférieure à 1, donc le test de rang 1 pèse
 * <b>toujours plus de la moitié</b>, quel que soit le nombre de tests. L'historique compte
 * sans jamais pouvoir écraser le présent.
 *
 * <p><b>Non gamable</b> : pour faire monter son estimation il faut battre sa propre moyenne
 * pondérée, et un mauvais résultat entre dans l'historique sans jamais en ressortir.
 * Une agrégation par le maximum, elle, récompenserait la multiplication des tentatives.
 */
public final class HardSkillLevelEstimate {

    /**
     * Garde-fou de boucle, pas une politique : au rang 32 le poids vaut 2⁻³² ≈ 2,3e-10, et
     * la somme de <i>tous</i> les rangs suivants reste sous 4,7e-10. Sur une échelle 0-100
     * arrondie à l'entier, leur effet cumulé est nul. Borner évite simplement de parcourir
     * un historique pathologique pour un résultat identique.
     */
    static final int RANGS_SIGNIFICATIFS = 32;

    private HardSkillLevelEstimate() {}

    /**
     * @param history          historique du candidat sur le métier — l'appelant a déjà exclu
     *                         les tentatives abandonnées (D4)
     * @param offreConsulteeId offre en cours d'évaluation ; son test remonte au rang 1 même
     *                         s'il est plus ancien (D3). {@code null} quand l'estimation ne
     *                         se rattache à aucune offre (résumé IA, qui est par métier).
     * @return l'estimation 0-100, ou {@code null} si l'historique est vide — une absence de
     *         donnée n'est pas un zéro, et le calculateur bascule alors en soft seul.
     */
    public static Integer estimate(List<HardSkillHistoryEntry> history, UUID offreConsulteeId) {
        if (history == null || history.isEmpty()) return null;

        List<HardSkillHistoryEntry> ordonnes = history.stream()
            .sorted(ordreDeRang(offreConsulteeId))
            .limit(RANGS_SIGNIFICATIFS)
            .toList();

        double numerateur = 0;
        double denominateur = 0;
        double poids = 1;
        for (HardSkillHistoryEntry entry : ordonnes) {
            numerateur += entry.percentage() * poids;
            denominateur += poids;
            poids /= 2;
        }
        return (int) Math.round(numerateur / denominateur);
    }

    /**
     * Rang 1 = le test de l'offre consultée s'il existe (D3), puis du plus récent au plus
     * ancien.
     *
     * <p>Sans la première clause, un candidat effacerait un mauvais résultat sur une offre
     * en passant un test ailleurs sur le même métier. Elle a un second effet, utile :
     * elle conserve une différenciation du score entre les offres d'un même métier.
     *
     * <p>Départage final par identifiant d'offre : deux tests soumis à la même
     * milliseconde donneraient sinon un ordre dépendant de la base, donc un score non
     * reproductible.
     */
    private static Comparator<HardSkillHistoryEntry> ordreDeRang(UUID offreConsulteeId) {
        return Comparator
            .comparing((HardSkillHistoryEntry e) -> !e.jobOfferId().equals(offreConsulteeId))
            .thenComparing(HardSkillHistoryEntry::completedAt, Comparator.reverseOrder())
            .thenComparing(e -> e.jobOfferId().toString());
    }
}
