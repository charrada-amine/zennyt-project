package com.zennyt.identity.application.model;

import com.zennyt.identity.domain.model.SkillType;

import java.time.LocalDate;
import java.util.List;

/** Résultat structuré d'analyse d'un CV, indépendant de la couche HTTP. */
public record CvParseData(
    Boolean isValidCv,
    String currentPosition,
    String aboutMe,
    Integer yearsOfExperience,
    List<SkillData> skills,
    List<PositionData> positions,
    List<EducationData> education,
    List<CertificationData> certifications
) {
    public record SkillData(String name, SkillType type, Integer level) {}
    public record PositionData(String title, String companyName, String location,
                               String description, LocalDate startDate, LocalDate endDate,
                               boolean current) {}
    public record EducationData(String degree, String school, String fieldOfStudy,
                                String description, LocalDate startDate, LocalDate endDate) {}
    public record CertificationData(String title, String issuer, LocalDate completionDate,
                                    String credentialId, String credentialUrl) {}
}
