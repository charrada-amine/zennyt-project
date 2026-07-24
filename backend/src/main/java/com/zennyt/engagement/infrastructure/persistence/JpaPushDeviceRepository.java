package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

interface JpaPushDeviceRepository extends JpaRepository<PushDeviceEntity, UUID> {
    Optional<PushDeviceEntity> findByToken(String token);
}
