package com.zennyt.shared.infrastructure.ai;

import com.zennyt.shared.application.port.EmbeddingPort;

/** Repli par défaut quand aucun service d'empreintes n'est configuré — jamais d'erreur, jamais de bonus sémantique. */
public class NoOpEmbeddingPort implements EmbeddingPort {
    @Override
    public float[] embed(String text) {
        return null;
    }
}
