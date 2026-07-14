package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.JobOpportunityOfferSentEvent;
import com.zennyt.recruitment.domain.event.JobOpportunityOfferConfirmedEvent;
import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import com.zennyt.recruitment.domain.vo.SalaryRange;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Offre d'opportunité — envoyée par le recruteur au candidat.
 *
 * <p>Flux : le recruteur envoie → candidat confirme → OTP SMS → vérification OTP.
 * Publie des événements pour que le contexte Engagement délivre la carte dans le chat.
 */
public class JobOpportunityOffer extends AggregateRoot {

    private final UUID id;
    private final UUID recruiterId;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private String title;
    private SalaryRange salary;
    private JobOpportunityStatus status;
    private boolean otpVerified;
    private final Instant sentAt;
    private Instant respondedAt;

    private JobOpportunityOffer(UUID id, UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        this.id = id;
        this.recruiterId = recruiterId;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.status = JobOpportunityStatus.PENDING;
        this.otpVerified = false;
        this.sentAt = Instant.now();
    }

    /** Fabrique : envoyer une offre d'opportunité. */
    public static JobOpportunityOffer send(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        JobOpportunityOffer offer = new JobOpportunityOffer(UUID.randomUUID(), recruiterId, candidateId, jobOfferId);
        offer.registerEvent(JobOpportunityOfferSentEvent.of(offer.id, recruiterId, candidateId, jobOfferId));
        return offer;
    }

    /** Reconstruction depuis la persistance. */
    public static JobOpportunityOffer rehydrate(UUID id, UUID recruiterId, UUID candidateId,
                                                 UUID jobOfferId, String title, SalaryRange salary,
                                                 JobOpportunityStatus status, boolean otpVerified,
                                                 Instant sentAt, Instant respondedAt) {
        JobOpportunityOffer offer = new JobOpportunityOffer(id, recruiterId, candidateId, jobOfferId);
        offer.title = title;
        offer.salary = salary;
        offer.status = status;
        offer.otpVerified = otpVerified;
        offer.respondedAt = respondedAt;
        return offer;
    }

    /** Le candidat confirme — déclenche l'envoi OTP SMS. */
    public void confirm() {
        if (this.status != JobOpportunityStatus.PENDING) {
            throw new IllegalStateException("L'offre n'est plus en attente");
        }
        // Le status reste PENDING jusqu'à la vérification OTP
    }

    /** Vérifier le code OTP — finalise la confirmation. */
    public void verifyOtp() {
        this.otpVerified = true;
        this.status = JobOpportunityStatus.CONFIRMED;
        this.respondedAt = Instant.now();
        registerEvent(JobOpportunityOfferConfirmedEvent.of(this.id, this.candidateId, this.jobOfferId));
    }

    /** Le candidat rejette l'offre. */
    public void reject() {
        if (this.status != JobOpportunityStatus.PENDING) {
            throw new IllegalStateException("L'offre n'est plus en attente");
        }
        this.status = JobOpportunityStatus.REJECTED;
        this.respondedAt = Instant.now();
    }

    public UUID id() { return id; }
    public UUID recruiterId() { return recruiterId; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public String title() { return title; }
    public SalaryRange salary() { return salary; }
    public JobOpportunityStatus status() { return status; }
    public boolean otpVerified() { return otpVerified; }
    public Instant sentAt() { return sentAt; }
    public Instant respondedAt() { return respondedAt; }
}
