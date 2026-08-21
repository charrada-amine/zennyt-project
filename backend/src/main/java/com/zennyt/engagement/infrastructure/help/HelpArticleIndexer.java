package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.engagement.domain.repository.HelpArticleChunkRepository;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import com.zennyt.shared.application.port.EmbeddingPort;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Découpe les articles et calcule leurs empreintes sémantiques.
 *
 * <p><b>Rien n'est recalculé sans raison.</b> Chaque fragment porte l'empreinte de son
 * propre texte ; si elle n'a pas changé, l'empreinte sémantique est conservée telle
 * quelle. Sans cette précaution, chaque redémarrage déclencherait un appel réseau par
 * fragment — plusieurs centaines d'appels pour un corpus rigoureusement identique.
 *
 * <p>Un article dont le texte a changé voit en revanche <b>tous</b> ses fragments
 * reconstruits : le découpage suit les paragraphes, donc ajouter une phrase peut déplacer
 * les frontières de tous les fragments suivants. Tenter de les apparier un à un coûterait
 * plus cher que de refaire.
 *
 * <p>Si le service d'empreintes n'est pas configuré, les fragments sont tout de même
 * créés, sans empreinte. La recherche bascule alors sur les mots — voir
 * {@link HelpArticleSearch}. Le centre d'aide fonctionne sans clé ; il fonctionne mieux
 * avec.
 */
@Component
@RequiredArgsConstructor
public class HelpArticleIndexer {

    private static final Logger log = LoggerFactory.getLogger(HelpArticleIndexer.class);

    private final HelpArticleRepository articles;
    private final HelpArticleChunkRepository chunks;
    private final HelpArticleChunker decoupeur;
    private final EmbeddingPort empreintes;

    @Transactional
    public Resultat indexer() {
        int fragmentsCrees = 0;
        int empreintesCalculees = 0;
        int empreintesConservees = 0;
        int articlesInchanges = 0;

        for (HelpArticle article : articles.findAll()) {
            List<HelpArticleChunk> existants = chunks.findByArticleId(article.id());
            List<String> textes = decoupeur.decouper(article);

            if (correspond(existants, textes)) {
                articlesInchanges++;
                empreintesConservees += (int) existants.stream()
                    .filter(HelpArticleChunk::aUneEmpreinte).count();
                // Rattrapage : un fragment sans empreinte est réessayé, au cas où le
                // service était indisponible au moment de sa création.
                for (HelpArticleChunk fragment : existants) {
                    if (!fragment.aUneEmpreinte()) {
                        float[] valeur = empreintes.embed(fragment.text());
                        if (valeur != null) {
                            chunks.save(fragment.avecEmpreinte(valeur));
                            empreintesCalculees++;
                        }
                    }
                }
                continue;
            }

            Map<String, float[]> reutilisables = new HashMap<>();
            for (HelpArticleChunk ancien : existants) {
                if (ancien.aUneEmpreinte()) reutilisables.put(ancien.sourceHash(), ancien.embedding());
            }
            chunks.deleteByArticleId(article.id());

            for (int position = 0; position < textes.size(); position++) {
                String texte = textes.get(position);
                String empreinteTexte = HelpArticleFileReader.empreinte(texte);

                float[] vecteur = reutilisables.get(empreinteTexte);
                if (vecteur != null) {
                    empreintesConservees++;
                } else {
                    vecteur = empreintes.embed(texte);
                    if (vecteur != null) empreintesCalculees++;
                }

                chunks.save(new HelpArticleChunk(UUID.randomUUID(), article.id(), position,
                    texte, vecteur, empreinteTexte));
                fragmentsCrees++;
            }
        }

        Resultat resultat = new Resultat(fragmentsCrees, empreintesCalculees,
            empreintesConservees, articlesInchanges);
        log.info("[Aide] Index documentaire : {} fragment(s) reconstruit(s), {} empreinte(s) "
            + "calculée(s), {} réutilisée(s), {} article(s) inchangé(s)",
            fragmentsCrees, empreintesCalculees, empreintesConservees, articlesInchanges);
        return resultat;
    }

    /**
     * Les fragments en base décrivent-ils exactement ce découpage ? La comparaison porte
     * sur les empreintes de texte, dans l'ordre : deux fragments identiques mais permutés
     * ne se valent pas, puisque leur position sert à les citer.
     */
    private boolean correspond(List<HelpArticleChunk> existants, List<String> textes) {
        if (existants.size() != textes.size()) return false;
        for (int i = 0; i < textes.size(); i++) {
            if (!existants.get(i).sourceHash().equals(HelpArticleFileReader.empreinte(textes.get(i)))) {
                return false;
            }
        }
        return true;
    }

    public record Resultat(int fragmentsCrees, int empreintesCalculees,
                           int empreintesConservees, int articlesInchanges) {}
}
