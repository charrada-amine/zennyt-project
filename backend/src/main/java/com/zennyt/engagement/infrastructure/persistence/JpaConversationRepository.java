package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

interface JpaConversationRepository extends JpaRepository<ConversationEntity, UUID> {
    Optional<ConversationEntity> findByIdAndCandidateIdOrIdAndRecruiterId(
        UUID candidateConversationId, UUID candidateId,
        UUID recruiterConversationId, UUID recruiterId);
    Optional<ConversationEntity> findByApplicationIdAndCandidateIdOrApplicationIdAndRecruiterId(
        UUID candidateApplicationId, UUID candidateId,
        UUID recruiterApplicationId, UUID recruiterId);
    Page<ConversationEntity> findByCandidateIdOrRecruiterId(
        UUID candidateId, UUID recruiterId, Pageable pageable);
}
