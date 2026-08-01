package com.zennyt.games.api;

import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;

/** Traduction HTTP locale au bounded context Games, conforme au contrat commun. */
@RestControllerAdvice(basePackages = "com.zennyt.games.api")
public class GamesExceptionHandler {

    record ApiError(Instant timestamp, int status, String error,
                    String message, String path) {
    }

    @ExceptionHandler(ForbiddenException.class)
    ResponseEntity<ApiError> forbidden(
            ForbiddenException exception, HttpServletRequest request) {
        return response(HttpStatus.FORBIDDEN, exception.getMessage(), request);
    }

    @ExceptionHandler(NotFoundException.class)
    ResponseEntity<ApiError> notFound(
            NotFoundException exception, HttpServletRequest request) {
        return response(HttpStatus.NOT_FOUND, exception.getMessage(), request);
    }

    @ExceptionHandler({
        IllegalArgumentException.class,
        IllegalStateException.class,
        ConstraintViolationException.class,
        MethodArgumentNotValidException.class,
        HttpMessageNotReadableException.class
    })
    ResponseEntity<ApiError> badRequest(Exception exception,
                                        HttpServletRequest request) {
        return response(HttpStatus.BAD_REQUEST, exception.getMessage(), request);
    }

    private static ResponseEntity<ApiError> response(
            HttpStatus status, String message, HttpServletRequest request) {
        ApiError body = new ApiError(
            Instant.now(), status.value(), status.getReasonPhrase(),
            message == null ? status.getReasonPhrase() : message,
            request.getRequestURI());
        return ResponseEntity.status(status).body(body);
    }
}
