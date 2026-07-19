package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

interface JpaMessageRepository extends JpaRepository<MessageEntity, UUID> {
    List<MessageEntity> findByConversationIdOrderBySentAtDescIdDesc(UUID conversationId, Pageable pageable);

    @Query(value = """
        SELECT message.* FROM engagement.messages message
        JOIN engagement.messages cursor
          ON cursor.id = :beforeId AND cursor.conversation_id = :conversationId
        WHERE message.conversation_id = :conversationId
          AND (message.sent_at < cursor.sent_at
            OR (message.sent_at = cursor.sent_at AND message.id < cursor.id))
        ORDER BY message.sent_at DESC, message.id DESC
        """, nativeQuery = true)
    List<MessageEntity> findBefore(@Param("conversationId") UUID conversationId,
                                   @Param("beforeId") UUID beforeId, Pageable pageable);

    @Modifying
    @Query("update MessageEntity message set message.readAt = :readAt " +
           "where message.conversationId = :conversationId and message.senderId <> :readerId " +
           "and message.readAt is null")
    int markReceivedAsRead(@Param("conversationId") UUID conversationId,
                           @Param("readerId") UUID readerId,
                           @Param("readAt") Instant readAt);
}
