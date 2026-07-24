package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.JobOfferCreatedEvent;
import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Offre d'emploi — racine du contexte Recruitment.
 *
 * <p>Gère le cycle de vie complet d'une offre (DRAFT → ACTIVE → HIDDEN → CLOSED),
 * les informations descriptives du poste, et les évaluations associées.
 */
public class JobOffer extends AggregateRoot {

    private final UUID id;
    private final UUID recruiterId;
    private UUID hiringContactId;
    private String title;
    private Location location;
    private Double salaryMin;
    private Double salaryMax;
    private ContractType contractType;
    private WorkplaceType workplaceType;
    private ExperienceLevel experienceLevel;
    private String description;
    private String responsibilities;
    private String minimumQualifications;
    private String preferredQualifications;
    private String whatWeOffer;
    private String howToApply;
    private UUID assessmentId;
    private UUID jobPositionId;
    private boolean openToInternational;
    private JobOfferStatus status;
    private Instant postedAt;
    private Instant updatedAt;

    private JobOffer(UUID id, UUID recruiterId, String title, String description,
                     ContractType contractType, WorkplaceType workplaceType,
                     ExperienceLevel experienceLevel, Location location) {
        this.id = id;
        this.recruiterId = recruiterId;
        this.title = title;
        this.description = description;
        this.contractType = contractType;
        this.workplaceType = workplaceType;
        this.experienceLevel = experienceLevel;
        this.location = location;
        this.status = JobOfferStatus.DRAFT;
        this.openToInternational = false;
        this.postedAt = Instant.now();
        this.updatedAt = this.postedAt;
    }

    /** Fabrique : crée une offre en brouillon et enregistre l'événement de création. */
    public static JobOffer create(UUID recruiterId, String title, String description,
                                  ContractType contractType, WorkplaceType workplaceType,
                                  ExperienceLevel experienceLevel, Location location) {
        JobOffer offer = new JobOffer(UUID.randomUUID(), recruiterId, title, description,
            contractType, workplaceType, experienceLevel, location);
        offer.registerEvent(JobOfferCreatedEvent.of(offer.id, recruiterId));
        return offer;
    }

    /** Reconstruction depuis la persistance (pas d'événement émis). */
    public static JobOffer rehydrate(UUID id, UUID recruiterId, UUID hiringContactId,
                                     String title, Location location,
                                     Double salaryMin, Double salaryMax, ContractType contractType,
                                     WorkplaceType workplaceType, ExperienceLevel experienceLevel,
                                     String description, String responsibilities,
                                     String minimumQualifications, String preferredQualifications,
                                     String whatWeOffer, String howToApply,
                                     UUID assessmentId, UUID jobPositionId,
                                     boolean openToInternational,
                                     JobOfferStatus status, Instant postedAt, Instant updatedAt) {
        JobOffer offer = new JobOffer(id, recruiterId, title, description,
            contractType, workplaceType, experienceLevel, location);
        offer.hiringContactId = hiringContactId;
        offer.salaryMin = salaryMin;
        offer.salaryMax = salaryMax;
        offer.responsibilities = responsibilities;
        offer.minimumQualifications = minimumQualifications;
        offer.preferredQualifications = preferredQualifications;
        offer.whatWeOffer = whatWeOffer;
        offer.howToApply = howToApply;
        offer.assessmentId = assessmentId;
        offer.jobPositionId = jobPositionId;
        offer.openToInternational = openToInternational;
        offer.status = status;
        offer.postedAt = postedAt;
        offer.updatedAt = updatedAt;
        return offer;
    }

    /** Transition de statut — librement réversible, aucun état terminal. */
    public void changeStatus(JobOfferStatus target) {
        JobOfferStatus previous = this.status;
        this.status = target;
        this.updatedAt = Instant.now();
        registerEvent(JobOfferStatusChangedEvent.of(this.id, previous, target));
    }

    /** Met à jour les champs modifiables (seules les offres en DRAFT ou ACTIVE). */
    public void update(String title, Location location, Double salaryMin, Double salaryMax,
                       ContractType contractType, WorkplaceType workplaceType,
                       ExperienceLevel experienceLevel, String description,
                       String responsibilities, String minimumQualifications,
                       String preferredQualifications, String whatWeOffer, String howToApply,
                       UUID assessmentId, UUID jobPositionId,
                       boolean openToInternational) {
        this.title = title;
        this.location = location;
        this.salaryMin = salaryMin;
        this.salaryMax = salaryMax;
        this.contractType = contractType;
        this.workplaceType = workplaceType;
        this.experienceLevel = experienceLevel;
        this.description = description;
        this.responsibilities = responsibilities;
        this.minimumQualifications = minimumQualifications;
        this.preferredQualifications = preferredQualifications;
        this.whatWeOffer = whatWeOffer;
        this.howToApply = howToApply;
        this.assessmentId = assessmentId;
        this.jobPositionId = jobPositionId;
        this.openToInternational = openToInternational;
        this.updatedAt = Instant.now();
    }

    /** Assigne (ou désassigne avec null) l'évaluation technique liée à l'offre. */
    public void assignAssessment(UUID assessmentId) {
        this.assessmentId = assessmentId;
        this.updatedAt = Instant.now();
    }

    /** Supprime l'offre. Suppression physique quel que soit le statut ;
     *  passera en soft-delete quand des matches/swipes référenceront l'offre. */
    public void delete() {
        // aucune règle bloquante pour l'instant
    }

    // ───────────── Accesseurs ─────────────
    public UUID id() { return id; }
    public UUID recruiterId() { return recruiterId; }
    public UUID hiringContactId() { return hiringContactId; }
    public String title() { return title; }
    public Location location() { return location; }
    public Double salaryMin() { return salaryMin; }
    public Double salaryMax() { return salaryMax; }
    public ContractType contractType() { return contractType; }
    public WorkplaceType workplaceType() { return workplaceType; }
    public ExperienceLevel experienceLevel() { return experienceLevel; }
    public String description() { return description; }
    public String responsibilities() { return responsibilities; }
    public String minimumQualifications() { return minimumQualifications; }
    public String preferredQualifications() { return preferredQualifications; }
    public String whatWeOffer() { return whatWeOffer; }
    public String howToApply() { return howToApply; }
    public UUID assessmentId() { return assessmentId; }
    public UUID jobPositionId() { return jobPositionId; }
    public boolean openToInternational() { return openToInternational; }
    public JobOfferStatus status() { return status; }
    public Instant postedAt() { return postedAt; }
    public Instant updatedAt() { return updatedAt; }
}
