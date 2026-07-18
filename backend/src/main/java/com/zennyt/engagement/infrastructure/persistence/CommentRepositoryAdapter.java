package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Comment;
import com.zennyt.engagement.domain.repository.CommentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class CommentRepositoryAdapter implements CommentRepository {
    private final JpaCommentRepository jpa;
    @Override public Comment save(Comment comment) {
        return toDomain(jpa.save(new CommentEntity(comment.id(), comment.postId(),
            comment.authorId(), comment.content(), comment.createdAt())));
    }
    @Override public List<Comment> findByPostId(UUID postId) {
        return jpa.findByPostIdOrderByCreatedAtAscIdAsc(postId).stream().map(this::toDomain).toList();
    }
    private Comment toDomain(CommentEntity entity) {
        return new Comment(entity.getId(), entity.getPostId(), entity.getAuthorId(),
            entity.getContent(), entity.getCreatedAt());
    }
}
