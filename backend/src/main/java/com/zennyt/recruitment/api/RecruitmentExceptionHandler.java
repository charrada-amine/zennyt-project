package com.zennyt.recruitment.api;

import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;

@RestControllerAdvice(basePackages = "com.zennyt.recruitment.api")
public class RecruitmentExceptionHandler {
    record ApiError(Instant timestamp, int status, String error, String message, String path) {}

    @ExceptionHandler(UpstreamServiceException.class)
    ResponseEntity<ApiError> upstream(UpstreamServiceException exception, HttpServletRequest request) {
        var body = new ApiError(Instant.now(), HttpStatus.BAD_GATEWAY.value(),
            HttpStatus.BAD_GATEWAY.getReasonPhrase(), exception.getMessage(), request.getRequestURI());
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(body);
    }
}
