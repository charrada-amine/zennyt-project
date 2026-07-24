package com.zennyt.shared.infrastructure.web;

import com.fasterxml.jackson.annotation.JsonValue;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import com.zennyt.shared.application.exception.ServerException;
import com.zennyt.shared.application.exception.ServiceUnavailableException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.security.authentication.BadCredentialsException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Gestion centralisée des erreurs.
 *
 * <p>Produit l'enveloppe unifiée définie dans
 * {@code contracts/common.openapi.yaml#/components/schemas/Error} :
 * {@code {error: CODE_MACHINE, message, ...champs de contexte optionnels}}.
 * {@code error} est un code métier spécifique quand l'exception en porte un
 * (ex. {@code JOB_NOT_ACTIVE}, {@code ASSESSMENT_IN_USE}), sinon un code
 * générique dérivé du statut HTTP (ex. {@code NOT_FOUND}, {@code FORBIDDEN}).
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    public record FieldError(String field, String message) {}

    public record ApiError(String error, String message, Map<String, Object> extra) {
        @JsonValue
        public Map<String, Object> asJson() {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("error", error);
            body.put("message", message);
            if (extra != null) body.putAll(extra);
            return body;
        }
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleBadRequest(IllegalArgumentException ex) {
        return build(HttpStatus.BAD_REQUEST, null, ex.getMessage(), null);
    }

    /** Opération invalide dans l'état courant (transition d'état, consentement absent) — 422. */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiError> handleIllegalState(IllegalStateException ex) {
        return build(HttpStatus.UNPROCESSABLE_ENTITY, null, ex.getMessage(), null);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiError> handleUnauthorized(BadCredentialsException ex) {
        return build(HttpStatus.UNAUTHORIZED, null, "Identifiants invalides", null);
    }

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(NotFoundException ex) {
        return build(HttpStatus.NOT_FOUND, ex.code(), ex.getMessage(), null);
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<ApiError> handleForbidden(ForbiddenException ex) {
        return build(HttpStatus.FORBIDDEN, null, ex.getMessage(), null);
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ApiError> handleConflict(ConflictException ex) {
        return build(HttpStatus.CONFLICT, ex.code(), ex.getMessage(), ex.extra());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        List<FieldError> fields = ex.getBindingResult().getFieldErrors().stream()
            .map(f -> new FieldError(f.getField(), f.getDefaultMessage()))
            .toList();
        return build(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Erreur de validation",
            Map.of("fieldErrors", fields));
    }

    @ExceptionHandler({AuthorizationDeniedException.class, AccessDeniedException.class})
    public ResponseEntity<ApiError> handleAccessDenied(Exception ex) {
        return build(HttpStatus.FORBIDDEN, null, "Accès refusé", null);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ApiError> handleUnsupportedMediaType(HttpMediaTypeNotSupportedException ex) {
        return build(HttpStatus.UNSUPPORTED_MEDIA_TYPE, null, "Type de contenu non supporté", null);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> handleUploadTooLarge(MaxUploadSizeExceededException ex) {
        return build(HttpStatus.PAYLOAD_TOO_LARGE, null, "Le fichier dépasse la limite autorisée", null);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class,
        MissingRequestHeaderException.class,
        MissingServletRequestParameterException.class,
        MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ApiError> handleMalformedRequest(Exception ex) {
        return build(HttpStatus.BAD_REQUEST, null, "Requête invalide", null);
    }

    @ExceptionHandler(com.zennyt.shared.application.exception.RateLimitException.class)
    public ResponseEntity<ApiError> handleRateLimit(com.zennyt.shared.application.exception.RateLimitException ex) {
        return build(HttpStatus.TOO_MANY_REQUESTS, null, ex.getMessage(), null);
    }

    @ExceptionHandler(ServerException.class)
    public ResponseEntity<ApiError> handleServerException(ServerException ex) {
        log.error("Server exception: ", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, null, ex.getMessage(), null);
    }

    @ExceptionHandler(ServiceUnavailableException.class)
    public ResponseEntity<ApiError> handleServiceUnavailable(ServiceUnavailableException ex) {
        log.warn("External service unavailable: {}", ex.getMessage());
        return build(HttpStatus.SERVICE_UNAVAILABLE, null, ex.getMessage(), null);
    }

    @ExceptionHandler(com.zennyt.recruitment.application.exception.UpstreamServiceException.class)
    public ResponseEntity<ApiError> handleUpstreamService(
            com.zennyt.recruitment.application.exception.UpstreamServiceException ex) {
        log.warn("Recruitment upstream AI service failed: {}", ex.getMessage());
        return build(HttpStatus.BAD_GATEWAY, null, ex.getMessage(), null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleAllExceptions(Exception ex) {
        log.error("Unhandled exception: ", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, null, "Une erreur interne est survenue.", null);
    }

    private ResponseEntity<ApiError> build(HttpStatus status, String code, String msg, Map<String, Object> extra) {
        ApiError body = new ApiError(code != null ? code : defaultCode(status), msg, extra);
        return ResponseEntity.status(status).body(body);
    }

    private static String defaultCode(HttpStatus status) {
        return switch (status) {
            case BAD_REQUEST -> "BAD_REQUEST";
            case UNAUTHORIZED -> "UNAUTHORIZED";
            case FORBIDDEN -> "FORBIDDEN";
            case NOT_FOUND -> "NOT_FOUND";
            case CONFLICT -> "CONFLICT";
            case UNPROCESSABLE_ENTITY -> "UNPROCESSABLE_ENTITY";
            case PAYLOAD_TOO_LARGE -> "PAYLOAD_TOO_LARGE";
            case UNSUPPORTED_MEDIA_TYPE -> "UNSUPPORTED_MEDIA_TYPE";
            case TOO_MANY_REQUESTS -> "RATE_LIMITED";
            case BAD_GATEWAY -> "BAD_GATEWAY";
            case SERVICE_UNAVAILABLE -> "SERVICE_UNAVAILABLE";
            default -> "INTERNAL_ERROR";
        };
    }
}
