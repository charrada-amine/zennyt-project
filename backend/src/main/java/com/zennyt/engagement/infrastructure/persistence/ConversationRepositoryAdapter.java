package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ConversationRepositoryAdapter implements ConversationRepository {
    private final JpaConversationRepository jpa;

    @Override
    public Conversation save(Conversation conversation) {
        ConversationEntity entity = jpa.findById(conversation.id())
            .orElseGet(() -> new ConversationEntity(
                conversation.id(), conversation.applicationId(), conversation.jobOfferId(),
                conversation.candidateId(), conversation.recruiterId(), conversation.jobTitle(),
                conversation.lastMessagePreview(), conversation.lastMessageAt(),
                conversation.candidateUnreadCount(), conversation.recruiterUnreadCount()));
        entity.update(conversation.applicationId(), conversation.jobOfferId(),
            conversation.candidateId(), conversation.recruiterId(), conversation.jobTitle(),
            conversation.lastMessagePreview(), conversation.lastMessageAt(),
            conversation.candidateUnreadCount(), conversation.recruiterUnreadCount());
        return toDomain(jpa.save(entity));
    }

    @Override
    public Optional<Conversation> findByIdAndParticipantId(UUID id, UUID participantId) {
        return jpa.findByIdAndCandidateIdOrIdAndRecruiterId(id, participantId, id, participantId)
            .map(this::toDomain);
    }

    @Override
    public Optional<Conversation> findByApplicationIdAndParticipantId(
            UUID applicationId, UUID participantId) {
        return jpa.findByApplicationIdAndCandidateIdOrApplicationIdAndRecruiterId(
                applicationId, participantId, applicationId, participantId)
            .map(this::toDomain);
    }

    @Override
    public PageSlice<Conversation> findByParticipantId(UUID participantId, int page, int size) {
        var pageable = PageRequest.of(page, size,
            Sort.by(Sort.Order.desc("lastMessageAt").nullsLast(), Sort.Order.desc("id")));
        var result = jpa.findByCandidateIdOrRecruiterId(participantId, participantId, pageable);
        return new PageSlice<>(result.map(this::toDomain).getContent(),
            result.getNumber(), result.getSize(), result.getTotalElements());
    }

    private Conversation toDomain(ConversationEntity entity) {
        return Conversation.rehydrate(entity.getId(), entity.getApplicationId(),
            entity.getJobOfferId(), entity.getCandidateId(), entity.getRecruiterId(),
            entity.getJobTitle(), entity.getLastMessagePreview(), entity.getLastMessageAt(),
            entity.getCandidateUnreadCount(), entity.getRecruiterUnreadCount());
    }
}
