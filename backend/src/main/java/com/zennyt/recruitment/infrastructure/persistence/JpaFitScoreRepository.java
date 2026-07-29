package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.List;
import java.util.UUID;

public interface JpaFitScoreRepository extends JpaRepository<FitScoreEntity, UUID> {

    /** Le score le plus récent pour la paire — tolère d'éventuels doublons historiques. */
    Optional<FitScoreEntity> findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(
        UUID candidateId, UUID jobOfferId);

    @Modifying
    @Transactional
    @Query(value = """
        INSERT INTO recruitment.fit_scores
            (id, candidate_id, job_offer_id, score, soft_skill_score,
             hard_skill_score, coverage_ratio, computed_at)
        VALUES (:id, :candidateId, :jobOfferId, :score, :softSkillScore,
                :hardSkillScore, :coverageRatio, :computedAt)
        ON CONFLICT (candidate_id, job_offer_id) DO UPDATE SET
            score = EXCLUDED.score,
            soft_skill_score = EXCLUDED.soft_skill_score,
            hard_skill_score = EXCLUDED.hard_skill_score,
            coverage_ratio = EXCLUDED.coverage_ratio,
            computed_at = EXCLUDED.computed_at
        WHERE recruitment.fit_scores.computed_at <= EXCLUDED.computed_at
        """, nativeQuery = true)
    void upsert(UUID id, UUID candidateId, UUID jobOfferId, int score,
                Integer softSkillScore, Integer hardSkillScore,
                int coverageRatio, Instant computedAt);

    List<FitScoreEntity> findByJobOfferIdOrderByScoreDesc(UUID jobOfferId);

    int deleteByJobOfferId(UUID jobOfferId);

    List<FitScoreEntity> findByCandidateIdAndJobOfferIdIn(UUID candidateId, List<UUID> jobOfferIds);

    List<FitScoreEntity> findByCandidateIdInAndJobOfferIdIn(List<UUID> candidateIds, List<UUID> jobOfferIds);

    /**
     * Paires (candidat actif, offre ACTIVE) sans score — backlog du balayage de rattrapage.
     *
     * <p>SQL natif volontaire : anti-jointure sur un produit croisé, dont le plan doit rester
     * lisible et prévisible (même raison que l'upsert ci-dessus, qui est natif faute
     * d'équivalent JPQL). Tri par offre la plus anciennement en attente : les trous les plus
     * vieux se résorbent en premier, et l'index {@code (status, posted_at)} permet au planner
     * de s'arrêter dès qu'il a {@code limit} lignes.
     *
     * <p><b>La jointure sur {@code job_positions} est un filtre de correctness, pas de
     * préférence</b> : sans métier au profil assigné, la formule n'a pas de pondération et
     * la paire est <i>incalculable</i>, pas « en attente ». L'inclure ferait resélectionner
     * indéfiniment une paire qu'aucun passage ne peut résoudre, consommant le budget du lot
     * à chaque tour. Dès qu'un admin approuve le métier ({@code profile_type} renseigné), les
     * paires concernées réapparaissent ici et sont calculées au passage suivant — sans
     * mécanisme dédié.
     *
     * <p>Aucun tri par activité candidat : le seul horodatage disponible
     * ({@code actors.last_event_at}) est réécrit pour <b>tous</b> les utilisateurs à chaque
     * démarrage par {@code IdentityAccessSnapshotPublisher}, il ne porte donc aucune
     * information d'activité réelle.
     */
    @Query(value = """
        SELECT a.public_user_id, j.id
        FROM recruitment.job_offers j
        JOIN recruitment.job_positions p
          ON p.id = j.job_position_id AND p.profile_type IS NOT NULL
        CROSS JOIN recruitment.actors a
        LEFT JOIN recruitment.fit_scores f
          ON f.job_offer_id = j.id AND f.candidate_id = a.public_user_id
        WHERE j.status = 'ACTIVE'
          AND a.role = 'CANDIDATE'
          AND a.active = TRUE
          AND f.id IS NULL
        ORDER BY j.posted_at ASC
        LIMIT :limit
        """, nativeQuery = true)
    List<Object[]> findPairsNeedingScore(int limit);

