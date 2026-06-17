package com.zennyt.identity.api;

import com.zennyt.identity.api.security.Authenticated;
import com.zennyt.identity.api.security.CandidateOrStudentOnly;
import com.zennyt.identity.api.security.RecruiterOnly;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class IdentitySecurityAnnotationTest {
    @Test
    void authControllerMarksOnlyCurrentUserAsAuthenticated() {
        assertThat(annotatedMethods(AuthController.class, Authenticated.class))
            .containsExactly("me");
        assertThat(annotatedMethods(AuthController.class, CandidateOrStudentOnly.class)).isEmpty();
        assertThat(annotatedMethods(AuthController.class, RecruiterOnly.class)).isEmpty();
    }

    @Test
    void onboardingControllerDeclaresRoleBoundaries() {
        assertThat(annotatedMethods(OnboardingController.class, CandidateOrStudentOnly.class))
            .containsExactlyInAnyOrder(
                "createCandidateStudent", "getCandidateStudent", "updateCandidateStudent");
        assertThat(annotatedMethods(OnboardingController.class, RecruiterOnly.class))
            .containsExactlyInAnyOrder("createRecruiter", "getRecruiter", "updateRecruiter");
    }

    @Test
    void profileControllerSeparatesAccountAndProfessionalProfileAccess() {
        assertThat(annotatedMethods(ProfileController.class, Authenticated.class))
            .containsExactlyInAnyOrder("updateUser", "changeRole");
        assertThat(annotatedMethods(ProfileController.class, CandidateOrStudentOnly.class))
            .containsExactlyInAnyOrder(
                "createProfile", "getProfile", "updateProfile",
                "skills", "addSkill", "updateSkill", "deleteSkill",
                "positions", "addPosition", "updatePosition", "deletePosition",
                "certifications", "addCertification", "updateCertification",
                "deleteCertification",
                "education", "addEducation", "updateEducation", "deleteEducation");
    }

    @Test
    void identityControllersDoNotExposeJwtPrincipalParameters() {
        assertThat(Stream.of(AuthController.class, OnboardingController.class, ProfileController.class)
            .flatMap(type -> Stream.of(type.getDeclaredMethods()))
            .flatMap(method -> Arrays.stream(method.getParameterTypes()))
            .map(Class::getName))
            .noneMatch(name -> name.equals("org.springframework.security.oauth2.jwt.Jwt"));
    }

    private static Set<String> annotatedMethods(
        Class<?> type, Class<? extends java.lang.annotation.Annotation> annotation) {
        return Stream.of(type.getDeclaredMethods())
            .filter(method -> method.isAnnotationPresent(annotation))
            .map(Method::getName)
            .collect(Collectors.toSet());
    }
}
