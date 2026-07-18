package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Comment;
import com.zennyt.engagement.domain.repository.CommentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class ListCommentsUseCase {
    private final GetPostUseCase getPost;
    private final CommentRepository comments;
    @Transactional(readOnly = true) public List<Comment> execute(UUID actorId, UUID postId) {
        getPost.execute(actorId, postId);
        return comments.findByPostId(postId);
    }
}
