package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Post;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.engagement.domain.vo.PostVisibility;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class CreatePostUseCase {
    private final PostRepository posts;
    @Transactional
    public Post execute(UUID actorId, PostVisibility visibility, String content,
                        List<Post.PostMedia> media, Post.Poll poll) {
        return posts.save(Post.create(actorId, visibility, content, media, poll));
    }
}
