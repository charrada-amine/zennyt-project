package com.zennyt.analytics.infrastructure.persistence;

import com.zennyt.analytics.domain.repository.AnalyticsReadRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Component
public class JdbcAnalyticsReadRepository implements AnalyticsReadRepository {

    private final JdbcTemplate jdbc;

    public JdbcAnalyticsReadRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public long countCandidateActivity(UUID candidateId, String kind) {
        Long count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM analytics.candidate_activity WHERE candidate_id = ? AND kind = ?",
            Long.class, candidateId, kind);
        return count == null ? 0 : count;
    }

    @Override
    public Map<String, Long> candidateActivityByKind(UUID candidateId) {
        return jdbc.query(
            "SELECT kind, COUNT(*) AS total FROM analytics.candidate_activity "
                + "WHERE candidate_id = ? GROUP BY kind",
            rs -> {
                Map<String, Long> result = new HashMap<>();
                while (rs.next()) {
                    result.put(rs.getString("kind"), rs.getLong("total"));
                }
                return result;
            }, candidateId);
    }

    @Override
    public long countOffersByRecruiter(UUID recruiterId) {
        Long count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM analytics.job_offer_projection WHERE recruiter_id = ?",
            Long.class, recruiterId);
        return count == null ? 0 : count;
    }

    @Override
    public long countActiveOffersByRecruiter(UUID recruiterId) {
        Long count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM analytics.job_offer_projection "
                + "WHERE recruiter_id = ? AND status = 'ACTIVE'",
            Long.class, recruiterId);
        return count == null ? 0 : count;
    }

    @Override
    public long countApplicationsForRecruiter(UUID recruiterId) {
        Long count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM analytics.candidate_activity a "
                + "JOIN analytics.job_offer_projection j ON j.job_offer_id = a.job_offer_id "
                + "WHERE j.recruiter_id = ? AND a.kind = 'INTERESTED'",
            Long.class, recruiterId);
        return count == null ? 0 : count;
    }

    @Override
    public long countApplicationsForOffer(UUID jobOfferId) {
        Long count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM analytics.candidate_activity "
                + "WHERE job_offer_id = ? AND kind = 'INTERESTED'",
            Long.class, jobOfferId);
        return count == null ? 0 : count;
    }
}
