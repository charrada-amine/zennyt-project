package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class VoteOnPollUseCase {
    private final PostRepository posts;
    private final GetPostUseCase getPost;

    @Transactional
    public PostView execute(UUID actorId, UUID postId, UUID optionId) {
        Post post = getPost.execute(actorId, postId).post();   // visibilité + existence
        if (post.poll() == null) throw new NotFoundException("Cette publication n'a pas de sondage");
        boolean optionBelongsToPoll = post.poll().options().stream()
            .anyMatch(option -> option.id().equals(optionId));
        if (!optionBelongsToPoll) throw new NotFoundException("Option de sondage invalide");

        // Réservation atomique : la contrainte SQL arbitre deux votes concurrents.
        boolean reserved = posts.recordVoteIfAbsent(postId, actorId, optionId);
        if (!reserved) throw new ConflictException("Vous avez déjà voté");
        if (!posts.incrementOptionVote(optionId)) {
            throw new NotFoundException("Option de sondage invalide");
        }

        return posts.findViewById(postId, actorId)
            .orElseThrow(() -> new NotFoundException("Publication introuvable"));
    }
}
