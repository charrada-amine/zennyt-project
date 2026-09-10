package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.application.port.HelpDocumentationPort;
import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.engagement.domain.repository.HelpArticleChunkRepository;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import com.zennyt.shared.application.port.EmbeddingPort;
import com.zennyt.shared.application.EmbeddingCodec;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Retrouve les fragments de documentation qui répondent à une question.
 *
 * <p><b>Deux voies, et la seconde n'est pas un pis-aller.</b> Si le service d'empreintes
 * est configuré, la recherche compare le sens ; sinon elle compare les mots, en pondérant
 * chaque terme par sa rareté dans le corpus. Sur soixante-dix articles d'un même domaine,
 * cette seconde voie est loin d'être ridicule — et elle a trois qualités que la première
 * n'a pas : gratuite, instantanée, et reproductible.
 *
 * <p>Le centre d'aide fonctionne donc sans clé d'API. Il fonctionne mieux avec, parce que
 * les empreintes rattrapent les questions posées avec d'autres mots que ceux du corpus —
 * « je ne vois plus mes candidats » face à un article intitulé « liste des candidats ».
 *
 * <p><b>Le seuil compte autant que le classement.</b> Une recherche rend toujours un
 * meilleur résultat, même quand la question n'a aucun rapport avec le corpus. Sans seuil,
 * l'agent citerait le moins mauvais fragment et répondrait à côté avec assurance. En
 * dessous, on ne rend rien — et l'agent dit qu'il ne sait pas.
 */
@Component
@RequiredArgsConstructor
public class HelpArticleSearch implements HelpDocumentationPort {

    /**
     * Proximité sémantique minimale.
     *
     * <p>Relevé le 21 août 2026 sur le modèle réellement utilisé : une vraie correspondance
     * obtient 0,92, et le <i>meilleur</i> résultat d'une question sans aucun rapport avec le
     * corpus obtient encore 0,80. L'écart est de six centièmes. Les préfixes « query: » et
     * « passage: » recommandés pour ce modèle ne l'élargissent pas.
     *
     * <p>Un seuil seul ne peut donc pas trancher : c'est pourquoi il est doublé d'une
     * exigence lexicale, voir {@link #COUVERTURE_MINIMALE_SEMANTIQUE}.
     */
    private static final double SEUIL_SEMANTIQUE = 0.85;

    /** Score lexical minimal, une fois les mots absents du corpus comptés au dénominateur. */
    private static final double SEUIL_LEXICAL = 0.30;

    /**
     * Part minimale des mots de la question qui doit se retrouver dans le fragment.
     *
     * <p>Ce garde-fou double le seuil de score, et il traite un cas que celui-ci laissait
     * passer : une question dont un seul mot est connu du corpus. « Quelle est la recette
     * de la tarte aux pommes ? » ne partage rien avec la documentation — mais si un unique
     * mot commun suffisait, le fragment qui le contient obtiendrait un score parfait.
     */
    private static final double COUVERTURE_MINIMALE = 0.4;

    /**
     * Exigence lexicale appliquée <b>aussi</b> aux résultats sémantiques.
     *
     * <p>C'est le garde-fou qui manquait. Les empreintes classent bien mais séparent mal :
     * « Quelle est la recette de la tarte aux pommes ? » obtenait 0,91 face à l'article sur
     * le mot de passe oublié, et l'assistant répondait donc à côté avec assurance.
     *
     * <p>Le partage d'un quart des mots de la question suffit ici — moins exigeant que pour
     * la recherche purement lexicale, puisque le sens apporte une preuve supplémentaire.
     * Une reformulation garde ainsi ses chances (« je ne vois plus mes candidats » partage
     * « candidats »), tandis qu'une question étrangère au produit ne partage rien.
     */
    private static final double COUVERTURE_MINIMALE_SEMANTIQUE = 0.25;

