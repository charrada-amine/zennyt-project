package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.ApplicationResponse;
import com.zennyt.recruitment.api.dto.SubmitApplicationRequest;
import com.zennyt.recruitment.application.command.SubmitApplicationCommand;
import com.zennyt.recruitment.application.usecase.SubmitApplicationUseCase;
import com.zennyt.recruitment.domain.model.Application;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Contrôleur REST des candidatures.
 *
 * <p>Couche fine : il traduit la requête HTTP en commande applicative, délègue
 * au use case, et mappe le résultat en DTO de réponse. Aucune logique métier ici.
 *
 * <p>En contract-first, ce contrôleur peut implémenter l'interface générée par
 * openapi-generator depuis {@code recruitment.openapi.yaml} pour garantir la
 * conformité au contrat.
 */
@RestController
@RequestMapping("/api/v1/applications")
public class ApplicationController {

    private final SubmitApplicationUseCase submitApplication;

    public ApplicationController(SubmitApplicationUseCase submitApplication) {
        this.submitApplication = submitApplication;
    }

    @PostMapping
    public ResponseEntity<ApplicationResponse> submit(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody SubmitApplicationRequest request) {

        UUID candidateId = UUID.fromString(jwt.getSubject());

        Application app = submitApplication.execute(
            new SubmitApplicationCommand(candidateId, request.jobId(), request.coverLetter()));

        return ResponseEntity.status(HttpStatus.CREATED).body(ApplicationResponse.from(app));
    }
}
