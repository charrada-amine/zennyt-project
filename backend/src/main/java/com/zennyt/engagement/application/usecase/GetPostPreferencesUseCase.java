package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.UserPostPreferences;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class GetPostPreferencesUseCase {
    private final UserPostPreferencesRepository preferences;
    @Transactional(readOnly = true) public UserPostPreferences execute(UUID actorId) {
        return preferences.findByUserId(actorId).orElseGet(() -> UserPostPreferences.empty(actorId));
    }
}
