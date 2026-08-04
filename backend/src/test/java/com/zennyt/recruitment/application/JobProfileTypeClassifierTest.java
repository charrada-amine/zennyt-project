package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.infrastructure.ai.NoOpEmbeddingPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.util.Locale;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

/**
 * Le classifieur réutilise le port d'empreintes existant pour situer un
 * nouveau métier parmi les 6 familles (Couche A) — jamais un second système
 * IA, jamais un calcul bloquant si aucune empreinte n'est disponible.
 */
class JobProfileTypeClassifierTest {

    @Test
    void suggestsFamilyClosestToTheGivenEmbedding() {
        // EnumMap itère dans l'ordre des ordinaux : TECHNIQUE, ANALYTIQUE, RELATIONNEL,
        // MANAGERIAL, CONVENTIONNEL, ARTISTIQUE -> le 3e appel embed() correspond à RELATIONNEL.
        EmbeddingPort oneHotPerFamily = new EmbeddingPort() {
            private int calls = 0;
            @Override public float[] embed(String text) {
                float[] vector = new float[JobProfileType.values().length];
                vector[calls % vector.length] = 1f;
                calls++;
                return vector;
            }
        };
        JobProfileTypeClassifier classifier = new JobProfileTypeClassifier(oneHotPerFamily);

        JobProfileType suggestion = classifier.suggest(new float[]{0, 0, 1, 0, 0, 0});

        assertThat(suggestion).isEqualTo(JobProfileType.RELATIONNEL);
    }

    @Test
    void noEmbeddingServiceConfigured_returnsNullRatherThanGuessing() {
        JobProfileTypeClassifier classifier = new JobProfileTypeClassifier(new NoOpEmbeddingPort());

        assertThat(classifier.suggest(new float[]{1, 0, 0, 0, 0, 0})).isNull();
    }

    @Test
    void nullEmbedding_returnsNullWithoutCallingThePort() {
        EmbeddingPort port = mock(EmbeddingPort.class);
        JobProfileTypeClassifier classifier = new JobProfileTypeClassifier(port);

        assertThat(classifier.suggest(null)).isNull();
        verifyNoInteractions(port);
    }

    /**
     * F09 (FITSCORE_REMEDIATION.md §3 index F09, §6 B1) — la seule couverture
     * précédente de {@code DESCRIPTIONS} portait sur des vecteurs one-hot
     * synthétiques (voir {@code suggestsFamilyClosestToTheGivenEmbedding} plus
     * haut) : elle valide l'argmax du classifieur, jamais que les descriptions
     * elles-mêmes pointent vers le bon profil pour un vrai intitulé de métier.
     *
     * <p>Ce test rejoue le classifieur avec un port d'empreintes lexical (sac de
     * mots hashé) plutôt qu'un vrai service d'IA — suffisant pour vérifier que
     * les descriptions réécrites partagent le bon vocabulaire avec les métiers
     * seedés en V26, sans dépendance externe ni non-déterminisme. Les 10
     * intitulés couvrent les deux contradictions corrigées par F09 : le
     * développement logiciel est TECHNIQUE (pas ANALYTIQUE), la vente
     * individuelle est RELATIONNEL (pas MANAGERIAL).
     */
    @ParameterizedTest(name = "\"{0}\" (seedé V26) -> {1}")
    @CsvSource({
        "Développeur, TECHNIQUE",
        "Ingénieur IA / Machine Learning, TECHNIQUE",
        "Data Analyst / Data Scientist, ANALYTIQUE",
        "Commercial / Business Developer, RELATIONNEL",
        "Conseiller de vente, RELATIONNEL",
        "Infirmier, RELATIONNEL",
        "Chef de projet / Product Manager, MANAGERIAL",
        "Responsable de magasin, MANAGERIAL",
        "Comptable, CONVENTIONNEL",
        "UX/UI Designer, ARTISTIQUE",
    })
    void reclassifiesRealSeededJobTitlesOnTheirOwnProfile(String jobTitle, JobProfileType expectedProfile) {
        JobProfileTypeClassifier classifier = new JobProfileTypeClassifier(JobProfileTypeClassifierTest::bagOfWords);

        JobProfileType suggestion = classifier.suggest(bagOfWords(jobTitle));

        assertThat(suggestion).isEqualTo(expectedProfile);
    }

    // Mots-outils français à ignorer : sans ce filtre, "de" (répété 7 fois dans la
    // description CONVENTIONNEL — "Gestionnaire de stock", "Chargé de conformité"…)
    // domine le produit scalaire face à un intitulé court comme "Conseiller de vente"
    // et masque le vrai signal lexical ("conseiller", "vente").
    private static final java.util.Set<String> STOPWORDS = java.util.Set.of(
        "de", "du", "des", "le", "la", "les", "un", "une", "et", "en", "à", "d", "l", "ou",
        "que", "qui", "pour", "sur", "ex", "au", "aux", "ce", "ses", "son", "sa");

    /** Empreinte lexicale déterministe (sac de mots hashé) — proxy local pour un vrai service d'embeddings. */
    private static float[] bagOfWords(String text) {
        float[] vector = new float[4096];
        for (String word : text.toLowerCase(Locale.ROOT).split("[^\\p{L}]+")) {
            if (word.isBlank() || STOPWORDS.contains(word)) continue;
            vector[Math.floorMod(word.hashCode(), vector.length)] += 1f;
        }
        return vector;
    }
}
