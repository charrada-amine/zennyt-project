package com.zennyt.identity.domain.model;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.experimental.Accessors;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Getter
@Accessors(fluent = true)
public class Profile {
    private final Long id;
    private final Long userId;
    private String currentPosition;
    private String lookingFor;
    private WorkplaceType workplaceType;
    private JobType jobType;
    private String targetJobLocation;
    private Integer yearsOfExperience;
    private Integer softSkillsScore;
    private String aboutMe;
    private boolean openInternationally;
    private AvailabilityType availabilityType;
    private LocalDate availabilityDate;
    private String resumeAiUrl;
    private String portfolioUrl;
    private final Instant createdAt;
    private Instant updatedAt;
    @Getter(AccessLevel.NONE)
    private final List<Skill> skills;
    @Getter(AccessLevel.NONE)
    private final List<Position> positions;
    @Getter(AccessLevel.NONE)
    private final List<Certification> certifications;
    @Getter(AccessLevel.NONE)
    private final List<Education> education;

    private Profile(Long id, Long userId, String currentPosition, String lookingFor,
                    WorkplaceType workplaceType, JobType jobType, String targetJobLocation,
                    Integer yearsOfExperience, Integer softSkillsScore, String aboutMe,
                    boolean openInternationally, AvailabilityType availabilityType,
                    LocalDate availabilityDate, String resumeAiUrl, String portfolioUrl,
                    Instant createdAt, Instant updatedAt, List<Skill> skills,
                    List<Position> positions, List<Certification> certifications,
                    List<Education> education) {
        this.id = id;
        this.userId = userId;
        this.createdAt = createdAt;
        this.skills = new ArrayList<>(skills);
        this.positions = new ArrayList<>(positions);
        this.certifications = new ArrayList<>(certifications);
        this.education = new ArrayList<>(education);
        update(currentPosition, lookingFor, workplaceType, jobType, targetJobLocation,
            yearsOfExperience, softSkillsScore, aboutMe, openInternationally, availabilityType,
            availabilityDate, resumeAiUrl, portfolioUrl);
        this.updatedAt = updatedAt;
    }

    public static Profile create(Long userId, String currentPosition, String lookingFor,
                                 WorkplaceType workplaceType, JobType jobType,
                                 String targetJobLocation, Integer yearsOfExperience,
                                 Integer softSkillsScore, String aboutMe, boolean openInternationally,
                                 AvailabilityType availabilityType, LocalDate availabilityDate,
                                 String resumeAiUrl, String portfolioUrl) {
        Instant now = Instant.now();
        return new Profile(null, userId, currentPosition, lookingFor, workplaceType, jobType,
            targetJobLocation, yearsOfExperience, softSkillsScore, aboutMe, openInternationally,
            availabilityType, availabilityDate, resumeAiUrl, portfolioUrl, now, now,
            List.of(), List.of(), List.of(), List.of());
    }

    public static Profile rehydrate(Long id, Long userId, String currentPosition, String lookingFor,
                                    WorkplaceType workplaceType, JobType jobType,
                                    String targetJobLocation, Integer yearsOfExperience,
                                    Integer softSkillsScore, String aboutMe,
                                    boolean openInternationally, AvailabilityType availabilityType,
                                    LocalDate availabilityDate, String resumeAiUrl,
                                    String portfolioUrl, Instant createdAt, Instant updatedAt,
                                    List<Skill> skills, List<Position> positions,
                                    List<Certification> certifications, List<Education> education) {
        return new Profile(id, userId, currentPosition, lookingFor, workplaceType, jobType,
            targetJobLocation, yearsOfExperience, softSkillsScore, aboutMe, openInternationally,
            availabilityType, availabilityDate, resumeAiUrl, portfolioUrl, createdAt, updatedAt,
            skills, positions, certifications, education);
    }

