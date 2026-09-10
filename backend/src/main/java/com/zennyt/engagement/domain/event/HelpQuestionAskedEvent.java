package com.zennyt.engagement.domain.event;

import java.util.UUID;

/**
 * Un utilisateur vient de poser une question au centre d'aide.
 *
 * <p>Emis apres validation en base, pour que la generation de la reponse ne fasse pas
 * attendre l'envoi du message : l'utilisateur voit sa question apparaitre immediatement,
 * la reponse arrive ensuite.
 */
public record HelpQuestionAskedEvent(UUID helpChatId, UUID askedBy, String question) {}
