package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class UnlikePostUseCase {
    private final PostRepository posts;
    private final GetPostUseCase getPost;
    @Transactional public void execute(UUID actorId, UUID postId) {
        getPost.execute(actorId, postId);
        posts.removeLike(postId, actorId);
    }
}
