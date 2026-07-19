package com.zennyt.engagement.api.security;

import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.UUID;

@Component("engagementActorPolicy")
@RequiredArgsConstructor
public class EngagementActorPolicy {
    private static final Set<String> ALLOWED_ROLES = Set.of("CANDIDATE", "STUDENT", "RECRUITER");
    private final EngagementActorRepository actors;

    public boolean allowed(String actorId) {
        try {
            return actors.findById(UUID.fromString(actorId))
                .map(actor -> actor.active() && ALLOWED_ROLES.contains(actor.role()))
                .orElse(false);
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }
}
