package com.zennyt.recruitment.application.command;

import java.util.UUID;

/** Commande d'entrée du use case de soumission de candidature. */
public record SubmitApplicationCommand(
    UUID candidateId,
    UUID jobId,
    String coverLetter
) {}
