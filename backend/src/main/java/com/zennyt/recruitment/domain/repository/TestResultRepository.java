package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;

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
     * Page de résultats pour une offre (vue liste recruteur).
     * @param sort {@code "champ,direction"} (ex. {@code "completedAt,desc"}) — {@code null}/vide
     *             ou champ non reconnu retombe sur le tri par défaut (contrat squad web §7.2).
     */
    List<TestResult> findByJobOfferId(UUID jobOfferId, String sort, int page, int size);

    long countByJobOfferId(UUID jobOfferId);

    /** Ensemble complet des résultats d'une offre — pour l'agrégat summary, jamais paginé. */
    List<TestResult> findAllByJobOfferId(UUID jobOfferId);
}
