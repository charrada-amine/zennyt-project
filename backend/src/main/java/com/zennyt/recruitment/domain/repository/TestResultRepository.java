package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.vo.CandidateJobPositionCouple;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Port du repository de résultats de test de compétences. */
public interface TestResultRepository {

    TestResult save(TestResult result);

    Optional<TestResult> findById(UUID id);

    Optional<TestResult> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    /**
     * Variante par lot de {@link #findByCandidateIdAndJobOfferId} — une seule requête pour
     * tout un lot de recalcul.
     *
     * <p>Cible <b>exactement</b> les paires demandées : ni sur-lecture, ni filtrage en
     * mémoire côté appelant. Voir {@link CandidateOfferPair} pour ce que faisait la
     * signature précédente (deux listes séparées) et pourquoi elle bornait la taille de lot.
     */
    List<TestResult> findByPairs(List<CandidateOfferPair> pairs);

    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    /**
     * Historique des tests notés d'un candidat sur un métier, du plus récent au plus ancien
     * (décision D1 : « même domaine » = même {@code jobPositionId}).
     *
     * <p>Ne remonte que les statuts {@code COMPLETED} et {@code TIMEOUT} — un
     * {@code TIMEOUT} est un résultat noté, un {@code ABANDONED} n'en est pas un (D4).
     * L'ordre du tri sert la lisibilité ; le rang effectif est décidé par
     * {@link com.zennyt.recruitment.domain.vo.HardSkillLevelEstimate}, qui peut remonter le
     * test de l'offre consultée au rang 1.
     */
    List<HardSkillHistoryEntry> findHardSkillHistory(UUID candidateId, UUID jobPositionId);

    /**
     * Variante par lot de {@link #findHardSkillHistory} — une seule requête pour tous les
     * couples du lot, sur le même principe de zip que {@link #findByPairs}.
     *
     * <p>Différence à noter : cette lecture renvoie <b>N lignes par couple</b>, pas une.
     * C'est voulu — c'est l'historique complet qui produit l'estimation. Le regroupement
     * par couple est à la charge de l'appelant.
     */
    List<HardSkillHistoryEntry> findHardSkillHistoryByCouples(List<CandidateJobPositionCouple> couples);

    /**
     * Page de résultats pour une offre (vue liste recruteur).
     * @param sort {@code "champ,direction"} (ex. {@code "completedAt,desc"}) — {@code null}/vide
     *             ou champ non reconnu retombe sur le tri par défaut (contrat squad web §7.2).
     */
    List<TestResult> findByJobOfferId(UUID jobOfferId, String sort, int page, int size);

    long countByJobOfferId(UUID jobOfferId);

    /** Ensemble complet des résultats d'une offre — pour l'agrégat summary, jamais paginé. */
    List<TestResult> findAllByJobOfferId(UUID jobOfferId);
}
