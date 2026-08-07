package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.TestAttempt;

import java.util.Optional;
import java.util.UUID;

/** Port du repository de tentatives de test de compétences. */
public interface TestAttemptRepository {

    TestAttempt save(TestAttempt attempt);

    Optional<TestAttempt> findById(UUID id);
}
