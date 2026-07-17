package com.zennyt.recruitment.api.security;

import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.UUID;

@Component("recruitmentActorPolicy")
@RequiredArgsConstructor
public class RecruitmentActorPolicy {
    private final RecruitmentActorRepository actors;

    public boolean active(String actorId) {
        return find(actorId).map(RecruitmentActor::active).orElse(false);
    }

    public boolean activeWithRole(String actorId, String role) {
        return find(actorId)
            .map(value -> value.active() && role.equals(value.role()))
            .orElse(false);
    }

    public boolean activeWithAnyRole(String actorId, String... roles) {
        Set<String> accepted = Set.of(roles);
        return find(actorId)
            .map(value -> value.active() && accepted.contains(value.role()))
            .orElse(false);
    }

    private java.util.Optional<RecruitmentActor> find(String actorId) {
        try {
            return actors.findById(UUID.fromString(actorId));
        } catch (IllegalArgumentException ex) {
            return java.util.Optional.empty();
        }
    }
}
