package com.zennyt.engagement.application;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ActorDirectory {
    private final EngagementActorRepository actors;

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
}
