package com.zennyt.engagement.api.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/** Requête validée de (ré)ouverture d'une conversation de candidature. */
public record ConversationCreateRequest(@NotNull UUID applicationId) {}
