package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Locale;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le corpus documentaire se relit-il, et dit-il quelque chose d'utilisable ?
 *
 * <p>Ces vérifications portent sur du <b>texte</b>, ce qui est inhabituel — mais le corpus
 * est la matière première de l'agent : un article illisible, dupliqué ou vide se traduira
 * par une réponse fausse ou par un aveu d'ignorance inexpliqué. Autant l'apprendre ici
 * qu'en production.
 */
class HelpArticleCorpusTest {

    private static final List<HelpArticle> CORPUS = new HelpArticleFileReader().lireTout();

    @Test
    @DisplayName("Le corpus se lit sans erreur et n'est pas vide")
    void leCorpusSeLit() {
        assertThat(CORPUS)
            .as("aucun article lu : le chemin des ressources a probablement changé")
            .isNotEmpty();
    }

    @Test
    @DisplayName("Chaque slug est unique pour une langue donnée")
    void slugsUniques() {
        assertThat(CORPUS.stream().map(a -> a.locale() + '/' + a.slug()).toList())
            .doesNotHaveDuplicates();
    }

    /**
     * Un slug est une clé stable, citée dans les réponses de l'agent et destinée à devenir
     * une adresse. Les accents et les majuscules y sont des pièges silencieux.
     */
    @Test
    @DisplayName("Les slugs sont en minuscules, sans accent ni espace")
    void slugsBienFormes() {
        assertThat(CORPUS)
            .allSatisfy(article -> assertThat(article.slug())
                .as("slug « %s »", article.slug())
                .matches("[a-z0-9-]+"));
    }

    @Test
    @DisplayName("Les trois publics sont représentés")
    void lesTroisPublicsSontCouverts() {
        assertThat(CORPUS.stream().map(HelpArticle::audience).distinct())
            .containsExactlyInAnyOrder(HelpArticle.Audience.CANDIDATE,
                HelpArticle.Audience.RECRUITER, HelpArticle.Audience.BOTH);
    }

    /**
     * Un article de deux lignes ne répond à rien : découpé en fragments, il produira un
     * fragment trop court pour être retrouvé, ou trop vague pour être cité.
     */
    @Test
    @DisplayName("Aucun article n'est trop court pour être utile")
    void articlesSuffisammentEtoffes() {
        assertThat(CORPUS)
            .allSatisfy(article -> assertThat(article.body().split("\\s+").length)
                .as("article « %s »", article.slug())
                .isGreaterThanOrEqualTo(30));
    }

    /**
     * <b>Le test qui compte.</b> Le corpus ne doit rien emprunter aux documents internes du
     * dépôt — audits de défauts, noms de classes, décisions non annoncées. Un utilisateur
     * qui demande « c'est quoi le Fit Score ? » ne doit pas s'entendre répondre qu'une
     * pondération n'est pas calibrée ou qu'un calcul a été faux pendant deux jours.
     */
    @Test
    @DisplayName("Aucune fuite de vocabulaire interne dans le corpus")
    void pasDeVocabulaireInterne() {
        List<String> interdits = List.of(
            "flyway", "migration", "postgres", "endpoint", "backend", "commit",
            "openapi", "groq", "cloudinary", "usecase", "repository", "null",
            "bug", "calibr", "todo", "fixme", "sprint", "jira");

        for (HelpArticle article : CORPUS) {
            String texte = (article.title() + ' ' + article.body()).toLowerCase(Locale.FRENCH);
            for (String mot : interdits) {
                assertThat(texte)
                    .as("l'article « %s » emploie le terme interne « %s »", article.slug(), mot)
                    .doesNotContain(mot);
            }
        }
    }

    /**
     * Le corpus décrit le produit à des utilisateurs : il ne doit pas leur promettre des
     * fonctionnalités qui n'existent pas. Le « Wallet » de la maquette d'origine en est
     * l'exemple — aucune trace de portefeuille dans la plateforme.
     *
     * <p><b>« Paiement » et « abonnement » figuraient ici par erreur.</b> La liste avait été
     * écrite en supposant qu'aucun règlement n'existait ; le paiement de la visioconférence
     * existe bel et bien. Une liste d'interdits trop large est un piège : elle empêche de
     * documenter une fonctionnalité réelle, et l'utilisateur reste sans réponse.
     */
    @Test
    @DisplayName("Le corpus ne parle pas de fonctionnalités inexistantes")
    void pasDeFonctionnaliteImaginaire() {
        List<String> inexistantes = List.of("wallet", "portefeuille");

        for (HelpArticle article : CORPUS) {
            String texte = (article.title() + ' ' + article.body()).toLowerCase(Locale.FRENCH);
            for (String mot : inexistantes) {
                assertThat(texte)
                    .as("l'article « %s » évoque « %s », qui n'existe pas dans la plateforme",
                        article.slug(), mot)
                    .doesNotContain(mot);
            }
        }
    }

    @Test
    @DisplayName("Deux articles au texte différent ont deux empreintes différentes")
    void empreintesDistinctes() {
        assertThat(CORPUS.stream().map(HelpArticle::contentHash).distinct().count())
            .isEqualTo(CORPUS.size());
    }

    @Test
    @DisplayName("Un article ne concerne que son public, sauf s'il s'adresse aux deux")
    void filtrageParPublic() {
        HelpArticle pourCandidat = CORPUS.stream()
            .filter(a -> a.audience() == HelpArticle.Audience.CANDIDATE).findFirst().orElseThrow();
        HelpArticle pourTous = CORPUS.stream()
            .filter(a -> a.audience() == HelpArticle.Audience.BOTH).findFirst().orElseThrow();

        assertThat(pourCandidat.concerne(HelpArticle.Audience.CANDIDATE)).isTrue();
        assertThat(pourCandidat.concerne(HelpArticle.Audience.RECRUITER)).isFalse();
        assertThat(pourTous.concerne(HelpArticle.Audience.CANDIDATE)).isTrue();
        assertThat(pourTous.concerne(HelpArticle.Audience.RECRUITER)).isTrue();
    }
}
