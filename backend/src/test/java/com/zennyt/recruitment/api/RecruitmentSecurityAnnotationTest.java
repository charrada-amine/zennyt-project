package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.CreateJobOfferRequest;
import com.zennyt.recruitment.api.dto.SwipeRequest;
import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.lang.reflect.Method;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class RecruitmentSecurityAnnotationTest {
    private static final List<Class<?>> CONTROLLERS = List.of(
        ApplicationController.class, AssessmentAttemptController.class,
        AssessmentController.class, CallbackController.class, CandidateResumeController.class,
        FitScoreController.class,
        IdentityVerificationController.class, JobOfferController.class,
        JobOpportunityOfferController.class, MatchController.class,
        PaymentController.class, PublicTestController.class, SwipeController.class);

    private static final Set<String> INTENTIONALLY_PUBLIC = Set.of(
        "JobOfferController#getById", "JobOfferController#search", "PublicTestController#getByToken",
        "CallbackController#fitScore", "CallbackController#integrity",
        "CallbackController#identity");

    @Test
    void everyRecruitmentEndpointIsProtectedOrExplicitlyPublic() {
        var endpoints = CONTROLLERS.stream()
            .flatMap(type -> Stream.of(type.getDeclaredMethods())
                .filter(RecruitmentSecurityAnnotationTest::isEndpoint)
                .map(method -> new Endpoint(type, method)))
            .toList();

        assertThat(endpoints).hasSize(48);
        assertThat(endpoints)
            .allSatisfy(endpoint -> assertThat(isProtected(endpoint.method())
                || INTENTIONALLY_PUBLIC.contains(endpoint.key()))
                .as(endpoint.key()).isTrue());
        assertThat(endpoints.stream().filter(e -> !isProtected(e.method())).map(Endpoint::key))
            .containsExactlyInAnyOrderElementsOf(INTENTIONALLY_PUBLIC);
    }

    @Test
    void actorIdentifiersAreNotAcceptedInActorControlledRequests() {
        assertThat(componentNames(CreateJobOfferRequest.class)).doesNotContain("recruiterId");
        assertThat(componentNames(SwipeRequest.class)).doesNotContain("swiperId");
    }

    private static boolean isEndpoint(Method method) {
        return Stream.of(GetMapping.class, PostMapping.class, PutMapping.class,
                PatchMapping.class, DeleteMapping.class)
            .anyMatch(method::isAnnotationPresent);
    }

    private static boolean isProtected(Method method) {
        return method.isAnnotationPresent(Authenticated.class)
            || method.isAnnotationPresent(CandidateOrStudentOnly.class)
            || method.isAnnotationPresent(RecruiterOnly.class)
            || method.isAnnotationPresent(PreAuthorize.class);
    }

    private static Set<String> componentNames(Class<?> recordType) {
        return Stream.of(recordType.getRecordComponents())
            .map(component -> component.getName()).collect(java.util.stream.Collectors.toSet());
    }

    private record Endpoint(Class<?> type, Method method) {
        String key() { return type.getSimpleName() + "#" + method.getName(); }
    }
}
