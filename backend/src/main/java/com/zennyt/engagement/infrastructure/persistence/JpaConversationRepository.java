package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

interface JpaConversationRepository extends JpaRepository<ConversationEntity, UUID> {
    @Modifying
    @Query(value = """
        INSERT INTO engagement.conversations(
            id, application_id, job_offer_id, candidate_id, recruiter_id, job_title,
            last_message_preview, last_message_at, candidate_unread_count,
            recruiter_unread_count, version)
        VALUES (
            :id, :applicationId, :jobOfferId, :candidateId, :recruiterId, :jobTitle,
            :lastMessagePreview, :lastMessageAt, :candidateUnreadCount,
            :recruiterUnreadCount, 0)
        ON CONFLICT (application_id) DO NOTHING
        """, nativeQuery = true)
    int insertIfApplicationAbsent(
        @Param("id") UUID id,
        @Param("applicationId") UUID applicationId,
        @Param("jobOfferId") UUID jobOfferId,
        @Param("candidateId") UUID candidateId,
        @Param("recruiterId") UUID recruiterId,
        @Param("jobTitle") String jobTitle,
        @Param("lastMessagePreview") String lastMessagePreview,
        @Param("lastMessageAt") Instant lastMessageAt,
        @Param("candidateUnreadCount") int candidateUnreadCount,
        @Param("recruiterUnreadCount") int recruiterUnreadCount);

    Optional<ConversationEntity> findByIdAndCandidateIdOrIdAndRecruiterId(
        UUID candidateConversationId, UUID candidateId,
        UUID recruiterConversationId, UUID recruiterId);
    Optional<ConversationEntity> findByApplicationIdAndCandidateIdOrApplicationIdAndRecruiterId(
        UUID candidateApplicationId, UUID candidateId,
        UUID recruiterApplicationId, UUID recruiterId);
    Page<ConversationEntity> findByCandidateIdOrRecruiterId(
        UUID candidateId, UUID recruiterId, Pageable pageable);
}
