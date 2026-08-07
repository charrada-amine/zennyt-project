package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaTestResultRepository extends JpaRepository<TestResultEntity, UUID> {
    Optional<TestResultEntity> findFirstByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    /**
     * Résultats des paires exactes fournies — jamais leur produit croisé.
     *
     * <p>SQL natif volontaire : {@code unnest} de deux tableaux <b>parallèles</b> les zippe
     * en paires (élément i avec élément i), là où {@code IN (...) AND IN (...)} les croise.
     * Effet secondaire précieux : deux paramètres liés quelle que soit la taille du lot, au
     * lieu d'un par identifiant — la limite de 65 535 paramètres du protocole PostgreSQL
     * n'est donc jamais un plafond. Les listes sont transmises en chaînes séparées par des
     * virgules puis reconverties, ce qui évite toute dépendance à la liaison de tableaux JDBC.
     */
    @Query(value = """
        SELECT t.* FROM recruitment.test_results t
        JOIN unnest(
                 string_to_array(:candidateIds, ',')::uuid[],
                 string_to_array(:jobOfferIds, ',')::uuid[]
             ) AS p(candidate_id, job_offer_id)
          ON t.candidate_id = p.candidate_id AND t.job_offer_id = p.job_offer_id
        """, nativeQuery = true)
    List<TestResultEntity> findByPairs(String candidateIds, String jobOfferIds);

    /**
     * Historique noté d'un candidat sur un métier (D1) — la jointure sur {@code job_offers}
     * est ce qui fait passer la lecture de « le test de cette offre » à « ses tests de ce
     * métier ».
     *
     * <p>{@code ABANDONED} exclu par le filtre de statut (D4). Le niveau de l'offre source
     * remonte avec chaque ligne : il sera affiché à côté d'un score emprunté (D5).
     */
    @Query(value = """
        SELECT t.candidate_id, o.job_position_id, t.job_offer_id,
               t.percentage, t.passed, t.completed_at, o.experience_level
        FROM recruitment.test_results t
        JOIN recruitment.job_offers o ON o.id = t.job_offer_id
        WHERE t.candidate_id = :candidateId
          AND o.job_position_id = :jobPositionId
          AND t.status IN ('COMPLETED', 'TIMEOUT')
        ORDER BY t.completed_at DESC
        """, nativeQuery = true)
    List<Object[]> findHardSkillHistory(UUID candidateId, UUID jobPositionId);

    /**
     * Variante par lot — même zip par {@code unnest} de deux tableaux parallèles que
     * {@link #findByPairs}, donc deux paramètres liés quelle que soit la taille du lot.
     *
     * <p>Renvoie <b>N lignes par couple</b> : c'est l'historique complet, pas une valeur
     * par couple. Le regroupement se fait côté appelant.
     */
    @Query(value = """
        SELECT t.candidate_id, o.job_position_id, t.job_offer_id,
               t.percentage, t.passed, t.completed_at, o.experience_level
        FROM recruitment.test_results t
        JOIN recruitment.job_offers o ON o.id = t.job_offer_id
        JOIN unnest(
                 string_to_array(:candidateIds, ',')::uuid[],
                 string_to_array(:jobPositionIds, ',')::uuid[]
             ) AS c(candidate_id, job_position_id)
          ON t.candidate_id = c.candidate_id AND o.job_position_id = c.job_position_id
        WHERE t.status IN ('COMPLETED', 'TIMEOUT')
        ORDER BY t.completed_at DESC
        """, nativeQuery = true)
    List<Object[]> findHardSkillHistoryByCouples(String candidateIds, String jobPositionIds);

    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    Page<TestResultEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByJobOfferId(UUID jobOfferId);
    List<TestResultEntity> findAllByJobOfferId(UUID jobOfferId);
}