    /**
     * Mots trop courants pour distinguer quoi que ce soit. Les garder ferait remonter
     * l'article qui contient le plus de « pour » et de « avec ».
     */
    private static final Set<String> MOTS_VIDES = Set.of(
        "a", "ai", "and", "as", "au", "aux", "avec", "avoir", "ca", "car", "ce", "ceci",
        "cela", "ces", "cet", "cette", "combien", "comme", "comment", "dans", "de", "des",
        "donc", "dont", "du", "elle", "elles", "en", "est", "et", "ete", "etre", "faire",
        "fait", "il", "ils", "je", "la", "laquelle", "le", "lequel", "les", "ma", "mais",
        "me", "mes", "moi", "mon", "ne", "nous", "of", "on", "ont", "ou", "par", "pas",
        "peut", "plus", "pour", "pourquoi", "puis", "quand", "que", "quel", "quelle",
        "quelles", "quels", "qui", "quoi", "sa", "sans", "se", "ses", "si", "son", "sont",
        "sur", "ta", "tes", "the", "to", "ton", "tous", "tout", "toute", "toutes", "tu",
        "un", "une", "vous", "y");    private final HelpArticleRepository articles;
    private final HelpArticleChunkRepository chunks;
    private final EmbeddingPort empreintes;

    /**
     * @param audience public du lecteur — un article destiné aux recruteurs ne doit jamais
     *                 remonter pour un candidat, même s'il répond parfaitement à sa question
     * @return les meilleurs fragments, du plus pertinent au moins, ou une liste vide si
     *         aucun ne dépasse le seuil
     */
    @Override
    public List<Extrait> chercher(String question, HelpArticle.Audience audience,
                                  String locale, int maximum) {
        return classer(question, audience, locale, maximum).stream()
            .map(r -> new Extrait(r.article().slug(), r.article().title(),
                r.fragment().text(), r.score(), r.semantique()))
            .toList();
    }

    /** Variante interne, qui conserve les objets du domaine — utile aux tests de recherche. */
    public List<Resultat> classer(String question, HelpArticle.Audience audience,
                                  String locale, int maximum) {
        if (question == null || question.isBlank()) return List.of();

        Map<UUID, HelpArticle> parId = new HashMap<>();
        for (HelpArticle article : articles.findByLocale(locale)) {
            if (article.concerne(audience)) parId.put(article.id(), article);
        }
        if (parId.isEmpty()) return List.of();

        List<HelpArticleChunk> candidats = chunks.findAll().stream()
            .filter(c -> parId.containsKey(c.articleId()))
            .toList();
        if (candidats.isEmpty()) return List.of();

        float[] empreinteQuestion = empreintes.embed(question);
        List<Resultat> resultats = empreinteQuestion != null
            ? parSens(question, empreinteQuestion, candidats, parId)
            : List.of();

        // Aucun résultat sémantique — service absent, ou question dont aucun fragment
        // n'approche : on tente les mots avant d'abandonner.
        if (resultats.isEmpty()) {
            resultats = parMots(question, candidats, parId);
        }

        return resultats.stream()
            .sorted(Comparator.comparingDouble(Resultat::score).reversed())
            .limit(maximum)
            .toList();
    }

    private List<Resultat> parSens(String question, float[] empreinteQuestion,
                                   List<HelpArticleChunk> candidats,
                                   Map<UUID, HelpArticle> parId) {
        List<String> motsQuestion = motsUtiles(question).stream().distinct().toList();
        if (motsQuestion.isEmpty()) return List.of();

        List<Resultat> retenus = new ArrayList<>();
        for (HelpArticleChunk fragment : candidats) {
            if (!fragment.aUneEmpreinte()) continue;
            Double proximite = EmbeddingCodec.cosineSimilarity(empreinteQuestion, fragment.embedding());
            if (proximite == null || proximite < SEUIL_SEMANTIQUE) continue;

            // Le sens classe, les mots gardent la porte : sans ce second critère, une
            // question étrangère au produit obtient tout de même 0,91 sur le fragment le
            // moins éloigné, et l'assistant répond à côté.
            Set<String> motsFragment = new HashSet<>(motsUtiles(fragment.text()));
            double couverture = motsQuestion.stream().filter(motsFragment::contains).count()
                / (double) motsQuestion.size();
            if (couverture < COUVERTURE_MINIMALE_SEMANTIQUE) continue;

            retenus.add(new Resultat(parId.get(fragment.articleId()), fragment, proximite, true));
        }
        return retenus;
    }

