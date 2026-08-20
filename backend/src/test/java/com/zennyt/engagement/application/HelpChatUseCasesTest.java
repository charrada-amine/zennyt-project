package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.OpenHelpChatUseCase;
import com.zennyt.engagement.application.usecase.RateHelpChatUseCase;
import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.vo.HelpChatRating;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Ouverture et notation d'une conversation d'aide — étape 1 du centre d'aide.
 *
 * <p>Ces deux chemins n'existaient pas : la table des conversations ne pouvait pas se
 * remplir, et la note choisie par l'utilisateur ne quittait jamais l'écran.
 */
class HelpChatUseCasesTest {

    private final HelpChatRepository chats = mock(HelpChatRepository.class);
    private final OpenHelpChatUseCase ouvrir = new OpenHelpChatUseCase(chats);
    private final RateHelpChatUseCase noter = new RateHelpChatUseCase(chats);

    private static final UUID MOI = UUID.randomUUID();
    private static final UUID QUELQU_UN_DAUTRE = UUID.randomUUID();

    private static HelpChat conversationDe(UUID userId) {
        return HelpChat.create(userId, "Assistance", "Service client 24/7");
    }

    @Test
    @DisplayName("Ouvrir une conversation l'attache à celui qui la demande")
    void ouvrirAttacheALUtilisateur() {
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        HelpChat ouverte = ouvrir.execute(MOI, "Problème de connexion", "Compte");

        assertThat(ouverte.userId()).isEqualTo(MOI);
        assertThat(ouverte.title()).isEqualTo("Problème de connexion");
        assertThat(ouverte.subtitle()).isEqualTo("Compte");
        assertThat(ouverte.lastMessageAt()).as("aucun message n'a encore été échangé").isNull();
    }

    /**
     * Le bouton générique du menu n'a pas de contexte à transmettre. Sans valeurs de repli,
     * l'ouverture échouerait sur la validation du domaine, qui exige un titre non vide.
     */
    @Test
    @DisplayName("Sans titre fourni, des valeurs de repli s'appliquent")
    void titreFacultatif() {
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        HelpChat ouverte = ouvrir.execute(MOI, null, "   ");

        assertThat(ouverte.title()).isEqualTo("Assistance");
        assertThat(ouverte.subtitle()).isEqualTo("Service client 24/7");
    }

    @Test
    @DisplayName("Noter enregistre l'appréciation, le commentaire et la date")
    void noterEnregistreTout() {
        HelpChat mienne = conversationDe(MOI);
        when(chats.findByIdAndUserId(mienne.id(), MOI)).thenReturn(Optional.of(mienne));
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        HelpChat notee = noter.execute(MOI, mienne.id(), HelpChatRating.GREAT, "  J'apprécie votre service  ");

        assertThat(notee.rating()).isEqualTo(HelpChatRating.GREAT);
        assertThat(notee.ratingComment()).isEqualTo("J'apprécie votre service");
        assertThat(notee.ratedAt()).isNotNull();
    }

    /**
     * Le formulaire de commentaire s'ouvre <i>après</i> la note et peut être fermé sans
     * rien écrire. Un commentaire vide ne doit pas être stocké comme une chaîne vide :
     * la colonne resterait pleine de blancs, indistinguables d'un vrai commentaire perdu.
     */
    @Test
    @DisplayName("Un commentaire absent ou vide est enregistré comme absent")
    void commentaireFacultatif() {
        HelpChat mienne = conversationDe(MOI);
        when(chats.findByIdAndUserId(mienne.id(), MOI)).thenReturn(Optional.of(mienne));
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        assertThat(noter.execute(MOI, mienne.id(), HelpChatRating.OK, null).ratingComment()).isNull();
        assertThat(noter.execute(MOI, mienne.id(), HelpChatRating.OK, "   ").ratingComment()).isNull();
    }

    @Test
    @DisplayName("Noter à nouveau remplace la note précédente")
    void noterDeuxFoisRemplace() {
        HelpChat mienne = conversationDe(MOI);
        when(chats.findByIdAndUserId(mienne.id(), MOI)).thenReturn(Optional.of(mienne));
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        noter.execute(MOI, mienne.id(), HelpChatRating.POOR, "trop lent");
        HelpChat finale = noter.execute(MOI, mienne.id(), HelpChatRating.GREAT, null);

        assertThat(finale.rating()).isEqualTo(HelpChatRating.GREAT);
        assertThat(finale.ratingComment())
            .as("le commentaire de la note remplacée ne doit pas survivre à celle-ci")
            .isNull();
    }

    /**
     * <b>Le test qui compte.</b> Connaître un identifiant de conversation ne doit pas
     * suffire à noter — ni à commenter — l'échange de quelqu'un d'autre. La recherche
     * passe par {@code findByIdAndUserId} : le filtre est dans la requête, pas dans une
     * vérification que l'on pourrait oublier après coup.
     */
    @Test
    @DisplayName("On ne peut pas noter la conversation d'un autre")
    void impossibleDeNoterLaConversationDunAutre() {
        HelpChat laSienne = conversationDe(QUELQU_UN_DAUTRE);
        when(chats.findByIdAndUserId(laSienne.id(), MOI)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> noter.execute(MOI, laSienne.id(), HelpChatRating.POOR, "sabotage"))
            .isInstanceOf(NotFoundException.class);

        verify(chats, never()).save(any());
        assertThat(laSienne.rating()).as("la conversation visée reste intacte").isNull();
    }

    @Test
    @DisplayName("La note est bien persistée, pas seulement portée par l'objet renvoyé")
    void laNoteEstPersistee() {
        HelpChat mienne = conversationDe(MOI);
        when(chats.findByIdAndUserId(mienne.id(), MOI)).thenReturn(Optional.of(mienne));
        when(chats.save(any())).thenAnswer(i -> i.getArgument(0));

        noter.execute(MOI, mienne.id(), HelpChatRating.OK, "correct");

        ArgumentCaptor<HelpChat> sauvegardee = ArgumentCaptor.forClass(HelpChat.class);
        verify(chats).save(sauvegardee.capture());
        assertThat(sauvegardee.getValue().rating()).isEqualTo(HelpChatRating.OK);
        assertThat(sauvegardee.getValue().ratingComment()).isEqualTo("correct");
    }

    @Test
    @DisplayName("Une conversation inexistante ne se note pas")
    void conversationInexistante() {
        UUID inconnue = UUID.randomUUID();
        when(chats.findByIdAndUserId(eq(inconnue), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> noter.execute(MOI, inconnue, HelpChatRating.GREAT, null))
            .isInstanceOf(NotFoundException.class);
    }
}
