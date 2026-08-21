package com.zennyt.engagement.application.port;

import java.util.List;

/**
 * Rédige une réponse d'aide <b>à partir des seuls extraits fournis</b>.
 *
 * <p>Le contrat est plus étroit qu'il n'y paraît : l'implémentation reformule, elle
 * n'apporte rien. Si les extraits ne répondent pas à la question, elle doit le dire — pas
 * combler. C'est ce qui sépare un assistant documentaire d'un générateur de texte
 * plausible.
 *
 * <p>Port interchangeable, comme celui des empreintes : {@code null} signifie « aucun
 * service de rédaction disponible ». L'appelant sert alors l'extrait tel quel, ce qui est
 * moins fluide mais reste exact.
 */
public interface HelpAnswerPort {

    /**
     * @param question la question de l'utilisateur, telle qu'il l'a écrite
     * @param extraits les fragments de documentation retenus, du plus pertinent au moins
     * @param tutoyer  registre attendu — la plateforme s'adresse aux candidats et aux
     *                 recruteurs sur des tons différents
     * @return la réponse rédigée, ou {@code null} si le service n'est pas disponible
     */
    String redigerReponse(String question, List<String> extraits, boolean tutoyer);
}
