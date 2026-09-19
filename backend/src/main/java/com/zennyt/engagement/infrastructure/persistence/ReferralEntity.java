package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.ReferralStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.Check;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "referrals", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "uq_referrals_referrer_email", columnNames = {"referrer_user_id", "invitee_email"}),
    indexes = @Index(name = "idx_referrals_referrer", columnList = "referrer_user_id"))
@Check(name = "ck_referrals_status", constraints = "status IN ('INVITED', 'REGISTERED', 'HIRED', 'CANCELLED')")
class ReferralEntity {
    @Id private UUID id;
    @Column(name = "referrer_user_id", nullable = false) private UUID referrerUserId;
    @Column(name = "invitee_email", nullable = false, length = 150) private String inviteeEmail;
    @Column(name = "invitee_user_id") private UUID inviteeUserId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private ReferralStatus status;
    @Column(name = "hired_at") private Instant hiredAt;
    @Column(name = "probation_ends_at") private Instant probationEndsAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;

    protected ReferralEntity() {}

    ReferralEntity(UUID id, UUID referrerUserId, String inviteeEmail, UUID inviteeUserId,
                   ReferralStatus status, Instant hiredAt, Instant probationEndsAt,
                   Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.referrerUserId = referrerUserId;
        this.inviteeEmail = inviteeEmail;
        this.inviteeUserId = inviteeUserId;
        this.status = status;
        this.hiredAt = hiredAt;
        this.probationEndsAt = probationEndsAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    UUID getId() { return id; }
    UUID getReferrerUserId() { return referrerUserId; }
    String getInviteeEmail() { return inviteeEmail; }
    UUID getInviteeUserId() { return inviteeUserId; }
    ReferralStatus getStatus() { return status; }
    Instant getHiredAt() { return hiredAt; }
    Instant getProbationEndsAt() { return probationEndsAt; }
    Instant getCreatedAt() { return createdAt; }
    Instant getUpdatedAt() { return updatedAt; }
}
