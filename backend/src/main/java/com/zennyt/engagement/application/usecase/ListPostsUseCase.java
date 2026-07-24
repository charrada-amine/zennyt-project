package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service @RequiredArgsConstructor
public class ListPostsUseCase {
    private final PostRepository posts;
    @Transactional(readOnly = true)
    public PageSlice<PostView> execute(UUID actorId, int page, int size) {
        ListConversationsUseCase.validatePage(page, size);
        return posts.findFeed(actorId, page, size);
    }
}
