package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Post;
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
    @Transactional public Post execute(UUID actorId, UUID postId, UUID optionId) {
        Post post = getPost.execute(actorId, postId);
        if (posts.hasVoted(postId, actorId)) throw new ConflictException("Vous avez déjà voté");
        post.voteOnPoll(optionId);
        Post saved = posts.save(post);
        posts.recordVote(postId, actorId, optionId);
        return saved;
    }
}
