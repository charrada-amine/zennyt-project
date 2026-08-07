package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.Map;

/**
 * Suggère à quelle famille de métier (Couche A de la matrice Fit Score,
 * inspirée RIASEC) rattacher un métier nouvellement proposé — réutilise le
 * même port d'empreintes que la recherche sémantique "Recommended for you"
 * (voir plan), pas de second système IA.
 *
 * <p>Simple suggestion : l'admin choisit toujours librement le profil à
 * l'approbation ({@link com.zennyt.recruitment.application.usecase.ReviewJobPositionUseCase#approve}) —
 * une classification imprécise ou absente (mode NoOp, pas de clé configurée)
 * ne bloque jamais la proposition.
 */
@Component
public class JobProfileTypeClassifier {

    private static final Map<JobProfileType, String> DESCRIPTIONS = new EnumMap<>(Map.of(
        JobProfileType.TECHNIQUE,
        "Métiers techniques et manuels, ancrés dans le concret : construction, mécanique, "
            + "production, maintenance, logistique, travail de terrain.",
        JobProfileType.ANALYTIQUE,
        "Métiers d'analyse et de résolution de problèmes complexes : recherche, ingénierie, "
            + "data, sciences, développement logiciel, expertise technique poussée.",
        JobProfileType.RELATIONNEL,
        "Métiers centrés sur l'aide, l'accompagnement et la relation humaine : santé, "
            + "éducation, service client, ressources humaines, travail social.",
        JobProfileType.MANAGERIAL,
        "Métiers de direction, de persuasion et de prise de décision : management, vente, "
            + "entrepreneuriat, développement commercial, animation d'équipe.",
        JobProfileType.CONVENTIONNEL,
        "Métiers structurés, organisés, basés sur des règles précises : comptabilité, "
            + "administration, gestion de données, conformité, opérations back-office.",
        JobProfileType.ARTISTIQUE,
        "Métiers créatifs et d'expression : design, communication, contenu, arts, mode, "
            + "médias, création visuelle ou narrative."));

    private final EmbeddingPort embeddings;
    private volatile Map<JobProfileType, float[]> profileEmbeddings;

    public JobProfileTypeClassifier(EmbeddingPort embeddings) {
        this.embeddings = embeddings;
    }

    /**
     * @param jobPositionEmbedding empreinte déjà calculée du nom du métier proposé (évite un second appel externe)
     * @return la famille la plus proche sémantiquement, ou {@code null} si aucune empreinte n'est disponible
     */
    public JobProfileType suggest(float[] jobPositionEmbedding) {
        if (jobPositionEmbedding == null) return null;
        JobProfileType best = null;
        double bestSimilarity = -1;
        for (var entry : profileEmbeddings().entrySet()) {
            Double similarity = EmbeddingCodec.cosineSimilarity(jobPositionEmbedding, entry.getValue());
            if (similarity != null && similarity > bestSimilarity) {
                bestSimilarity = similarity;
                best = entry.getKey();
            }
        }
        return best;
    }

    /** Calculées une seule fois (lazy) : les 6 familles sont fixes, jamais recalculées à chaque proposition. */
    private Map<JobProfileType, float[]> profileEmbeddings() {
        Map<JobProfileType, float[]> cached = profileEmbeddings;
        if (cached != null) return cached;
        Map<JobProfileType, float[]> computed = new EnumMap<>(JobProfileType.class);
        DESCRIPTIONS.forEach((type, description) -> {
            float[] embedding = embeddings.embed(description);
            if (embedding != null) computed.put(type, embedding);
        });
        profileEmbeddings = computed;
        return computed;
    }
}
