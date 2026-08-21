package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.engagement.domain.repository.HelpArticleChunkRepository;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La recherche documentaire, éprouvée sur le <b>vrai corpus</b> et sans clé d'API.
 *
 * <p>Aucun service d'empreintes n'est branché ici : la recherche bascule donc sur les
 * mots. C'est délibéré, et c'est le cas qui compte le plus — il correspond à une
 * installation sans clé configurée, et c'est celui où le centre d'aide doit malgré tout
 * répondre.
 */
class HelpArticleSearchTest {

    /** Dépôt d'articles en mémoire, alimenté par le corpus réel du projet. */
    private static class DepotArticles implements HelpArticleRepository {
        final Map<UUID, HelpArticle> contenu = new LinkedHashMap<>();
        @Override public HelpArticle save(HelpArticle a) { contenu.put(a.id(), a); return a; }
        @Override public Optional<HelpArticle> findBySlugAndLocale(String s, String l) {
            return contenu.values().stream()
                .filter(a -> a.slug().equals(s) && a.locale().equals(l)).findFirst();
        }
        @Override public List<HelpArticle> findByLocale(String l) {
            return contenu.values().stream().filter(a -> a.locale().equals(l)).toList();
        }
        @Override public List<HelpArticle> findAll() { return List.copyOf(contenu.values()); }
        @Override public void deleteBySlugAndLocale(String s, String l) {
            findBySlugAndLocale(s, l).ifPresent(a -> contenu.remove(a.id()));
        }
    }

    /**
     * Dépôt de fragments, séparé du précédent : les deux interfaces déclarent {@code
     * findAll()} avec des types de retour différents, et une seule classe ne peut donc pas
     * porter les deux.
     */
    private static class DepotFragments implements HelpArticleChunkRepository {
        final List<HelpArticleChunk> contenu = new ArrayList<>();
        @Override public HelpArticleChunk save(HelpArticleChunk c) { contenu.add(c); return c; }
        @Override public List<HelpArticleChunk> findByArticleId(UUID id) {
            return contenu.stream().filter(c -> c.articleId().equals(id)).toList();
        }
        @Override public List<HelpArticleChunk> findAll() { return List.copyOf(contenu); }
        @Override public void deleteByArticleId(UUID id) {
            contenu.removeIf(c -> c.articleId().equals(id));
        }
    }

    private static final DepotArticles ARTICLES = new DepotArticles();
    private static final DepotFragments FRAGMENTS = new DepotFragments();
    private static final HelpArticleSearch RECHERCHE;

    static {
        new HelpArticleFileReader().lireTout().forEach(ARTICLES::save);
        // Pas de service d'empreintes : « texte -> null », comme une installation sans clé.
        new HelpArticleIndexer(ARTICLES, FRAGMENTS, new HelpArticleChunker(), texte -> null)
            .indexer();
        RECHERCHE = new HelpArticleSearch(ARTICLES, FRAGMENTS, texte -> null);
    }

    private List<HelpArticleSearch.Resultat> chercher(String question, HelpArticle.Audience public_) {
        return RECHERCHE.classer(question, public_, "fr", 3);
    }

    private List<String> slugs(String question, HelpArticle.Audience public_) {
        return chercher(question, public_).stream().map(r -> r.article().slug()).toList();
    }

    @Test
    @DisplayName("Le corpus produit bien des fragments")
    void leCorpusEstIndexe() {
        assertThat(FRAGMENTS.contenu).isNotEmpty();
        assertThat(FRAGMENTS.contenu).allSatisfy(f ->
            assertThat(f.text()).isNotBlank());
    }

    @Test
    @DisplayName("Une question sur un score vide trouve le bon article")
    void questionFitScoreVide() {
        assertThat(slugs("Pourquoi mon offre n'affiche aucun Fit Score ?",
            HelpArticle.Audience.CANDIDATE)).contains("fit-score-vide");
    }

    @Test
    @DisplayName("Une question sur les mini-jeux trouve la bonne famille d'articles")
    void questionJeux() {
        assertThat(slugs("À quoi servent les mini-jeux psychométriques ?",
            HelpArticle.Audience.CANDIDATE).getFirst()).startsWith("jeux-");
    }

