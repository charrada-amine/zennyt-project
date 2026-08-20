package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Ouvre une conversation d'aide.
 *
 * <p>Cette porte d'entrée manquait : le centre d'aide savait lister les conversations et y
 * répondre, mais aucun chemin ne permettait d'en créer une. La table était donc vide, et
 * l'écran affichait une liste vide sans aucun moyen de la remplir.
 *
 * <p>Le titre et le sous-titre viennent du client parce qu'ils dépendent de l'endroit d'où
 * l'utilisateur ouvre l'aide — « Problème de connexion » depuis l'écran de compte n'est pas
 * « Question sur mon Fit Score » depuis une offre. Des valeurs de repli existent pour le
 * cas le plus courant : le bouton générique du menu.
 */
@Service
@RequiredArgsConstructor
public class OpenHelpChatUseCase {

    static final String TITRE_PAR_DEFAUT = "Assistance";
    static final String SOUS_TITRE_PAR_DEFAUT = "Service client 24/7";

    private final HelpChatRepository chats;

    @Transactional
    public HelpChat execute(UUID actorId, String title, String subtitle) {
        return chats.save(HelpChat.create(actorId,
            valeurOuDefaut(title, TITRE_PAR_DEFAUT),
            valeurOuDefaut(subtitle, SOUS_TITRE_PAR_DEFAUT)));
    }

    private static String valeurOuDefaut(String valeur, String defaut) {
        return valeur == null || valeur.isBlank() ? defaut : valeur.trim();
    }
}
