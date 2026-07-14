package com.zennyt.recruitment.api.security;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT') and "
    + "@recruitmentActorPolicy.activeWithAnyRole(authentication.name, 'CANDIDATE', 'STUDENT')")
public @interface CandidateOrStudentOnly {
}
