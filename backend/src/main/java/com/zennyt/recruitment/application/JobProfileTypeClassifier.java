package com.zennyt.recruitment.application;

import com.zennyt.shared.application.EmbeddingCodec;

import com.zennyt.shared.application.port.EmbeddingPort;
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

    /**
     * F09 (FITSCORE_REMEDIATION.md §3 index F09) — descriptions réécrites depuis
     * le CdC §4.3 (nature dominante de chaque profil) et la matrice réellement
     * seedée (V26), qu'elles contredisaient auparavant : par ex. « développement
     * logiciel » était rattaché à ANALYTIQUE alors que les 9 métiers IT/dev
     * (Développeur, DevOps, IA, Data Engineer…) sont seedés en TECHNIQUE, et
     * « vente » était rattachée à MANAGERIAL alors que Commercial/BD et
     * Conseiller de vente sont seedés en RELATIONNEL. Chaque description
     * mentionne désormais des métiers réels de V26 pour ancrer le classifieur
     * sur le vocabulaire effectivement utilisé par la plateforme.
     */
    private static final Map<JobProfileType, String> DESCRIPTIONS = new EnumMap<>(Map.of(
        JobProfileType.TECHNIQUE,
        "Résolution concrète de problèmes techniques : construire, développer, réparer. Couvre "
            + "aussi bien le développement logiciel et l'ingénierie IT/IA/DevOps que la médecine, "
            + "l'industrie, le BTP ou l'artisanat qualifié — ex. Développeur, Ingénieur DevOps / "
            + "Cloud, Ingénieur IA / Machine Learning, Médecin, Pharmacien, Ingénieur BTP, "
            + "Architecte, Technicien de maintenance, Ouvrier / Compagnon qualifié.",
        JobProfileType.ANALYTIQUE,
        "Analyse ouverte de données ou de situations complexes, recherche de sens dans "
            + "l'ambigu, hors résolution technique directe : audit, conseil, finance, contrôle "
            + "de gestion, data, études, veille — ex. Auditeur, Business Analyst, Analyste "
            + "financier, Contrôleur de gestion, Data Analyst / Data Scientist, Growth hacker, "
            + "Journaliste.",
        JobProfileType.RELATIONNEL,
        "Interaction humaine, écoute, persuasion, accompagnement — inclut la vente et le "
            + "développement commercial individuels : santé et soin, ressources humaines, "
            + "service client, accueil et restauration en contact clientèle — ex. Commercial / "
            + "Business Developer, Conseiller de vente, RH / Talent Acquisition, Support client "
            + "/ Service client, Infirmier, Kinésithérapeute, Réceptionniste, Serveur / Maître "
            + "d'hôtel.",
        JobProfileType.MANAGERIAL,
        "Coordination d'équipe, leadership, arbitrage — pilotage d'équipe plutôt que vente "
            + "individuelle (qui relève du profil Relationnel) : direction générale, gestion de "
            + "projet ou de produit, encadrement d'atelier ou de magasin — ex. Management "
            + "général / Direction, Chef de projet / Product Manager, Product Owner, Scrum "
            + "Master / Agile Coach, Responsable d'atelier / production, Responsable de "
            + "magasin, Directeur d'hôtel, Conducteur de travaux.",
        JobProfileType.CONVENTIONNEL,
        "Application de règles et de procédures documentées, précision d'exécution, expertise "
            + "qui se stabilise tôt plutôt que de se complexifier indéfiniment avec l'expérience "
            + ": comptabilité, conformité, gestion de stock, contrôle qualité, opérations "
            + "back-office — ex. Comptable, Chargé de conformité / Compliance officer, "
            + "Gestionnaire de stock, Technicien qualité, Opérateur de production, Métreur.",
        JobProfileType.ARTISTIQUE,
        "Création : génération d'idées, sens esthétique, expression visuelle ou narrative, "
            + "pensée divergente dominante à tous les niveaux d'ancienneté : design, "
            + "illustration, photographie, réalisation audiovisuelle, composition — ex. UX/UI "
            + "Designer, Graphiste / Designer, Motion designer, Styliste / Designer produit, "
            + "Illustrateur / Concept artist, Photographe, Compositeur / Sound designer, "
            + "Scénariste, Directeur artistique."));

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
