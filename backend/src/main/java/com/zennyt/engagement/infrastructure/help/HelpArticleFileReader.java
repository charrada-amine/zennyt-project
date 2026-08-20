package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Lit les articles d'aide depuis les fichiers de ressources.
 *
 * <p>Un fichier contient plusieurs articles séparés par un en-tête de métadonnées, sur le
 * modèle du « front matter » Markdown :
 *
 * <pre>
 * ---
 * slug: fit-score-c-est-quoi
 * audience: BOTH
 * category: Fit Score
 * title: Qu'est-ce que le Fit Score ?
 * ---
 * Le corps de l'article…
 * </pre>
 *
 * <p>Regrouper plusieurs articles par fichier est délibéré : un fichier par article
 * donnerait quarante fichiers de quinze lignes, et l'ensemble deviendrait illisible en
 * revue. Un fichier par thème garde les articles voisins côte à côte, là où on les
 * compare.
 *
 * <p>Le lecteur est <b>strict</b> : un en-tête incomplet ou un slug répété arrête le
 * démarrage. Une documentation à moitié chargée est pire qu'absente — l'agent répondrait
 * avec assurance sur la moitié qu'il connaît, et par un aveu d'ignorance sur l'autre, sans
 * que personne ne comprenne pourquoi.
 */
@Component
public class HelpArticleFileReader {

    private static final String MOTIF = "classpath*:help/*/*.md";
    private static final String SEPARATEUR = "---";

    public List<HelpArticle> lireTout() {
        List<HelpArticle> articles = new ArrayList<>();
        Map<String, String> vus = new LinkedHashMap<>();
        Instant maintenant = Instant.now();

        for (Resource fichier : ressources()) {
            String locale = localeDe(fichier);
            for (HelpArticle article : lireFichier(fichier, locale, maintenant)) {
                String cle = article.locale() + '/' + article.slug();
                String precedent = vus.put(cle, nomDe(fichier));
                if (precedent != null) {
                    throw new IllegalStateException("Slug d'aide en double : « " + article.slug()
                        + " » (" + article.locale() + ") apparaît dans " + precedent
                        + " et dans " + nomDe(fichier)
                        + ". Un slug identifie un article, il ne peut pas en désigner deux.");
                }
                articles.add(article);
            }
        }
        return articles;
    }

    private Resource[] ressources() {
        try {
            return new PathMatchingResourcePatternResolver().getResources(MOTIF);
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture des articles d'aide impossible", e);
        }
    }

    /** La langue vient du dossier : {@code help/fr/…} → {@code fr}. */
    private String localeDe(Resource fichier) {
        String chemin = fichier.toString().replace('\\', '/');
        int fin = chemin.lastIndexOf('/');
        int debut = chemin.lastIndexOf('/', fin - 1);
        return chemin.substring(debut + 1, fin);
    }

    private String nomDe(Resource fichier) {
        String nom = fichier.getFilename();
        return nom == null ? fichier.toString() : nom;
    }

    private List<HelpArticle> lireFichier(Resource fichier, String locale, Instant maintenant) {
        String contenu;
        try (var flux = fichier.getInputStream()) {
            contenu = new String(flux.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture de " + nomDe(fichier) + " impossible", e);
        }

        List<HelpArticle> articles = new ArrayList<>();
        // Chaque article commence par un séparateur ; le premier morceau est vide.
        String[] morceaux = contenu.replace("\r\n", "\n").split("(?m)^" + SEPARATEUR + "\\s*$\n");

        for (int i = 1; i < morceaux.length; i += 2) {
            if (i + 1 >= morceaux.length) {
                throw new IllegalStateException("En-tête sans corps dans " + nomDe(fichier)
                    + " : chaque article doit être suivi de son texte.");
            }
            Map<String, String> entete = entete(morceaux[i], fichier);
            String corps = morceaux[i + 1].trim();
            articles.add(construire(entete, corps, locale, fichier, maintenant));
        }
        return articles;
    }

    private Map<String, String> entete(String bloc, Resource fichier) {
        Map<String, String> valeurs = new LinkedHashMap<>();
        for (String ligne : bloc.split("\n")) {
            if (ligne.isBlank()) continue;
            int separateur = ligne.indexOf(':');
            if (separateur < 0) {
                throw new IllegalStateException("Ligne d'en-tête illisible dans "
                    + nomDe(fichier) + " : « " + ligne + " »");
            }
            valeurs.put(ligne.substring(0, separateur).trim(),
                ligne.substring(separateur + 1).trim());
        }
        return valeurs;
    }

    private HelpArticle construire(Map<String, String> entete, String corps, String locale,
                                   Resource fichier, Instant maintenant) {
        String slug = obligatoire(entete, "slug", fichier);
        String titre = obligatoire(entete, "title", fichier);
        String categorie = obligatoire(entete, "category", fichier);
        String public_ = obligatoire(entete, "audience", fichier);

        HelpArticle.Audience audience;
        try {
            audience = HelpArticle.Audience.valueOf(public_);
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("Public inconnu « " + public_ + " » pour l'article « "
                + slug + " » dans " + nomDe(fichier) + ". Valeurs acceptées : CANDIDATE, "
                + "RECRUITER, BOTH.");
        }

        return new HelpArticle(UUID.randomUUID(), slug, locale, audience, categorie, titre,
            corps, empreinte(titre + '\n' + corps), maintenant);
    }

    private String obligatoire(Map<String, String> entete, String cle, Resource fichier) {
        String valeur = entete.get(cle);
        if (valeur == null || valeur.isBlank()) {
            throw new IllegalStateException("Champ « " + cle + " » manquant dans un article de "
                + nomDe(fichier));
        }
        return valeur;
    }

    /**
     * Empreinte du titre et du corps. Le titre en fait partie : le corriger sans toucher au
     * texte doit suffire à déclencher un recalcul, puisque le titre sera indexé lui aussi.
     */
    static String empreinte(String texte) {
        try {
            byte[] condensat = MessageDigest.getInstance("SHA-256")
                .digest(texte.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(condensat);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponible", e);
        }
    }
}