    @Test
    @DisplayName("Une question de recruteur sur le métier obligatoire trouve son article")
    void questionRecruteur() {
        assertThat(slugs("Pourquoi dois-je choisir un métier pour publier mon offre ?",
            HelpArticle.Audience.RECRUITER)).contains("recruteur-metier-obligatoire");
    }

    /**
     * <b>Le test qui compte le plus.</b> Une recherche rend toujours un meilleur résultat,
     * même quand la question n'a aucun rapport avec le corpus. Sans seuil, l'agent citerait
     * le moins mauvais fragment et répondrait à côté avec assurance — le mode d'échec qu'un
     * utilisateur ne peut pas détecter.
     */
    @Test
    @DisplayName("Une question hors sujet ne ramène rien")
    void questionHorsSujet() {
        assertThat(chercher("Quelle est la recette de la tarte aux pommes ?",
            HelpArticle.Audience.CANDIDATE)).isEmpty();
        assertThat(chercher("Quel temps fera-t-il demain à Tunis ?",
            HelpArticle.Audience.BOTH)).isEmpty();
    }

    /**
     * Un article destiné aux recruteurs ne doit jamais remonter pour un candidat, même
     * s'il répond parfaitement à sa question. Le filtre est appliqué avant le classement,
     * pas après : sinon un article interdit occuperait une place dans les résultats.
     */
    @Test
    @DisplayName("Un article de recruteur ne remonte jamais pour un candidat")
    void cloisonnementDesPublics() {
        List<String> pourCandidat = slugs("Comment créer une offre d'emploi ?",
            HelpArticle.Audience.CANDIDATE);

        assertThat(pourCandidat).doesNotContain("recruteur-creer-offre",
            "recruteur-metier-obligatoire", "recruteur-niveau");
    }

    @Test
    @DisplayName("Les résultats sont classés du plus pertinent au moins")
    void classementDecroissant() {
        List<HelpArticleSearch.Resultat> resultats =
            chercher("mot de passe oublié connexion", HelpArticle.Audience.BOTH);

        assertThat(resultats).isNotEmpty();
        for (int i = 1; i < resultats.size(); i++) {
            assertThat(resultats.get(i).score())
                .isLessThanOrEqualTo(resultats.get(i - 1).score());
        }
    }

    @Test
    @DisplayName("Sans service d'empreintes, la recherche passe par les mots")
    void basculeSurLesMots() {
        assertThat(chercher("mot de passe oublié", HelpArticle.Audience.BOTH))
            .isNotEmpty()
            .allSatisfy(r -> assertThat(r.semantique()).isFalse());
    }

    @Test
    @DisplayName("Une question vide ne provoque aucune recherche")
    void questionVide() {
        assertThat(chercher("", HelpArticle.Audience.BOTH)).isEmpty();
        assertThat(chercher("   ", HelpArticle.Audience.BOTH)).isEmpty();
    }

    /**
     * Le chemin sémantique, isolé : une empreinte constante fait que <b>tout</b> se
     * ressemble parfaitement. Seul le garde-fou lexical peut alors écarter un fragment —
     * c'est donc lui, et lui seul, que ce test éprouve.
     */
    @Test
    @DisplayName("Même avec une similarité parfaite, une question hors sujet est écartée")
    void gardeFouLexicalSurLeCheminSemantique() {
        float[] constante = new float[] {1f, 0f, 0f};
        var indexes = new DepotFragments();
        new HelpArticleIndexer(ARTICLES, indexes, new HelpArticleChunker(), t -> constante)
            .indexer();
        var rechercheSemantique = new HelpArticleSearch(ARTICLES, indexes, t -> constante);

        assertThat(rechercheSemantique.classer("Quelle est la recette de la tarte aux pommes ?",
            HelpArticle.Audience.CANDIDATE, "fr", 3))
            .as("aucun mot commun avec le corpus, malgré une similarité de 1,0")
            .isEmpty();

        assertThat(rechercheSemantique.classer("Pourquoi mon Fit Score est vide ?",
            HelpArticle.Audience.CANDIDATE, "fr", 3))
            .as("les mots sont partagés : la question doit passer")
            .isNotEmpty();
    }

    @Test
    @DisplayName("Chaque fragment porte le titre de son article")
    void fragmentsContextualises() {
        HelpArticle article = ARTICLES.findAll().getFirst();
        assertThat(FRAGMENTS.findByArticleId(article.id()))
            .allSatisfy(f -> assertThat(f.text()).startsWith(article.title()));
    }
}
