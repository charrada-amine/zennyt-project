package com.zennyt.recruitment.infrastructure;

import com.zennyt.recruitment.application.EmbeddingCodec;
import com.zennyt.recruitment.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Calcule au démarrage l'empreinte numérique (embedding) des métiers du
 * référentiel qui n'en ont pas encore — couvre les 142 métiers seedés avant
 * l'introduction de la recherche sémantique (voir plan "Recommended for
 * you"). Idempotent : ne touche pas les métiers qui ont déjà une empreinte.
 */
@Component
@RequiredArgsConstructor
public class JobPositionEmbeddingBackfillRunner implements ApplicationRunner {
    private final JobPositionRepository positions;
    private final EmbeddingPort embeddings;

    @Override
    public void run(ApplicationArguments args) {
        positions.findByEmbeddingIsNull().forEach(position -> {
            String embedding = EmbeddingCodec.toJson(embeddings.embed(position.name()));
            if (embedding == null) return;
            position.updateEmbedding(embedding);
            positions.save(position);
        });
    }
}
