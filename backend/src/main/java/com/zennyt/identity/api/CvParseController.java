package com.zennyt.identity.api;


import com.zennyt.identity.api.security.CandidateOrStudentOnly;
import com.zennyt.identity.infrastructure.ai.GroqCvParser;
import com.zennyt.shared.application.exception.BadRequestException;
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

    private final GroqCvParser cvParser;

    @PostMapping
    @CandidateOrStudentOnly
    public CvParseResult parseCv(@Valid @RequestBody CvParseRequest request) {
        if (request.text() == null || request.text().trim().isEmpty()) {
            throw new BadRequestException("Le texte du CV ne peut pas être vide.");
        }
        
        String cleanText = request.text().replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "");
        
        if (cleanText.length() > 50000) {
            throw new BadRequestException("Le texte du CV est trop long (limite de 50 000 caractères).");
        }
        
        // Note: For rate limiting, a simple DB or Redis counter should be implemented here in a production environment.
        // For MVP, we assume it's enforced externally (e.g. API Gateway) or can be added later.
        
        return cvParser.parseCv(cleanText, request.language());
    }
}
