package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobRoleProfileRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Référentiel de pondération Fit Score (CdC v3 §4.3/§9) — les 24 lignes
 * profil × niveau, pour pré-remplir les curseurs de pondération du
 * formulaire de création d'offre côté recruteur.
 */
@RestController
@RequestMapping("/api/v1/job-role-profiles")
public class JobRoleProfileController {

    private final JobRoleProfileRepository profiles;

    public JobRoleProfileController(JobRoleProfileRepository profiles) {
        this.profiles = profiles;
    }

    record JobRoleProfileResponse(JobProfileType profileType, ExperienceLevel level,
                                  int softWeight, int hardWeight, int expectedHardWeight,
                                  int cognitiveFlexibilityWeight, int workingMemoryWeight,
                                  int decisionMakingWeight, int executivePlanningWeight,
                                  int emotionalRegulationWeight, TypeEvaluationHard typeEvaluationHard,
                                  boolean calibrated) {
        static JobRoleProfileResponse from(JobRoleProfile profile) {
            return new JobRoleProfileResponse(profile.profileType(), profile.level(), profile.softWeight(),
                profile.hardWeight(), profile.expectedHardWeight(), profile.cognitiveFlexibilityWeight(),
                profile.workingMemoryWeight(), profile.decisionMakingWeight(), profile.executivePlanningWeight(),
                profile.emotionalRegulationWeight(), profile.typeEvaluationHard(), profile.calibrated());
        }
    }

    /** GET /api/v1/job-role-profiles — Les 24 lignes du référentiel (profil × niveau). */
    @GetMapping
    @Authenticated
    public ResponseEntity<List<JobRoleProfileResponse>> list() {
        return ResponseEntity.ok(profiles.findAll().stream().map(JobRoleProfileResponse::from).toList());
    }
}
