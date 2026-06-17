package com.zennyt.identity.api.security;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.*;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT')")
public @interface CandidateOrStudentOnly {
}
