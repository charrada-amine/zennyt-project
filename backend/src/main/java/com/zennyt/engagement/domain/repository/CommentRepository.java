package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Comment;

import java.util.List;
import java.util.UUID;

public interface CommentRepository {
    Comment save(Comment comment);
    List<Comment> findByPostId(UUID postId);
}
