package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.UserPostPreferences;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class UpdatePostPreferencesUseCase {
    private final UserPostPreferencesRepository preferences;
    @Transactional public UserPostPreferences execute(UUID actorId, List<UUID> hidden, List<UUID> blocked) {
        return preferences.save(new UserPostPreferences(actorId, hidden, blocked));
    }
}
