package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.VideoConferencePaymentConfirmedEvent;
import com.zennyt.recruitment.domain.vo.Money;
import com.zennyt.recruitment.domain.vo.PaymentStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Paiement visioconférence — 9,99 EUR + taxe.
 *
 * <p>Flux : initiation → OTP SMS envoyé → vérification OTP → confirmé.
 * Publie {@code VideoConferencePaymentConfirmedEvent} qui permet au contexte
 * Engagement de débloquer l'appel vidéo.
 */
public class VideoConferencePayment extends AggregateRoot {

    private final UUID id;
    private final UUID recruiterId;
    private final UUID candidateId;
    private final UUID matchId;
    private Money amount;
    private Money tax;
    private Money total;
    private PaymentStatus status;
    private String paymentMethodLast4;
    private String paymentMethodType;
    private boolean otpVerified;
    private final Instant createdAt;
    private Instant confirmedAt;

    private VideoConferencePayment(UUID id, UUID recruiterId, UUID candidateId, UUID matchId,
                                   Money amount, Money tax) {
        this.id = id;
        this.recruiterId = recruiterId;
        this.candidateId = candidateId;
        this.matchId = matchId;
        this.amount = amount;
        this.tax = tax;
        this.total = amount.add(tax);
        this.status = PaymentStatus.PENDING;
        this.otpVerified = false;
        this.createdAt = Instant.now();
    }

    /** Fabrique : initier un paiement. */
    public static VideoConferencePayment initiate(UUID recruiterId, UUID candidateId, UUID matchId,
                                                   Money amount, Money tax,
                                                   String cardLast4, String cardType) {
        VideoConferencePayment payment = new VideoConferencePayment(
            UUID.randomUUID(), recruiterId, candidateId, matchId, amount, tax);
        payment.paymentMethodLast4 = cardLast4;
        payment.paymentMethodType = cardType;
        payment.status = PaymentStatus.OTP_SENT;
        return payment;
    }

    /** Reconstruction depuis la persistance. */
    public static VideoConferencePayment rehydrate(UUID id, UUID recruiterId, UUID candidateId,
                                                    UUID matchId, Money amount, Money tax, Money total,
                                                    PaymentStatus status, String paymentMethodLast4,
                                                    String paymentMethodType, boolean otpVerified,
                                                    Instant createdAt, Instant confirmedAt) {
        VideoConferencePayment p = new VideoConferencePayment(id, recruiterId, candidateId, matchId, amount, tax);
        p.total = total;
        p.status = status;
        p.paymentMethodLast4 = paymentMethodLast4;
        p.paymentMethodType = paymentMethodType;
        p.otpVerified = otpVerified;
        p.confirmedAt = confirmedAt;
        return p;
    }

    /** Vérifier le code OTP et confirmer le paiement. */
    public void verifyOtp() {
        if (this.status != PaymentStatus.OTP_SENT) {
            throw new IllegalStateException("Le paiement n'est pas en attente d'OTP");
        }
        this.otpVerified = true;
        this.status = PaymentStatus.CONFIRMED;
        this.confirmedAt = Instant.now();
        registerEvent(VideoConferencePaymentConfirmedEvent.of(this.id, this.matchId, this.recruiterId));
    }

    /** Marquer le paiement comme échoué. */
    public void fail() {
        this.status = PaymentStatus.FAILED;
    }

    public UUID id() { return id; }
    public UUID recruiterId() { return recruiterId; }
    public UUID candidateId() { return candidateId; }
    public UUID matchId() { return matchId; }
    public Money amount() { return amount; }
    public Money tax() { return tax; }
    public Money total() { return total; }
    public PaymentStatus status() { return status; }
    public String paymentMethodLast4() { return paymentMethodLast4; }
    public String paymentMethodType() { return paymentMethodType; }
    public boolean otpVerified() { return otpVerified; }
    public Instant createdAt() { return createdAt; }
    public Instant confirmedAt() { return confirmedAt; }
}
