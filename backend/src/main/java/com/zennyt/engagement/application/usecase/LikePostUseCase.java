package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service @RequiredArgsConstructor
public class LikePostUseCase {
    private final PostRepository posts;
    private final GetPostUseCase getPost;
    private final NotificationRepository notifications;
    @Transactional public void execute(UUID actorId, UUID postId) {
        Post post = getPost.execute(actorId, postId).post();
        boolean created = posts.addLike(postId, actorId);
        if (created && !post.authorId().equals(actorId)) {
            notifications.save(Notification.create(post.authorId(), NotificationType.NEW_LIKE,
                "Nouvelle appréciation", "Votre publication a reçu une nouvelle appréciation",
                "/posts/" + postId));
        }
    }
}
