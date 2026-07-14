package com.zennyt.identity.api;


import com.zennyt.identity.api.security.CandidateOrStudentOnly;
import com.zennyt.identity.application.ParseCvUseCase;
import com.zennyt.identity.application.model.CvParseData;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.zennyt.identity.api.IdentityDtos.CvParseRequest;
import static com.zennyt.identity.api.IdentityDtos.CvParseResult;

@RestController
@RequestMapping("/api/v1/profiles/me/cv/parse")
@RequiredArgsConstructor
public class CvParseController {

    private final ParseCvUseCase parseCv;

    @PostMapping
    @CandidateOrStudentOnly
    public CvParseResult parseCv(@Valid @RequestBody CvParseRequest request) {
        return toResponse(parseCv.execute(request.text(), request.language()));
    }

    private static CvParseResult toResponse(CvParseData data) {
        return new CvParseResult(
            data.isValidCv(), data.currentPosition(), data.aboutMe(), data.yearsOfExperience(),
            data.skills() == null ? null : data.skills().stream()
                .map(v -> new com.zennyt.identity.api.IdentityDtos.SkillRequest(
                    v.name(), v.type(), v.level())).toList(),
            data.positions() == null ? null : data.positions().stream()
                .map(v -> new com.zennyt.identity.api.IdentityDtos.PositionRequest(
                    v.title(), v.companyName(), v.location(), v.description(),
                    v.startDate(), v.endDate(), v.current())).toList(),
            data.education() == null ? null : data.education().stream()
                .map(v -> new com.zennyt.identity.api.IdentityDtos.EducationRequest(
                    v.degree(), v.school(), v.fieldOfStudy(), v.description(),
                    v.startDate(), v.endDate())).toList(),
            data.certifications() == null ? null : data.certifications().stream()
                .map(v -> new com.zennyt.identity.api.IdentityDtos.CertificationRequest(
                    v.title(), v.issuer(), v.completionDate(),
                    v.credentialId(), v.credentialUrl())).toList());
    }
}