    /**
     * Paires dont le score existe mais est devenu <b>faux</b> — le balayage doit les
     * reprendre, sinon on remplace un trou de couverture par un trou de fraîcheur
     * (un déclencheur ne rafraîchit que 20 paires : les autres gardent l'ancien profil).
     *
     * <p>Un score est périmé s'il a été calculé avant la dernière évolution d'une de ses
     * trois sources : l'offre, les soft skills du candidat, ou son résultat de test pour
     * cette offre. On compare des horodatages <b>déjà maintenus</b> par le code existant
     * plutôt que d'ajouter des colonnes de version à incrémenter : oublier un seul site
     * d'incrément recréerait le bug d'origine, en silence.
     *
     * <p>Contrairement à {@link #findPairsNeedingScore}, cette requête ne parcourt que les
     * scores existants (pas de produit croisé). Les deux sous-requêtes corrélées sont
     * couvertes par des index uniques existants :
     * {@code soft_skills_projection (candidate_id, module)} et
     * {@code test_results (candidate_id, job_offer_id)}.
     *
     * <p>Converge : un recalcul porte {@code computed_at} à maintenant, donc au-dessus des
     * trois sources — la paire cesse d'être sélectionnée.
     */
    @Query(value = """
        SELECT f.candidate_id, f.job_offer_id
        FROM recruitment.fit_scores f
        JOIN recruitment.job_offers j ON j.id = f.job_offer_id
        JOIN recruitment.job_positions p
          ON p.id = j.job_position_id AND p.profile_type IS NOT NULL
        JOIN recruitment.actors a ON a.public_user_id = f.candidate_id
        WHERE j.status = 'ACTIVE'
          AND a.role = 'CANDIDATE'
          AND a.active = TRUE
          AND (
               f.computed_at < j.updated_at
            OR f.computed_at < (SELECT MAX(s.updated_at)
                                FROM recruitment.soft_skills_projection s
                                WHERE s.candidate_id = f.candidate_id)
            OR f.computed_at < (SELECT MAX(t.completed_at)
                                FROM recruitment.test_results t
                                WHERE t.candidate_id = f.candidate_id
                                  AND t.job_offer_id = f.job_offer_id)
          )
        ORDER BY f.computed_at ASC
        LIMIT :limit
        """, nativeQuery = true)
    List<Object[]> findStalePairs(int limit);

    /**
     * Profondeur du retard — mêmes critères que {@link #findPairsNeedingScore} et
     * {@link #findStalePairs} réunis, mais sans {@code LIMIT} : c'est un indicateur de
     * supervision, pas une sélection de travail.
     */
    @Query(value = """
        SELECT
          (SELECT count(*)
           FROM recruitment.job_offers j
           JOIN recruitment.job_positions p
             ON p.id = j.job_position_id AND p.profile_type IS NOT NULL
           CROSS JOIN recruitment.actors a
           LEFT JOIN recruitment.fit_scores f
             ON f.job_offer_id = j.id AND f.candidate_id = a.public_user_id
           WHERE j.status = 'ACTIVE'
             AND a.role = 'CANDIDATE'
             AND a.active = TRUE
             AND f.id IS NULL)
          +
          (SELECT count(*)
           FROM recruitment.fit_scores f
           JOIN recruitment.job_offers j ON j.id = f.job_offer_id
           JOIN recruitment.job_positions p
             ON p.id = j.job_position_id AND p.profile_type IS NOT NULL
           JOIN recruitment.actors a ON a.public_user_id = f.candidate_id
           WHERE j.status = 'ACTIVE'
             AND a.role = 'CANDIDATE'
             AND a.active = TRUE
             AND (
                  f.computed_at < j.updated_at
               OR f.computed_at < (SELECT MAX(s.updated_at)
                                   FROM recruitment.soft_skills_projection s
                                   WHERE s.candidate_id = f.candidate_id)
               OR f.computed_at < (SELECT MAX(t.completed_at)
                                   FROM recruitment.test_results t
                                   WHERE t.candidate_id = f.candidate_id
                                     AND t.job_offer_id = f.job_offer_id)
             ))
        """, nativeQuery = true)
    long countPairsNeedingScore();
}
