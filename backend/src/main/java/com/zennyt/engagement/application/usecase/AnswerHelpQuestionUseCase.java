package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.HelpAnswerPort;
import com.zennyt.engagement.application.port.HelpDocumentationPort;
import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Fait répondre l'assistant à une question posée dans une conversation d'aide.
 *
 * <p><b>L'enchaînement porte toute la prudence du dispositif :</b>
 * <ol>
 *   <li>chercher dans la documentation ;</li>
 *   <li><b>si rien ne dépasse le seuil, dire qu'on ne sait pas</b> — et ne surtout pas
 *       appeler le service de rédaction, qui produirait un texte plausible à partir de
 *       rien ;</li>
 *   <li>sinon, faire reformuler les extraits, et citer l'article d'où ils viennent.</li>
 * </ol>
 *
 * <p>La citation n'est pas décorative : elle permet à l'utilisateur de vérifier, et à
 * l'équipe de retrouver quel article a produit une réponse contestée.
 */
@Service
@RequiredArgsConstructor
public class AnswerHelpQuestionUseCase {

    private static final Logger log = LoggerFactory.getLogger(AnswerHelpQuestionUseCase.class);

    /** Au-delà, les extraits se répètent et diluent la réponse plus qu'ils ne l'enrichissent. */
    private static final int EXTRAITS_MAXIMUM = 3;

    static final String AVEU_IGNORANCE = """
        Je ne trouve pas de réponse à cette question dans la documentation de la plateforme.

        Reformulez-la si vous le souhaitez, ou demandez à parler à une personne de l'équipe : \
        je transmettrai votre message.""";

    private final HelpChatRepository chats;
    private final HelpMessageRepository messages;
    private final HelpDocumentationPort documentation;
    private final HelpAnswerPort redacteur;

    @Transactional
    public HelpChat.HelpMessage repondre(UUID chatId, String question,
                                         HelpArticle.Audience audience, String locale) {
        HelpChat chat = chats.findById(chatId).orElse(null);
        if (chat == null) return null;

        List<HelpDocumentationPort.Extrait> trouves =
            documentation.chercher(question, audience, locale, EXTRAITS_MAXIMUM);

        String texte;
        if (trouves.isEmpty()) {
            texte = AVEU_IGNORANCE;
            log.info("[Aide] Question hors corpus — aveu d'ignorance servi");
        } else {
            texte = rediger(question, trouves, audience);
        }

        HelpChat.HelpMessage reponse = chat.recordMessage(texte, false);
        chats.save(chat);
        return messages.save(reponse);
    }

    private String rediger(String question, List<HelpDocumentationPort.Extrait> trouves,
                           HelpArticle.Audience audience) {
        List<String> extraits = trouves.stream().map(HelpDocumentationPort.Extrait::texte).toList();
        String redige = redacteur.redigerReponse(question, extraits,
            audience == HelpArticle.Audience.CANDIDATE);

        // Sans service de rédaction — ou s'il a échoué — l'extrait est servi tel quel.
        // Moins fluide qu'une reformulation, mais exact, et toujours préférable au silence.
        String corps = redige != null ? redige : extraits.getFirst();

        log.info("[Aide] Réponse produite depuis « {} » (score {}, {})",
            trouves.getFirst().slugArticle(),
            String.format("%.2f", trouves.getFirst().score()),
            trouves.getFirst().semantique() ? "sens" : "mots");

        return corps + "\n\nSource : " + trouves.getFirst().titreArticle();
    }
}
