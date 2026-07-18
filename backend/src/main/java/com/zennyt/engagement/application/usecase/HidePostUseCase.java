package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.UserPostPreferences;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service @RequiredArgsConstructor
public class HidePostUseCase {
    private final PostRepository posts;
    private final UserPostPreferencesRepository preferences;
    @Transactional public void execute(UUID actorId, UUID postId) {
        if (posts.findById(postId).isEmpty()) throw new NotFoundException("Publication introuvable");
        UserPostPreferences current = preferences.findByUserId(actorId)
            .orElseGet(() -> UserPostPreferences.empty(actorId));
        LinkedHashSet<UUID> hidden = new LinkedHashSet<>(current.hiddenPostIds());
        hidden.add(postId);
        preferences.save(new UserPostPreferences(actorId, hidden.stream().toList(), current.blockedAuthorIds()));
    }
}
