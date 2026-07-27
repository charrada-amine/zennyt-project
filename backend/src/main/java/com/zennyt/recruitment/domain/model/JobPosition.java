package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Métier du référentiel de pondération Fit Score — catalogue partagé utilisé
 * par le formulaire de création d'offre (sélection position -&gt; niveau).
 *
 * <p>Seedé depuis la matrice v4.1 (statut APPROVED, {@code calibrated=false}
 * — "v1 non calibrés" per la matrice p.31). Un recruteur peut aussi proposer
 * un nouveau métier (statut PENDING_APPROVAL) ; il devient utilisable par
 * tous une fois approuvé par un admin, qui lui assigne alors son profil.
 */
public class JobPosition extends AggregateRoot {

    private final UUID id;
    private String name;
    private String sector; // null = métier transverse
    private JobProfileType profileType; // null tant que non classé (proposition en attente)
    private boolean calibrated;
    private JobPositionStatus status;
    private final UUID proposedByRecruiterId; // null pour les métiers seedés
    private String juniorLabel;
    private String midLabel;
    private String seniorLabel;
    private String executiveLabel;
    private final Instant createdAt;
    private String embedding; // empreinte numérique du nom (JSON), voir EmbeddingCodec — calculée une fois
    private JobProfileType suggestedProfileType; // proposé par IA à la soumission, l'admin choisit librement à l'approbation

    private JobPosition(UUID id, String name, String sector, JobProfileType profileType,
                        boolean calibrated, JobPositionStatus status, UUID proposedByRecruiterId,
                        Instant createdAt) {
        this.id = id;
        this.name = name;
        this.sector = sector;
        this.profileType = profileType;
        this.calibrated = calibrated;
        this.status = status;
        this.proposedByRecruiterId = proposedByRecruiterId;
        this.createdAt = createdAt;
    }

    /** Fabrique : un recruteur propose un métier absent du référentiel. */
    public static JobPosition propose(String name, String sector, UUID recruiterId, String embedding,
                                      JobProfileType suggestedProfileType) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Le nom du métier est obligatoire");
        }
        JobPosition position = new JobPosition(UUID.randomUUID(), name.trim(),
            sector != null && !sector.isBlank() ? sector.trim() : null,
            null, false, JobPositionStatus.PENDING_APPROVAL, recruiterId, Instant.now());
        position.embedding = embedding;
        position.suggestedProfileType = suggestedProfileType;
        return position;
    }

    /** Reconstruction depuis la persistance. */
    public static JobPosition rehydrate(UUID id, String name, String sector, JobProfileType profileType,
                                        boolean calibrated, JobPositionStatus status,
                                        UUID proposedByRecruiterId, String juniorLabel, String midLabel,
                                        String seniorLabel, String executiveLabel, Instant createdAt,
                                        String embedding, JobProfileType suggestedProfileType) {
        JobPosition position = new JobPosition(id, name, sector, profileType, calibrated, status,
            proposedByRecruiterId, createdAt);
        position.juniorLabel = juniorLabel;
        position.midLabel = midLabel;
        position.seniorLabel = seniorLabel;
        position.executiveLabel = executiveLabel;
        position.embedding = embedding;
        position.suggestedProfileType = suggestedProfileType;
        return position;
    }

    /** Renseigne l'empreinte numérique du nom (backfill au démarrage, ou recalcul si le nom change). */
    public void updateEmbedding(String embedding) {
        this.embedding = embedding;
    }

    /** Un admin approuve un métier proposé, en lui assignant son profil (Couche A). */
    public void approve(JobProfileType profileType) {
        if (this.status != JobPositionStatus.PENDING_APPROVAL) {
            throw new IllegalStateException("Ce métier n'est pas en attente d'approbation");
        }
        if (profileType == null) {
            throw new IllegalArgumentException("Le profil du métier est obligatoire pour l'approbation");
        }
        this.profileType = profileType;
        this.status = JobPositionStatus.APPROVED;
    }

    /** Un admin rejette un métier proposé. */
    public void reject() {
        if (this.status != JobPositionStatus.PENDING_APPROVAL) {
            throw new IllegalStateException("Ce métier n'est pas en attente d'approbation");
        }
        this.status = JobPositionStatus.REJECTED;
    }

    /** Libellé affiché pour un niveau — le libellé usuel du métier si défini, sinon le niveau par défaut. */
    public String levelLabel(ExperienceLevel level) {
        String custom = switch (level) {
            case JUNIOR -> juniorLabel;
            case MID -> midLabel;
            case SENIOR -> seniorLabel;
            case EXECUTIVE -> executiveLabel;
        };
        if (custom != null && !custom.isBlank()) return custom;
        return switch (level) {
            case JUNIOR -> "Junior";
            case MID -> "Mid";
            case SENIOR -> "Senior";
            case EXECUTIVE -> "Executive";
        };
    }

    public UUID id() { return id; }
    public String name() { return name; }
    public String sector() { return sector; }
    public JobProfileType profileType() { return profileType; }
    public boolean calibrated() { return calibrated; }
    public JobPositionStatus status() { return status; }
    public UUID proposedByRecruiterId() { return proposedByRecruiterId; }
    public String juniorLabel() { return juniorLabel; }
    public String midLabel() { return midLabel; }
    public String seniorLabel() { return seniorLabel; }
    public String executiveLabel() { return executiveLabel; }
    public Instant createdAt() { return createdAt; }
    public String embedding() { return embedding; }
    public JobProfileType suggestedProfileType() { return suggestedProfileType; }
}