    public void update(String currentPosition, String lookingFor, WorkplaceType workplaceType,
                       JobType jobType, String targetJobLocation, Integer yearsOfExperience,
                       Integer softSkillsScore, String aboutMe, boolean openInternationally,
                       AvailabilityType availabilityType, LocalDate availabilityDate,
                       String resumeAiUrl, String portfolioUrl) {
        if (yearsOfExperience != null && yearsOfExperience < 0) {
            throw new IllegalArgumentException("Les années d'expérience doivent être positives");
        }
        if (softSkillsScore != null && (softSkillsScore < 0 || softSkillsScore > 100)) {
            throw new IllegalArgumentException("Le score de soft skills doit être compris entre 0 et 100");
        }
        if (availabilityType == AvailabilityType.SELECT_DATE && availabilityDate == null) {
            throw new IllegalArgumentException("Une date de disponibilité est obligatoire");
        }
        this.currentPosition = currentPosition;
        this.lookingFor = lookingFor;
        this.workplaceType = workplaceType;
        this.jobType = jobType;
        this.targetJobLocation = targetJobLocation;
        this.yearsOfExperience = yearsOfExperience;
        this.softSkillsScore = softSkillsScore == null ? 0 : softSkillsScore;
        this.aboutMe = aboutMe;
        this.openInternationally = openInternationally;
        this.availabilityType = availabilityType;
        this.availabilityDate = availabilityDate;
        this.resumeAiUrl = resumeAiUrl;
        this.portfolioUrl = portfolioUrl;
        this.updatedAt = Instant.now();
    }

    public void addSkill(Skill skill) { skills.add(skill); updatedAt = Instant.now(); }
    public void replaceSkill(Long id, Skill replacement) {
        replace(skills, id, new Skill(id, replacement.name(), replacement.type(), replacement.level(),
            find(skills, id).createdAt(), Instant.now()));
    }
    public void removeSkill(Long id) { remove(skills, id); }
    public void addPosition(Position position) { positions.add(position); updatedAt = Instant.now(); }
    public void replacePosition(Long id, Position value) {
        replace(positions, id, new Position(id, value.title(), value.companyName(), value.location(),
            value.description(), value.startDate(), value.endDate(), value.current(),
            find(positions, id).createdAt(), Instant.now()));
    }
    public void removePosition(Long id) { remove(positions, id); }
    public void addCertification(Certification value) { certifications.add(value); updatedAt = Instant.now(); }
    public void replaceCertification(Long id, Certification value) {
        replace(certifications, id, new Certification(id, value.title(), value.issuer(),
            value.completionDate(), value.credentialId(), value.credentialUrl(),
            find(certifications, id).createdAt(), Instant.now()));
    }
    public void removeCertification(Long id) { remove(certifications, id); }
    public void addEducation(Education value) { education.add(value); updatedAt = Instant.now(); }
    public void replaceEducation(Long id, Education value) {
        replace(education, id, new Education(id, value.degree(), value.school(), value.fieldOfStudy(),
            value.description(), value.startDate(), value.endDate(),
            find(education, id).createdAt(), Instant.now()));
    }
    public void removeEducation(Long id) { remove(education, id); }

    private static <T> T find(List<T> values, Long id) {
        return values.stream()
            .filter(value -> ((Record) value).toString() != null && recordId(value).equals(id))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Élément de profil introuvable"));
    }

    private static <T> void replace(List<T> values, Long id, T replacement) {
        for (int index = 0; index < values.size(); index++) {
            if (recordId(values.get(index)).equals(id)) {
                values.set(index, replacement);
                return;
            }
        }
        throw new IllegalArgumentException("Élément de profil introuvable");
    }

    private static <T> void remove(List<T> values, Long id) {
        if (!values.removeIf(value -> recordId(value).equals(id))) {
            throw new IllegalArgumentException("Élément de profil introuvable");
        }
    }

    private static Long recordId(Object value) {
        if (value instanceof Skill item) return item.id();
        if (value instanceof Position item) return item.id();
        if (value instanceof Certification item) return item.id();
        if (value instanceof Education item) return item.id();
        throw new IllegalArgumentException("Type d'élément de profil inconnu");
    }

    public List<Skill> skills() { return List.copyOf(skills); }
    public List<Position> positions() { return List.copyOf(positions); }
    public List<Certification> certifications() { return List.copyOf(certifications); }
    public List<Education> education() { return List.copyOf(education); }
}
