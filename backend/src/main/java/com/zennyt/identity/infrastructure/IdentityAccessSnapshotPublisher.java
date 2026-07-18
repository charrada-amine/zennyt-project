package com.zennyt.identity.infrastructure;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

/** Rejoue un snapshot idempotent pour initialiser les projections des autres contextes. */
@Component
@RequiredArgsConstructor
public class IdentityAccessSnapshotPublisher implements ApplicationRunner {
    private final UserRepository users;
    private final ApplicationEventPublisher events;

    @Override
    public void run(ApplicationArguments args) {
        users.findAll().forEach(user -> events.publishEvent(UserAccessStateChangedEvent.of(
            user.publicId(), user.role().name(), user.active(),
            user.firstName() + " " + user.lastName(), user.profileImageUrl())));
    }
}
