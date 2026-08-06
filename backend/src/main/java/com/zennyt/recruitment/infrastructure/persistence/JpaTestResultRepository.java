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
    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    Page<TestResultEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByJobOfferId(UUID jobOfferId);
    List<TestResultEntity> findAllByJobOfferId(UUID jobOfferId);
}
