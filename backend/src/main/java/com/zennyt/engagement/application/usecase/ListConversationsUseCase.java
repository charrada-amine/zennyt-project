package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ListConversationsUseCase {
    private final ConversationRepository conversations;

    @Transactional(readOnly = true)
    public PageSlice<Conversation> execute(UUID actorId, int page, int size) {
        validatePage(page, size);
        return conversations.findByParticipantId(actorId, page, size);
    }

    static void validatePage(int page, int size) {
        if (page < 0 || size < 1 || size > 100) {
            throw new IllegalArgumentException("Pagination invalide (page >= 0, taille 1..100)");
        }
    }
}
