package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service @RequiredArgsConstructor
public class DeletePostUseCase {
    private final PostRepository posts;
    @Transactional public void execute(UUID actorId, UUID postId) {
        Post post = posts.findById(postId).orElseThrow(() -> new NotFoundException("Publication introuvable"));
        if (!post.authorId().equals(actorId)) throw new ForbiddenException("Seul l'auteur peut supprimer cette publication");
        posts.delete(postId);
    }
}
