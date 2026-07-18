package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

interface JpaHelpMessageRepository extends JpaRepository<HelpMessageEntity, UUID> {
    List<HelpMessageEntity> findByHelpChatIdOrderByTimestampAscIdAsc(UUID helpChatId);
}
