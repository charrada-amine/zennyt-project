package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Aligne la table des articles sur les fichiers de ressources, à chaque démarrage.
 *
 * <p>Les fichiers font foi : ils sont relus, comparés à ce qui est en base, et la base est
 * corrigée. Éditer directement la table n'a donc aucun effet durable — la modification
 * serait écrasée au prochain démarrage.
 *
 * <p><b>Trois cas, et le troisième compte autant que les autres :</b>
 * <ul>
 *   <li>article nouveau → inséré ;</li>
 *   <li>texte modifié (empreinte différente) → mis à jour ;</li>
 *   <li>article <b>retiré des fichiers</b> → supprimé de la base. Sans cette suppression,
 *       un article que l'on a volontairement retiré — parce qu'il était faux, ou qu'il
 *       décrivait une fonctionnalité disparue — continuerait d'être servi par l'agent.
 *       C'est le cas le plus dangereux, et le plus facile à oublier.</li>
 * </ul>
 *
 * <p>Un article inchangé n'est pas réécrit : à l'étape suivante, chaque écriture entraînera
 * le recalcul d'une empreinte numérique, donc un appel réseau. Réécrire trente-cinq articles
 * identiques à chaque redémarrage coûterait trente-cinq appels pour rien.
 */
@Component
@RequiredArgsConstructor
public class HelpArticleSynchronizer {

    private static final Logger log = LoggerFactory.getLogger(HelpArticleSynchronizer.class);

    private final HelpArticleFileReader lecteur;
    private final HelpArticleRepository articles;
    private final HelpArticleIndexer indexeur;

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void synchroniser() {
        List<HelpArticle> desFichiers = lecteur.lireTout();
        Set<String> clesDesFichiers = new HashSet<>();

        int ajoutes = 0;
        int misAJour = 0;
        int inchanges = 0;

        for (HelpArticle article : desFichiers) {
            clesDesFichiers.add(cle(article.slug(), article.locale()));
            var existant = articles.findBySlugAndLocale(article.slug(), article.locale());

            if (existant.isEmpty()) {
                articles.save(article);
                ajoutes++;
            } else if (!existant.get().contentHash().equals(article.contentHash())) {
                articles.save(article);
                misAJour++;
            } else {
                inchanges++;
            }
        }

        int supprimes = 0;
        for (HelpArticle enBase : articles.findAll()) {
            if (!clesDesFichiers.contains(cle(enBase.slug(), enBase.locale()))) {
                articles.deleteBySlugAndLocale(enBase.slug(), enBase.locale());
                supprimes++;
            }
        }

        log.info("[Aide] Corpus synchronisé : {} article(s) — {} ajouté(s), {} mis à jour, "
            + "{} inchangé(s), {} supprimé(s)",
            desFichiers.size(), ajoutes, misAJour, inchanges, supprimes);

        // Les fragments dérivent des articles : les réindexer ici garantit qu'ils ne
        // décrivent jamais une version périmée du corpus.
        indexeur.indexer();
    }

    private static String cle(String slug, String locale) {
        return locale + '/' + slug;
    }
}
