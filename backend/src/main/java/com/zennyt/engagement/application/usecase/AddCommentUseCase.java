package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Comment;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.repository.*;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class AddCommentUseCase {
    private final PostRepository posts;
    private final GetPostUseCase getPost;
    private final CommentRepository comments;
    private final NotificationRepository notifications;
    @Transactional public Comment execute(UUID actorId, UUID postId, String content) {
        Post post = getPost.execute(actorId, postId);
        Comment saved = comments.save(Comment.create(postId, actorId, content));
        post.incrementCommentsCount();
        posts.save(post);
        if (!post.authorId().equals(actorId)) {
            notifications.save(Notification.create(post.authorId(), NotificationType.NEW_COMMENT,
                "Nouveau commentaire", "Votre publication a reçu un nouveau commentaire",
                "/posts/" + postId));
        }
        return saved;
    }
}
