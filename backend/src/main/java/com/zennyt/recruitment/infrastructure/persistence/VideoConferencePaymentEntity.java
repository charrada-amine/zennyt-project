package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.PaymentStatus;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "video_conference_payments", schema = "recruitment")
public class VideoConferencePaymentEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID recruiterId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID matchId;
    private double amount;
    private double tax;
    private double total;
    @Column(nullable = false) private String currency;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private PaymentStatus status;
    private String paymentMethodLast4;
    private String paymentMethodType;
    private boolean otpVerified;
    @Column(nullable = false) private Instant createdAt;
    private Instant confirmedAt;

    protected VideoConferencePaymentEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID v) { this.id = v; }
    public UUID getRecruiterId() { return recruiterId; }
    public void setRecruiterId(UUID v) { this.recruiterId = v; }
    public UUID getCandidateId() { return candidateId; }
    public void setCandidateId(UUID v) { this.candidateId = v; }
    public UUID getMatchId() { return matchId; }
    public void setMatchId(UUID v) { this.matchId = v; }
    public double getAmount() { return amount; }
    public void setAmount(double v) { this.amount = v; }
    public double getTax() { return tax; }
    public void setTax(double v) { this.tax = v; }
    public double getTotal() { return total; }
    public void setTotal(double v) { this.total = v; }
    public String getCurrency() { return currency; }
    public void setCurrency(String v) { this.currency = v; }
    public PaymentStatus getStatus() { return status; }
    public void setStatus(PaymentStatus v) { this.status = v; }
    public String getPaymentMethodLast4() { return paymentMethodLast4; }
    public void setPaymentMethodLast4(String v) { this.paymentMethodLast4 = v; }
    public String getPaymentMethodType() { return paymentMethodType; }
    public void setPaymentMethodType(String v) { this.paymentMethodType = v; }
    public boolean isOtpVerified() { return otpVerified; }
    public void setOtpVerified(boolean v) { this.otpVerified = v; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant v) { this.createdAt = v; }
    public Instant getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(Instant v) { this.confirmedAt = v; }
}
