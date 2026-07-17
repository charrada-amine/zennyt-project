package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.User;

import java.util.Optional;
import java.util.List;
import java.util.UUID;

public interface UserRepository {
    User save(User user);
    Optional<User> findById(Long id);
    Optional<User> findByEmail(String email);
    Optional<User> findByPublicId(UUID publicId);
    boolean existsByEmail(String email);
    List<User> findAll();
}
