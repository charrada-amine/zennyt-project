package com.zennyt.engagement.application.port;

import com.zennyt.engagement.domain.model.HelpArticle;

import java.util.List;

/**
 * Retrouve les passages de documentation qui repondent a une question.
 *
 * <p>Port plutot qu'appel direct : la maniere de chercher — empreintes semantiques, mots
 * ponderes, ou autre chose demain — est un detail d'infrastructure. Le cas d'usage, lui,
 * n'a besoin que d'une chose : des extraits, ou rien.
 *
 * <p>Une liste vide n'est pas un echec. Elle signifie que la question sort du corpus, et
 * c'est une reponse en soi : l'assistant dira qu'il ne sait pas.
 */
public interface HelpDocumentationPort {

    List<Extrait> chercher(String question, HelpArticle.Audience audience,
                           String locale, int maximum);

    /**
     * @param semantique {@code true} si l'extrait a ete trouve par proximite de sens,
     *                   {@code false} par les mots — journalise pour comprendre, apres coup,
     *                   pourquoi telle reponse a ete donnee
     */
    record Extrait(String slugArticle, String titreArticle, String texte,
                   double score, boolean semantique) {}
}
