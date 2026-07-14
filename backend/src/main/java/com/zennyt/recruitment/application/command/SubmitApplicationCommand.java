package com.zennyt.recruitment.application.command;

import java.util.UUID;

/** Commande pour soumettre une candidature. */
public record SubmitApplicationCommand(UUID candidateId, UUID jobOfferId) {}
