package com.zennyt.recruitment.api;

import com.zennyt.recruitment.application.usecase.ResolvePublicTestUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** Projection publique d'un assessment, sans aucune réponse correcte. */
@RestController
@RequestMapping("/api/v1/tests")
public class PublicTestController {
    private final ResolvePublicTestUseCase resolvePublicTest;

    public PublicTestController(ResolvePublicTestUseCase resolvePublicTest) {
        this.resolvePublicTest = resolvePublicTest;
    }

    @GetMapping("/{token}")
    public ResponseEntity<PublicAssessmentResponse> getByToken(@PathVariable String token) {
        return ResponseEntity.ok(PublicAssessmentResponse.from(resolvePublicTest.execute(token)));
    }

    record PublicQuestionResponse(UUID id, int order, String text, List<String> options) {
        static PublicQuestionResponse from(AssessmentQuestion question) {
            return new PublicQuestionResponse(question.id(), question.order(), question.text(), question.options());
        }
    }

    record PublicAssessmentResponse(UUID id, String title, int questionCount,
                                    int timeLimitSeconds, List<PublicQuestionResponse> questions) {
        static PublicAssessmentResponse from(Assessment assessment) {
            return new PublicAssessmentResponse(assessment.id(), assessment.title(),
                assessment.questions().size(), assessment.timeLimitSeconds(),
                assessment.questions().stream().map(PublicQuestionResponse::from).toList());
        }
    }
}