    /**
     * Score lexical : chaque mot commun compte d'autant plus qu'il est rare dans le corpus.
     * « Fit Score » distingue ; « offre » beaucoup moins, puisque la moitié des articles en
     * parlent.
     */
    private List<Resultat> parMots(String question, List<HelpArticleChunk> candidats,
                                   Map<UUID, HelpArticle> parId) {
        List<String> motsQuestion = motsUtiles(question);
        if (motsQuestion.isEmpty()) return List.of();

        Map<String, Integer> presence = new HashMap<>();
        List<Set<String>> motsDesFragments = new ArrayList<>(candidats.size());
        for (HelpArticleChunk fragment : candidats) {
            Set<String> mots = new HashSet<>(motsUtiles(fragment.text()));
            motsDesFragments.add(mots);
            for (String mot : mots) presence.merge(mot, 1, Integer::sum);
        }

        double total = candidats.size();
        List<String> distincts = motsQuestion.stream().distinct().toList();

        // Un mot absent du corpus pèse au dénominateur comme le mot le plus rare possible.
        // Sans cela, une question dont un seul mot est connu obtiendrait un score parfait :
        // le dénominateur ne compterait que ce mot-là.
        double poidsTotal = distincts.stream()
            .mapToDouble(mot -> presence.containsKey(mot) ? rarete(presence.get(mot), total)
                                                          : rarete(1, total))
            .sum();
        if (poidsTotal <= 0) return List.of();

        List<Resultat> retenus = new ArrayList<>();
        for (int i = 0; i < candidats.size(); i++) {
            Set<String> mots = motsDesFragments.get(i);
            List<String> trouves = distincts.stream().filter(mots::contains).toList();

            double couverture = trouves.size() / (double) distincts.size();
            if (couverture < COUVERTURE_MINIMALE) continue;

            double score = trouves.stream()
                .mapToDouble(mot -> rarete(presence.get(mot), total))
                .sum() / poidsTotal;

            if (score >= SEUIL_LEXICAL) {
                HelpArticleChunk fragment = candidats.get(i);
                retenus.add(new Resultat(parId.get(fragment.articleId()), fragment, score, false));
            }
        }
        return retenus;
    }

    /** Un mot présent partout ne vaut presque rien ; un mot rare vaut cher. */
    private static double rarete(int fragmentsContenantLeMot, double total) {
        if (fragmentsContenantLeMot <= 0) return 0;
        return Math.log(1 + total / fragmentsContenantLeMot);
    }

    /** Minuscules, accents retirés, ponctuation écartée, mots vides et mots d'une lettre ôtés. */
    static List<String> motsUtiles(String texte) {
        String normalise = Normalizer.normalize(texte.toLowerCase(java.util.Locale.FRENCH),
                Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .replaceAll("[^a-z0-9]+", " ");
        return Arrays.stream(normalise.split(" "))
            .filter(mot -> mot.length() > 2)
            .filter(mot -> !MOTS_VIDES.contains(mot))
            .toList();
    }

    /**
     * @param semantique {@code true} si le résultat vient de la comparaison de sens,
     *                   {@code false} s'il vient des mots — utile pour comprendre, en
     *                   journal, pourquoi telle réponse a été donnée
     */
    public record Resultat(HelpArticle article, HelpArticleChunk fragment,
                           double score, boolean semantique) {}
}
