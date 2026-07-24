package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.UserPostPreferences;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service @RequiredArgsConstructor
public class BlockAuthorUseCase {
    private final EngagementActorRepository actors;
    private final UserPostPreferencesRepository preferences;
    @Transactional public void execute(UUID actorId, UUID authorId) {
        if (actorId.equals(authorId)) throw new IllegalArgumentException("Impossible de se bloquer soi-même");
        if (actors.findById(authorId).isEmpty()) throw new NotFoundException("Auteur introuvable");
        UserPostPreferences current = preferences.findByUserId(actorId)
            .orElseGet(() -> UserPostPreferences.empty(actorId));
        LinkedHashSet<UUID> blocked = new LinkedHashSet<>(current.blockedAuthorIds());
        blocked.add(authorId);
        preferences.save(new UserPostPreferences(actorId, current.hiddenPostIds(), blocked.stream().toList()));
    }
}
