package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.MessageCreateRequest;
import com.zennyt.engagement.api.dto.PushDeviceRegistrationRequest;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class EngagementApiSafetyTest {
    private static final Pattern PATH_PARAMETER = Pattern.compile("\\{[^}]+}");
    private static final List<Class<?>> CONTROLLERS = List.of(
        ConversationController.class, MessageController.class,
        NotificationController.class, RealtimeController.class,
        PostController.class, CallController.class, HelpChatController.class,
        EngagementMediaController.class);

    @Test
    void all_contract_routes_are_protected_by_the_local_projection() {
        List<Method> endpoints = CONTROLLERS.stream()
            .flatMap(type -> Stream.of(type.getDeclaredMethods()))
            .filter(EngagementApiSafetyTest::isEndpoint)
            .toList();

        assertThat(endpoints).hasSize(31);
        assertThat(endpoints).allSatisfy(method ->
            assertThat(method.isAnnotationPresent(EngagementAuthenticated.class))
                .as(method.toGenericString()).isTrue());
    }

    @Test
    void actor_identifiers_and_system_role_are_not_client_controlled() {
        assertThat(componentNames(MessageCreateRequest.class))
            .doesNotContain("senderId", "senderRole", "actorId", "userId");
        assertThat(componentNames(PushDeviceRegistrationRequest.class))
            .doesNotContain("userId", "actorId");
        assertThat(MessageCreateRequest.ClientMessageContentType.values())
            .extracting(Enum::name).containsExactly("TEXT", "IMAGE", "FILE");
    }

    @Test
    void runtime_routes_match_the_contract() throws IOException {
        Set<String> contract = contractRoutes();
        Set<String> runtime = runtimeRoutes();

        assertThat(contract).hasSize(31);
        assertThat(runtime).isEqualTo(contract);
    }

    private static boolean isEndpoint(Method method) {
        return Stream.of(GetMapping.class, PostMapping.class, PutMapping.class,
                PatchMapping.class, DeleteMapping.class)
            .anyMatch(method::isAnnotationPresent);
    }

    private static Set<String> componentNames(Class<?> recordType) {
        return Stream.of(recordType.getRecordComponents())
            .map(component -> component.getName())
            .collect(java.util.stream.Collectors.toSet());
    }

    private static Set<String> runtimeRoutes() {
        Set<String> routes = new TreeSet<>();
        for (Class<?> controller : CONTROLLERS) {
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

    private static Set<String> contractRoutes() throws IOException {
        Path contract = Path.of("../contracts/engagement.openapi.yaml");
        if (!Files.exists(contract)) contract = Path.of("contracts/engagement.openapi.yaml");
        Set<String> routes = new TreeSet<>();
        String currentPath = null;
        boolean inPaths = false;
        for (String line : Files.readAllLines(contract)) {
            if (line.equals("paths:")) { inPaths = true; continue; }
            if (inPaths && line.equals("components:")) break;
            if (!inPaths) continue;
            if (line.matches("^  /[^:]+:$")) {
                currentPath = line.trim().replace(":", "");
            } else if (currentPath != null && line.matches("^    (get|post|put|patch|delete):$")) {
                routes.add(line.trim().replace(":", "").toUpperCase() + " " + normalize(currentPath));
            }
        }
        return routes;
    }

    private static void add(Set<String> routes, String verb, String base, String[] values) {
        if (values == null) return;
        if (values.length == 0) values = new String[]{""};
        for (String value : values) routes.add(verb + " " + normalize(base + value));
    }

    private static String[] values(GetMapping annotation) {
        return annotation == null ? null : annotation.value();
    }

    private static String[] values(PostMapping annotation) {
        return annotation == null ? null : annotation.value();
    }
    private static String[] values(PutMapping annotation) { return annotation == null ? null : annotation.value(); }
    private static String[] values(PatchMapping annotation) { return annotation == null ? null : annotation.value(); }
    private static String[] values(DeleteMapping annotation) { return annotation == null ? null : annotation.value(); }

    private static String normalize(String path) {
        String withoutPrefix = path.startsWith("/api/v1") ? path.substring(7) : path;
        return PATH_PARAMETER.matcher(withoutPrefix).replaceAll("{}");
    }
}
