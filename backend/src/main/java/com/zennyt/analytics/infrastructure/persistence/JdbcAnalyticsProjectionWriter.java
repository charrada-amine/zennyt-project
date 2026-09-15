package com.zennyt.analytics.infrastructure.persistence;

import com.zennyt.analytics.domain.repository.AnalyticsProjectionWriter;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;

@Component
public class JdbcAnalyticsProjectionWriter implements AnalyticsProjectionWriter {

    private final JdbcTemplate jdbc;

    public JdbcAnalyticsProjectionWriter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void upsertJobOffer(UUID jobOfferId, UUID recruiterId, String status, Instant occurredAt) {
        jdbc.update("""
            INSERT INTO analytics.job_offer_projection
                (job_offer_id, recruiter_id, status, posted_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT (job_offer_id) DO UPDATE SET
                recruiter_id = EXCLUDED.recruiter_id,
                status = EXCLUDED.status,
                updated_at = EXCLUDED.updated_at
            """, jobOfferId, recruiterId, status, Timestamp.from(occurredAt),
            Timestamp.from(occurredAt));
    }

    @Override
    public void updateJobOfferStatus(UUID jobOfferId, String status, Instant occurredAt) {
        jdbc.update(
            "UPDATE analytics.job_offer_projection SET status = ?, updated_at = ? "
                + "WHERE job_offer_id = ?",
            status, Timestamp.from(occurredAt), jobOfferId);
    }

    @Override
    public void recordCandidateActivity(UUID candidateId, UUID jobOfferId, String kind,
                                        Instant occurredAt) {
        jdbc.update("""
            INSERT INTO analytics.candidate_activity
                (candidate_id, job_offer_id, kind, occurred_at)
            VALUES (?, ?, ?, ?)
            """, candidateId, jobOfferId, kind, Timestamp.from(occurredAt));
    }
}
