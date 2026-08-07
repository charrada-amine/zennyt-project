package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.repository.FitScoreWorkQueueRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * File de travail en SQL direct.
 *
 * <p>{@code JdbcTemplate} plutôt que JPA, volontairement : {@code FOR UPDATE SKIP LOCKED}
 * et {@code ON CONFLICT DO NOTHING} n'ont pas d'équivalent portable en JPQL, et une file
 * de travail n'a pas d'identité de domaine à gérer — ce sont des lignes qu'on réserve et
 * qu'on relâche, pas des agrégats. Même raisonnement que l'upsert natif des Fit Scores.
 */
@Component
public class FitScoreWorkQueueRepositoryAdapter implements FitScoreWorkQueueRepository {

    private final JdbcTemplate jdbc;

    public FitScoreWorkQueueRepositoryAdapter(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Override
    @Transactional
    public int enqueue(List<CandidateOfferPair> pairs, int priority) {
        if (pairs.isEmpty()) return 0;
        int[][] résultats = jdbc.batchUpdate("""
            INSERT INTO recruitment.fitscore_work_queue
                (candidate_id, job_offer_id, priority, status)
            VALUES (?, ?, ?, 'PENDING')
            ON CONFLICT (candidate_id, job_offer_id) WHERE status = 'PENDING' DO NOTHING
            """, pairs, pairs.size(), (ps, pair) -> {
                ps.setObject(1, pair.candidateId());
                ps.setObject(2, pair.jobOfferId());
                ps.setInt(3, priority);
            });
        int inserees = 0;
        for (int[] lot : résultats) for (int n : lot) if (n > 0) inserees += n;
        return inserees;
    }

    /**
     * {@code SKIP LOCKED} laisse un worker sauter les lignes qu'un autre traite déjà, au
     * lieu d'attendre son verrou. Sans lui, deux workers se sérialiseraient et le
     * parallélisme ne servirait à rien.
     */
    @Override
    @Transactional
    public List<QueuedPair> claim(int limit) {
        if (limit <= 0) return List.of();
        return jdbc.query("""
            SELECT id, candidate_id, job_offer_id
            FROM recruitment.fitscore_work_queue
            WHERE status = 'PENDING'
              AND (next_retry_at IS NULL OR next_retry_at <= now())
            ORDER BY priority, created_at
            LIMIT ?
            FOR UPDATE SKIP LOCKED
            """, (rs, rowNum) -> new QueuedPair(
                rs.getLong("id"),
                new CandidateOfferPair(
                    rs.getObject("candidate_id", UUID.class),
                    rs.getObject("job_offer_id", UUID.class))),
            limit);
    }

    @Override
    @Transactional
    public void complete(List<Long> ids) {
        if (ids.isEmpty()) return;
        jdbc.batchUpdate(
            "UPDATE recruitment.fitscore_work_queue SET status = 'DONE' WHERE id = ?",
            ids, ids.size(), (ps, id) -> ps.setLong(1, id));
    }

    /**
     * Backoff exponentiel : 1s, 4s, 16s… Au-delà de {@code maxAttempts} la ligne passe en
     * {@code FAILED} et n'est plus réservée. Elle n'est pas perdue pour autant — le calcul
     * à l'affichage la reprendra.
     */
    @Override
    @Transactional
    public void fail(long id, String error, int maxAttempts) {
        jdbc.update("""
            UPDATE recruitment.fitscore_work_queue
            SET attempts = attempts + 1,
                last_error = ?,
                status = CASE WHEN attempts + 1 >= ? THEN 'FAILED' ELSE 'PENDING' END,
                next_retry_at = now() + (power(4, attempts) * interval '1 second')
            WHERE id = ?
            """, error == null ? null : error.substring(0, Math.min(error.length(), 1000)),
            maxAttempts, id);
    }

    @Override
    public long depth(int priority) {
        Long n = jdbc.queryForObject("""
            SELECT count(*) FROM recruitment.fitscore_work_queue
            WHERE status = 'PENDING' AND priority = ?
            """, Long.class, priority);
        return n == null ? 0 : n;
    }

    @Override
    public long oldestPendingAgeSeconds() {
        Long n = jdbc.queryForObject("""
            SELECT COALESCE(EXTRACT(EPOCH FROM (now() - min(created_at)))::bigint, 0)
            FROM recruitment.fitscore_work_queue WHERE status = 'PENDING'
            """, Long.class);
        return n == null ? 0 : n;
    }

    @Override
    public long failedCount() {
        Long n = jdbc.queryForObject(
            "SELECT count(*) FROM recruitment.fitscore_work_queue WHERE status = 'FAILED'",
            Long.class);
        return n == null ? 0 : n;
    }
}
