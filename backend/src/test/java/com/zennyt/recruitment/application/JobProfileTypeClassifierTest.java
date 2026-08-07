package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.EmbeddingPort;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.infrastructure.ai.NoOpEmbeddingPort;
import org.junit.jupiter.api.Test;

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
}
