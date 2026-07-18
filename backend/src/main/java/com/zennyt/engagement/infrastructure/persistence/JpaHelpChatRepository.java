package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

interface JpaHelpChatRepository extends JpaRepository<HelpChatEntity, UUID> {
    List<HelpChatEntity> findByUserIdOrderByLastMessageAtDesc(UUID userId);
    Optional<HelpChatEntity> findByIdAndUserId(UUID id, UUID userId);
}
