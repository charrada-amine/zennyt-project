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

    public static final int DEFAULT_PASSING_SCORE = 60;

    private final UUID id;
    private final UUID recruiterId;
    private UUID hiringContactId;
    private String title;
    private String companyName;
    private Location location;
    private SalaryRange salary;
    private ContractType contractType;
    private WorkplaceType workplaceType;
    private ExperienceLevel experienceLevel;
    private String fieldOfWork;
    private String description;
    private String responsibilities;
    private String minimumQualifications;
    private String preferredQualifications;
    private String whatWeOffer;
    private String howToApply;
    private String companyInfo;
    private UUID assessmentId;
    private UUID jobPositionId;
    private int passingScore;
    private boolean openToInternational;
    private JobOfferStatus status;
    private Instant postedAt;

    private JobOffer(UUID id, UUID recruiterId, String title, String description,
                     ContractType contractType, WorkplaceType workplaceType,
                     ExperienceLevel experienceLevel, Location location,
                     int passingScore) {
        this.id = id;
        this.recruiterId = recruiterId;
        this.title = title;
        this.description = description;
        this.contractType = contractType;
        this.workplaceType = workplaceType;
        this.experienceLevel = experienceLevel;
        this.location = location;
        setPassingScore(passingScore);
        this.status = JobOfferStatus.DRAFT;
        this.openToInternational = false;
        this.postedAt = Instant.now();
    }

    /** Fabrique : crée une offre en brouillon et enregistre l'événement de création. */
    public static JobOffer create(UUID recruiterId, String title, String description,
                                  ContractType contractType, WorkplaceType workplaceType,
                                  ExperienceLevel experienceLevel, Location location,
                                  int passingScore) {
        JobOffer offer = new JobOffer(UUID.randomUUID(), recruiterId, title, description,
            contractType, workplaceType, experienceLevel, location, passingScore);
        offer.registerEvent(JobOfferCreatedEvent.of(offer.id, recruiterId));
        return offer;
    }

    /** Reconstruction depuis la persistance (pas d'événement émis). */
    public static JobOffer rehydrate(UUID id, UUID recruiterId, UUID hiringContactId,
                                     String title, String companyName, Location location,
                                     SalaryRange salary, ContractType contractType,
                                     WorkplaceType workplaceType, ExperienceLevel experienceLevel,
                                     String fieldOfWork, String description, String responsibilities,
                                     String minimumQualifications, String preferredQualifications,
                                     String whatWeOffer, String howToApply, String companyInfo,
                                     UUID assessmentId, UUID jobPositionId, int passingScore,
                                     boolean openToInternational,
                                     JobOfferStatus status, Instant postedAt) {
        JobOffer offer = new JobOffer(id, recruiterId, title, description,
            contractType, workplaceType, experienceLevel, location, passingScore);
        offer.hiringContactId = hiringContactId;
        offer.companyName = companyName;
        offer.salary = salary;
        offer.fieldOfWork = fieldOfWork;
        offer.responsibilities = responsibilities;
        offer.minimumQualifications = minimumQualifications;
        offer.preferredQualifications = preferredQualifications;
        offer.whatWeOffer = whatWeOffer;
        offer.howToApply = howToApply;
        offer.companyInfo = companyInfo;
        offer.assessmentId = assessmentId;
        offer.jobPositionId = jobPositionId;
        offer.openToInternational = openToInternational;
        offer.status = status;
        offer.postedAt = postedAt;
        return offer;
    }

    /** Transition de statut avec validation de la machine à états. */
    public void changeStatus(JobOfferStatus target) {
        if (!this.status.canTransitionTo(target)) {
            throw new IllegalArgumentException(
                "Transition interdite : " + this.status + " -> " + target);
        }
        JobOfferStatus previous = this.status;
        this.status = target;
        registerEvent(JobOfferStatusChangedEvent.of(this.id, previous, target));
    }

    /** Met à jour les champs modifiables (seules les offres en DRAFT ou ACTIVE). */
    public void update(String title, String companyName, Location location, SalaryRange salary,
                       ContractType contractType, WorkplaceType workplaceType,
                       ExperienceLevel experienceLevel, String fieldOfWork, String description,
                       String responsibilities, String minimumQualifications,
                       String preferredQualifications, String whatWeOffer, String howToApply,
                       String companyInfo, UUID assessmentId, UUID jobPositionId,
                       boolean openToInternational) {
        this.title = title;
        this.companyName = companyName;
        this.location = location;
        this.salary = salary;
        this.contractType = contractType;
        this.workplaceType = workplaceType;
        this.experienceLevel = experienceLevel;
        this.fieldOfWork = fieldOfWork;
        this.description = description;
        this.responsibilities = responsibilities;
        this.minimumQualifications = minimumQualifications;
        this.preferredQualifications = preferredQualifications;
        this.whatWeOffer = whatWeOffer;
        this.howToApply = howToApply;
        this.companyInfo = companyInfo;
        this.assessmentId = assessmentId;
        this.jobPositionId = jobPositionId;
        this.openToInternational = openToInternational;
    }

    /** Configure le seuil QCM de l'offre. */
    public void setPassingScore(int passingScore) {
        if (passingScore < 0 || passingScore > 100) {
            throw new IllegalArgumentException("Le seuil de réussite doit être entre 0 et 100");
        }
        this.passingScore = passingScore;
    }

    /** Assigne (ou désassigne avec null) l'évaluation technique liée à l'offre. */
    public void assignAssessment(UUID assessmentId) {
        this.assessmentId = assessmentId;
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
    public String companyName() { return companyName; }
    public Location location() { return location; }
    public SalaryRange salary() { return salary; }
    public ContractType contractType() { return contractType; }
    public WorkplaceType workplaceType() { return workplaceType; }
    public ExperienceLevel experienceLevel() { return experienceLevel; }
    public String fieldOfWork() { return fieldOfWork; }
    public String description() { return description; }
    public String responsibilities() { return responsibilities; }
    public String minimumQualifications() { return minimumQualifications; }
    public String preferredQualifications() { return preferredQualifications; }
    public String whatWeOffer() { return whatWeOffer; }
    public String howToApply() { return howToApply; }
    public String companyInfo() { return companyInfo; }
    public UUID assessmentId() { return assessmentId; }
    public UUID jobPositionId() { return jobPositionId; }
    public int passingScore() { return passingScore; }
    public boolean openToInternational() { return openToInternational; }
    public JobOfferStatus status() { return status; }
    public Instant postedAt() { return postedAt; }
}
