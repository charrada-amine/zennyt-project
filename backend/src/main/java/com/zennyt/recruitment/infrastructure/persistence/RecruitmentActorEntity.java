package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.WorkplaceType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "actors", schema = "recruitment")
public class RecruitmentActorEntity {
    @Id
    @Column(name = "public_user_id", nullable = false)
    private UUID publicUserId;

    @Column(name = "role", nullable = false, length = 30)
    private String role;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "city")
    private String city;

    @Column(name = "country")
    private String country;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "company_info", columnDefinition = "TEXT")
    private String companyInfo;

    @Enumerated(EnumType.STRING)
    @Column(name = "workplace_type_preference", length = 20)
    private WorkplaceType workplaceTypePreference;

    @Enumerated(EnumType.STRING)
    @Column(name = "contract_type_preference", length = 20)
    private ContractType contractTypePreference;

    @Column(name = "target_location")
    private String targetLocation;

    @Column(name = "open_internationally")
    private Boolean openInternationally;

    @Column(name = "years_of_experience")
    private Integer yearsOfExperience;

    @Column(name = "looking_for", columnDefinition = "TEXT")
    private String lookingFor;

    @Column(name = "looking_for_embedding", columnDefinition = "TEXT")
    private String lookingForEmbedding;

    @Column(name = "last_event_at", nullable = false)
    private Instant lastEventAt;

    @Column(name = "last_event_id", nullable = false)
    private UUID lastEventId;

    protected RecruitmentActorEntity() {}

    public RecruitmentActorEntity(UUID publicUserId, String role, boolean active,
                                  String fullName, String avatarUrl, String city, String country,
                                  String companyName, String companyInfo,
                                  WorkplaceType workplaceTypePreference, ContractType contractTypePreference,
                                  String targetLocation, Boolean openInternationally,
                                  Integer yearsOfExperience, String lookingFor, String lookingForEmbedding,
                                  Instant lastEventAt, UUID lastEventId) {
        this.publicUserId = publicUserId;
        this.role = role;
        this.active = active;
        this.fullName = fullName;
        this.avatarUrl = avatarUrl;
        this.city = city;
        this.country = country;
        this.companyName = companyName;
        this.companyInfo = companyInfo;
        this.workplaceTypePreference = workplaceTypePreference;
        this.contractTypePreference = contractTypePreference;
        this.targetLocation = targetLocation;
        this.openInternationally = openInternationally;
        this.yearsOfExperience = yearsOfExperience;
        this.lookingFor = lookingFor;
        this.lookingForEmbedding = lookingForEmbedding;
        this.lastEventAt = lastEventAt;
        this.lastEventId = lastEventId;
    }

    public UUID getPublicUserId() { return publicUserId; }
    public String getRole() { return role; }
    public boolean isActive() { return active; }
    public String getFullName() { return fullName; }
    public String getAvatarUrl() { return avatarUrl; }
    public String getCity() { return city; }
    public String getCountry() { return country; }
    public String getCompanyName() { return companyName; }
    public String getCompanyInfo() { return companyInfo; }
    public WorkplaceType getWorkplaceTypePreference() { return workplaceTypePreference; }
    public ContractType getContractTypePreference() { return contractTypePreference; }
    public String getTargetLocation() { return targetLocation; }
    public Boolean getOpenInternationally() { return openInternationally; }
    public Integer getYearsOfExperience() { return yearsOfExperience; }
    public String getLookingFor() { return lookingFor; }
    public String getLookingForEmbedding() { return lookingForEmbedding; }
    public Instant getLastEventAt() { return lastEventAt; }
    public UUID getLastEventId() { return lastEventId; }
}
