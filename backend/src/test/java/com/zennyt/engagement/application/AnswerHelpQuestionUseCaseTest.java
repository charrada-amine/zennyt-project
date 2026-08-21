package com.zennyt.engagement.application;

import com.zennyt.engagement.application.port.HelpAnswerPort;
import com.zennyt.engagement.application.port.HelpDocumentationPort;
import com.zennyt.engagement.application.usecase.AnswerHelpQuestionUseCase;
import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * L'assistant répond-il, et surtout : <b>se tait-il quand il ne sait pas</b> ?
 *
 * <p>C'est le comportement le plus important de tout le dispositif. Un assistant qui comble
 * les trous se trompe avec assurance, sur un sujet où l'utilisateur n'a aucun moyen de
 * vérifier — le mode d'échec le plus coûteux d'un centre d'aide automatique.
 */
class AnswerHelpQuestionUseCaseTest {

    private final HelpChatRepository chats = mock(HelpChatRepository.class);
    private final HelpMessageRepository messages = mock(HelpMessageRepository.class);
    private final HelpDocumentationPort documentation = mock(HelpDocumentationPort.class);
    private final HelpAnswerPort redacteur = mock(HelpAnswerPort.class);

    private final AnswerHelpQuestionUseCase assistant =
        new AnswerHelpQuestionUseCase(chats, messages, documentation, redacteur);

    private final HelpChat conversation =
        HelpChat.create(UUID.randomUUID(), "Assistance", "Service client 24/7");

    private static HelpDocumentationPort.Extrait resultat(String slug, String titre, String texte) {
        return new HelpDocumentationPort.Extrait(slug, titre, texte, 0.9, true);
    }

    private void conversationExiste() {
        when(chats.findById(conversation.id())).thenReturn(Optional.of(conversation));
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));
        when(messages.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    private HelpChat.HelpMessage repondre(String question) {
        return assistant.repondre(conversation.id(), question,
            HelpArticle.Audience.CANDIDATE, "fr");
    }

    /**
     * <b>Le test central.</b> Aucun fragment trouvé signifie : la question sort du corpus.
     * L'assistant doit l'admettre, et le service de rédaction ne doit même pas être appelé —
     * saisi sans extrait, il produirait un texte plausible à partir de rien.
     */
    @Test
    @DisplayName("Sans extrait trouvé, l'assistant avoue son ignorance sans rien inventer")
    void aveuDIgnorance() {
        conversationExiste();
        when(documentation.chercher(anyString(), any(), anyString(), anyInt())).thenReturn(List.of());

        HelpChat.HelpMessage reponse = repondre("Quelle est la capitale de l'Australie ?");

        assertThat(reponse.text()).contains("ne trouve pas de réponse");
        assertThat(reponse.text()).contains("parler à une personne");
        assertThat(reponse.fromUser()).isFalse();
        verify(redacteur, never()).redigerReponse(anyString(), anyList(), anyBoolean());
    }

    @Test
    @DisplayName("Avec un extrait, la réponse cite l'article dont elle vient")
    void reponseCiteSaSource() {
        conversationExiste();
        when(documentation.chercher(anyString(), any(), anyString(), anyInt()))
            .thenReturn(List.of(resultat("fit-score-vide",
                "Pourquoi une offre n'affiche-t-elle aucun Fit Score ?", "Quatre raisons.")));
        when(redacteur.redigerReponse(anyString(), anyList(), anyBoolean()))
            .thenReturn("Il faut avoir joué à au moins un mini-jeu.");

        HelpChat.HelpMessage reponse = repondre("Pourquoi mon score est vide ?");

        assertThat(reponse.text())
            .contains("Il faut avoir joué à au moins un mini-jeu.")
            .contains("Source : Pourquoi une offre n'affiche-t-elle aucun Fit Score ?");
    }

    /**
     * Sans service de rédaction — clé absente, quota dépassé, appel échoué — l'extrait est
     * servi tel quel. Moins fluide qu'une reformulation, mais exact : l'utilisateur lit la
     * documentation plutôt que rien.
     */
    @Test
    @DisplayName("Sans service de rédaction, l'extrait est servi tel quel")
    void repliSurLExtrait() {
        conversationExiste();
        when(documentation.chercher(anyString(), any(), anyString(), anyInt()))
            .thenReturn(List.of(resultat("jeux-rejouer", "Puis-je rejouer à un mini-jeu ?",
                "Oui. Le résultat le plus récent remplace le précédent.")));
        when(redacteur.redigerReponse(anyString(), anyList(), anyBoolean())).thenReturn(null);

        HelpChat.HelpMessage reponse = repondre("Puis-je rejouer ?");

        assertThat(reponse.text())
            .contains("Le résultat le plus récent remplace le précédent")
            .contains("Source : Puis-je rejouer à un mini-jeu ?");
    }

    /**
     * Le service de rédaction ne reçoit que les extraits retenus. S'il recevait la question
     * seule, il répondrait de mémoire — et cette mémoire n'est pas la documentation de la
     * plateforme.
     */
    @Test
    @DisplayName("Le rédacteur ne reçoit que les extraits retenus")
    void leRedacteurNeVoitQueLesExtraits() {
        conversationExiste();
        when(documentation.chercher(anyString(), any(), anyString(), anyInt()))
            .thenReturn(List.of(resultat("a", "Titre A", "Contenu A"),
                                resultat("b", "Titre B", "Contenu B")));
        when(redacteur.redigerReponse(anyString(), anyList(), anyBoolean())).thenReturn("Réponse.");

        repondre("Une question");

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> extraits = ArgumentCaptor.forClass(List.class);
        verify(redacteur).redigerReponse(anyString(), extraits.capture(), anyBoolean());
        assertThat(extraits.getValue()).containsExactly("Contenu A", "Contenu B");
    }

    @Test
    @DisplayName("Une conversation inexistante ne produit aucune réponse")
    void conversationInexistante() {
        when(chats.findById(any())).thenReturn(Optional.empty());

        assertThat(assistant.repondre(UUID.randomUUID(), "Bonjour",
            HelpArticle.Audience.CANDIDATE, "fr")).isNull();
        verify(messages, never()).save(any());
    }

    @Test
    @DisplayName("La réponse est bien attribuée à l'assistant, pas à l'utilisateur")
    void reponseAttribueeALAssistant() {
        conversationExiste();
        when(documentation.chercher(anyString(), any(), anyString(), anyInt())).thenReturn(List.of());

        assertThat(repondre("Une question").fromUser()).isFalse();
    }
}
