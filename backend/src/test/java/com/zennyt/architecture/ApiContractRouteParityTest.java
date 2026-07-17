package com.zennyt.architecture;

import com.zennyt.identity.api.*;
import com.zennyt.recruitment.api.*;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

class ApiContractRouteParityTest {
    private static final Pattern PATH_PARAMETER = Pattern.compile("\\{[^}]+}");

    @Test
    void identityContractMatchesAllRuntimeRoutes() throws IOException {
        Set<String> runtime = runtimeRoutes(List.of(
            AuthController.class, OnboardingController.class,
            ProfileController.class, CvParseController.class));

        assertThat(runtime).hasSize(46);
        assertThat(contractRoutes("identity.openapi.yaml")).isEqualTo(runtime);
    }

    @Test
    void recruitmentContractMatchesAllRuntimeRoutes() throws IOException {
        Set<String> runtime = runtimeRoutes(List.of(
            ApplicationController.class, AssessmentAttemptController.class,
            AssessmentController.class, CallbackController.class, FitScoreController.class,
            IdentityVerificationController.class, JobOfferController.class,
            JobOpportunityOfferController.class, MatchController.class,
            PaymentController.class, PublicTestController.class, SwipeController.class));

        assertThat(runtime).hasSize(43);
        assertThat(contractRoutes("recruitment.openapi.yaml")).isEqualTo(runtime);
    }

    private static Set<String> runtimeRoutes(List<Class<?>> controllers) {
        Set<String> routes = new TreeSet<>();
        for (Class<?> controller : controllers) {
            String base = Optional.ofNullable(controller.getAnnotation(RequestMapping.class))
                .map(RequestMapping::value).filter(values -> values.length > 0)
                .map(values -> values[0]).orElse("");
            for (Method method : controller.getDeclaredMethods()) {
                add(routes, "GET", base, values(method.getAnnotation(GetMapping.class)));
                add(routes, "POST", base, values(method.getAnnotation(PostMapping.class)));
                add(routes, "PUT", base, values(method.getAnnotation(PutMapping.class)));
                add(routes, "PATCH", base, values(method.getAnnotation(PatchMapping.class)));
                add(routes, "DELETE", base, values(method.getAnnotation(DeleteMapping.class)));
            }
        }
        return routes;
    }

    private static void add(Set<String> routes, String verb, String base, String[] values) {
        if (values == null) return;
        if (values.length == 0) values = new String[]{""};
        for (String value : values) routes.add(verb + " " + normalize(base + value));
    }

    private static String[] values(GetMapping a) { return a == null ? null : a.value(); }
    private static String[] values(PostMapping a) { return a == null ? null : a.value(); }
    private static String[] values(PutMapping a) { return a == null ? null : a.value(); }
    private static String[] values(PatchMapping a) { return a == null ? null : a.value(); }
    private static String[] values(DeleteMapping a) { return a == null ? null : a.value(); }

    private static Set<String> contractRoutes(String fileName) throws IOException {
        Path contract = Path.of("../contracts", fileName);
        if (!Files.exists(contract)) contract = Path.of("contracts", fileName);
        Set<String> routes = new TreeSet<>();
        String currentPath = null;
        boolean inPaths = false;
        for (String line : Files.readAllLines(contract)) {
            if (line.equals("paths:")) { inPaths = true; continue; }
            if (inPaths && line.equals("components:")) break;
            if (!inPaths) continue;
            if (line.matches("^  /[^:]+:$")) {
                currentPath = line.trim().substring(0, line.trim().length() - 1);
            } else if (currentPath != null && line.matches("^    (get|post|put|patch|delete):$")) {
                routes.add(line.trim().replace(":", "").toUpperCase() + " " + normalize(currentPath));
            }
        }
        return routes;
    }

    private static String normalize(String path) {
        String withoutPrefix = path.startsWith("/api/v1") ? path.substring(7) : path;
        return PATH_PARAMETER.matcher(withoutPrefix).replaceAll("{}");
    }
}
