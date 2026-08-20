package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La base suit-elle vraiment les fichiers ?
 *
 * <p>Un dépôt en mémoire plutôt qu'un mock : le comportement à vérifier est un
 * <i>enchaînement</i> — lire, comparer, écrire, supprimer — et le décrire en attentes de
 * mock reviendrait à réécrire l'algorithme dans le test.
 */
class HelpArticleSynchronizerTest {

    /** Dépôt en mémoire, indexé comme le vrai : par (slug, langue). */
    private static class DepotEnMemoire implements HelpArticleRepository {
        final Map<String, HelpArticle> contenu = new LinkedHashMap<>();
        int ecritures = 0;

        @Override public HelpArticle save(HelpArticle article) {
            ecritures++;
            contenu.put(article.locale() + '/' + article.slug(), article);
            return article;
        }
        @Override public Optional<HelpArticle> findBySlugAndLocale(String slug, String locale) {
            return Optional.ofNullable(contenu.get(locale + '/' + slug));
        }
        @Override public List<HelpArticle> findByLocale(String locale) {
            return contenu.values().stream().filter(a -> a.locale().equals(locale)).toList();
        }
        @Override public List<HelpArticle> findAll() {
            return new ArrayList<>(contenu.values());
        }
        @Override public void deleteBySlugAndLocale(String slug, String locale) {
            contenu.remove(locale + '/' + slug);
        }
    }

    /** Lecteur qui rend ce qu'on lui donne, à la place des fichiers de ressources. */
    private static class LecteurFige extends HelpArticleFileReader {
        List<HelpArticle> articles = List.of();
        @Override public List<HelpArticle> lireTout() { return articles; }
    }

    private static HelpArticle article(String slug, String titre, String corps) {
        return new HelpArticle(UUID.randomUUID(), slug, "fr", HelpArticle.Audience.BOTH,
            "Test", titre, corps, HelpArticleFileReader.empreinte(titre + '\n' + corps),
            Instant.now());
    }

    private final DepotEnMemoire depot = new DepotEnMemoire();
    private final LecteurFige lecteur = new LecteurFige();
    private final HelpArticleSynchronizer synchroniseur =
        new HelpArticleSynchronizer(lecteur, depot);

    @Test
    @DisplayName("Un article nouveau est inséré")
    void insertion() {
        lecteur.articles = List.of(article("premier", "Premier", "Un texte."));

        synchroniseur.synchroniser();

        assertThat(depot.contenu).containsOnlyKeys("fr/premier");
    }

    @Test
    @DisplayName("Un texte modifié est mis à jour")
    void miseAJour() {
        lecteur.articles = List.of(article("evolutif", "Titre", "Version initiale."));
        synchroniseur.synchroniser();

        lecteur.articles = List.of(article("evolutif", "Titre", "Version corrigée."));
        synchroniseur.synchroniser();

        assertThat(depot.contenu.get("fr/evolutif").body()).isEqualTo("Version corrigée.");
    }

    /**
     * Réécrire un article identique déclenchera, à l'étape suivante, le recalcul d'une
     * empreinte numérique — donc un appel réseau. Trente-cinq articles inchangés
     * coûteraient trente-cinq appels à chaque redémarrage.
     */
    @Test
    @DisplayName("Un article inchangé n'est pas réécrit")
    void pasDEcritureInutile() {
        lecteur.articles = List.of(article("stable", "Titre", "Un texte qui ne bouge pas."));
        synchroniseur.synchroniser();
        int apresPremierPassage = depot.ecritures;

        synchroniseur.synchroniser();
        synchroniseur.synchroniser();

        assertThat(depot.ecritures).isEqualTo(apresPremierPassage);
    }

    /**
     * <b>Le cas le plus facile à oublier.</b> Un article retiré des fichiers — parce qu'il
     * était faux, ou décrivait une fonctionnalité disparue — doit disparaître de la base.
     * Sans cela, l'agent continuerait de le servir, et personne ne comprendrait d'où sort
     * cette réponse.
     */
    @Test
    @DisplayName("Un article retiré des fichiers disparaît de la base")
    void suppression() {
        lecteur.articles = List.of(
            article("garde", "Gardé", "Cet article reste."),
            article("retire", "Retiré", "Cet article sera supprimé."));
        synchroniseur.synchroniser();
        assertThat(depot.contenu).hasSize(2);

        lecteur.articles = List.of(article("garde", "Gardé", "Cet article reste."));
        synchroniseur.synchroniser();

        assertThat(depot.contenu).containsOnlyKeys("fr/garde");
    }

    @Test
    @DisplayName("Les articles d'une autre langue ne sont pas emportés")
    void languesIndependantes() {
        HelpArticle anglais = new HelpArticle(UUID.randomUUID(), "same-slug", "en",
            HelpArticle.Audience.BOTH, "Test", "Title", "Body in English",
            HelpArticleFileReader.empreinte("x"), Instant.now());
        depot.save(anglais);

        lecteur.articles = List.of(article("same-slug", "Titre", "Corps en français."),
            anglais);
        synchroniseur.synchroniser();

        assertThat(depot.contenu).containsOnlyKeys("en/same-slug", "fr/same-slug");
    }
}
