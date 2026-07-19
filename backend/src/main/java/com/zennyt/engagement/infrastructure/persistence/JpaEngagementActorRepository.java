package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface JpaEngagementActorRepository extends JpaRepository<EngagementActorEntity, UUID> {}
