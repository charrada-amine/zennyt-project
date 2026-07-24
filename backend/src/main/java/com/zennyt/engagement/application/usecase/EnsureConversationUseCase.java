package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Commande idempotente : retourne la conversation de la candidature pour le
 * participant, en la créant si nécessaire à partir de la projection locale.
 *
 * <p>Remplace l'ancien couple « find-only + 201 » : l'appelant sait, via
 * {@link Result#created()}, si une conversation a réellement été créée (201) ou
 * si elle préexistait (200). La contrainte {@code UNIQUE(application_id)} arbitre
 * deux créations concurrentes ; aucun appel direct au module Recruitment.
 */
@Service
@RequiredArgsConstructor
public class EnsureConversationUseCase {
    private final ConversationRepository conversations;
    private final EngagementApplicationRepository applications;

    public record Result(Conversation conversation, boolean created) {}

    @Transactional
    public Result execute(UUID actorId, UUID applicationId) {
        var existing = conversations.findByApplicationIdAndParticipantId(applicationId, actorId);
        if (existing.isPresent()) {
            return new Result(existing.get(), false);
        }

        EngagementApplication application = applications.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        if (!application.hasParticipant(actorId)) {
            // Un tiers ne doit pas révéler l'existence de la candidature.
            throw new NotFoundException("Candidature introuvable");
        }

        Conversation candidate = Conversation.create(
            application.applicationId(), application.jobOfferId(),
            application.candidateId(), application.recruiterId(), application.jobTitle());
        boolean created = conversations.createIfAbsent(candidate);
        Conversation persisted = conversations
            .findByApplicationIdAndParticipantId(applicationId, actorId)
            .orElseThrow(() -> new IllegalStateException(
                "La conversation n'a pas pu être relue après sa création atomique"));
        return new Result(persisted, created);
    }
}
