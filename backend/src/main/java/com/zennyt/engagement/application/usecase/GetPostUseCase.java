package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.PostView;
import com.zennyt.engagement.domain.repository.FriendshipRepository;
import com.zennyt.engagement.domain.repository.PostRepository;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import com.zennyt.engagement.domain.vo.PostVisibility;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service @RequiredArgsConstructor
public class GetPostUseCase {
    private final PostRepository posts;
    private final UserPostPreferencesRepository preferences;
    private final FriendshipRepository friendships;

    @Transactional(readOnly = true)
    public PostView execute(UUID actorId, UUID postId) {
        PostView view = posts.findViewById(postId, actorId)
            .orElseThrow(() -> new NotFoundException("Publication introuvable"));
        UUID authorId = view.post().authorId();
        var prefs = preferences.findByUserId(actorId).orElse(null);
        boolean hidden = prefs != null && (prefs.hiddenPostIds().contains(postId)
            || prefs.blockedAuthorIds().contains(authorId));
        boolean visible = view.post().visibility() == PostVisibility.PUBLIC
            || authorId.equals(actorId) || friendships.areFriends(actorId, authorId);
        if (hidden || !visible) throw new NotFoundException("Publication introuvable");
        return view;
    }
}
