package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class ActorDirectory {
    private final EngagementActorRepository actors;

    public record ActorPresentation(String displayName, String photoUrl) {}

    public EngagementActor find(UUID userId) {
        return actors.findById(userId).orElse(null);
    }

    public String displayName(UUID userId) {
        EngagementActor actor = find(userId);
        return actor == null || actor.displayName() == null || actor.displayName().isBlank()
            ? "Utilisateur Zennyt" : actor.displayName();
    }

    public String photoUrl(UUID userId) {
        EngagementActor actor = find(userId);
        return actor == null ? null : actor.photoUrl();
    }

    public ActorPresentation presentation(UUID userId) {
        return presentationOf(find(userId));
    }

    public Map<UUID, ActorPresentation> presentations(Collection<UUID> userIds) {
        Set<UUID> distinctIds = new LinkedHashSet<>(userIds);
        Map<UUID, ActorPresentation> result = new HashMap<>();
        actors.findAllByIds(distinctIds).forEach(actor ->
            result.put(actor.userId(), presentationOf(actor)));
        distinctIds.forEach(userId -> result.putIfAbsent(userId, presentationOf(null)));
        return Map.copyOf(result);
    }

    private ActorPresentation presentationOf(EngagementActor actor) {
        String name = actor == null || actor.displayName() == null || actor.displayName().isBlank()
            ? "Utilisateur Zennyt" : actor.displayName();
        return new ActorPresentation(name, actor == null ? null : actor.photoUrl());
    }
}
