package com.zennyt.shared.infrastructure.web;

import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import com.zennyt.shared.application.exception.ServerException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.security.authentication.BadCredentialsException;

import java.time.Instant;
import java.util.List;

/**
 * Gestion centralisée des erreurs.
 *
 * <p>Produit le format d'erreur unifié défini dans
 * {@code contracts/common.openapi.yaml#/components/schemas/Error}, garantissant
 * que le front reçoit toujours la même structure quelle que soit l'erreur.
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    public record FieldError(String field, String message) {}

    public record ApiError(
        Instant timestamp, int status, String error,
        String message, String path, List<FieldError> fieldErrors) {}

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleBadRequest(IllegalArgumentException ex, HttpServletRequest req) {
        return build(HttpStatus.BAD_REQUEST, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiError> handleUnauthorized(BadCredentialsException ex, HttpServletRequest req) {
        return build(HttpStatus.UNAUTHORIZED, "Identifiants invalides", req, List.of());
    }

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(NotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<ApiError> handleForbidden(ForbiddenException ex, HttpServletRequest req) {
        return build(HttpStatus.FORBIDDEN, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ApiError> handleConflict(ConflictException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        List<FieldError> fields = ex.getBindingResult().getFieldErrors().stream()
            .map(f -> new FieldError(f.getField(), f.getDefaultMessage()))
            .toList();
        return build(HttpStatus.BAD_REQUEST, "Erreur de validation", req, fields);
    }

    // Ajouter ici les exceptions métier : NotFoundException -> 404, ForbiddenException -> 403, etc.

    @ExceptionHandler(com.zennyt.shared.application.exception.RateLimitException.class)
    public ResponseEntity<ApiError> handleRateLimit(com.zennyt.shared.application.exception.RateLimitException ex, HttpServletRequest req) {
        return build(HttpStatus.TOO_MANY_REQUESTS, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(ServerException.class)
    public ResponseEntity<ApiError> handleServerException(ServerException ex, HttpServletRequest req) {
        log.error("Server exception: ", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, ex.getMessage(), req, List.of());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleAllExceptions(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception: ", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "Une erreur interne est survenue.", req, List.of());
    }

    private ResponseEntity<ApiError> build(HttpStatus status, String msg,
                                           HttpServletRequest req, List<FieldError> fields) {
        ApiError body = new ApiError(
            Instant.now(), status.value(), status.getReasonPhrase(),
            msg, req.getRequestURI(), fields);
        return ResponseEntity.status(status).body(body);
    }
}
