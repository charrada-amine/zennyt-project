package com.zennyt.engagement.infrastructure.help;

import com.zennyt.engagement.domain.model.HelpArticle;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Découpe un article en fragments recherchables.
 *
 * <p>Le découpage suit les <b>paragraphes</b>, pas un nombre de caractères. Couper au
 * milieu d'une phrase produirait des fragments qui commencent par « ...donc il faut » :
 * retrouvables peut-être, citables non. Un paragraphe est déjà une unité de sens, écrite
 * comme telle.
 *
 * <p>Deux ajustements, chacun corrigeant un défaut opposé :
 * <ul>
 *   <li>les paragraphes trop courts sont <b>fusionnés</b> avec le suivant — une phrase
 *       isolée n'a pas assez de mots pour être retrouvée de façon fiable ;</li>
 *   <li>chaque fragment est <b>préfixé du titre</b> de l'article. Sans lui, le paragraphe
 *       « Quatre raisons possibles, dans l'ordre… » ne dit pas de quoi il parle, et ne
 *       ressort donc sur aucune question.</li>
 * </ul>
 */
@Component
public class HelpArticleChunker {

    /** En deçà, un fragment n'a pas de quoi être distingué de ses voisins. */
    private static final int MOTS_MINIMUM = 25;

    /** Au-delà, on cesse d'agréger : un fragment trop large redevient un article. */
    private static final int MOTS_MAXIMUM = 160;

    public List<String> decouper(HelpArticle article) {
        List<String> fragments = new ArrayList<>();
        StringBuilder courant = new StringBuilder();

        for (String paragraphe : article.body().split("\\n\\s*\\n")) {
            String propre = paragraphe.strip();
            if (propre.isEmpty()) continue;

            if (!courant.isEmpty()) courant.append("\n\n");
            courant.append(propre);

            if (compterMots(courant.toString()) >= MOTS_MINIMUM) {
                fragments.add(courant.toString());
                courant.setLength(0);
            }
        }

        // Un reste trop court rejoint le fragment précédent plutôt que de vivre seul.
        if (!courant.isEmpty()) {
            if (fragments.isEmpty()) {
                fragments.add(courant.toString());
            } else {
                int dernier = fragments.size() - 1;
                fragments.set(dernier, fragments.get(dernier) + "\n\n" + courant);
            }
        }

        return fragments.stream()
            .flatMap(f -> compterMots(f) > MOTS_MAXIMUM ? scinder(f).stream() : List.of(f).stream())
            .map(f -> article.title() + "\n\n" + f)
            .toList();
    }

    /**
     * Un fragment devenu trop large est recoupé sur ses paragraphes, à mi-parcours. Cela
     * n'arrive que sur un article dont un seul paragraphe dépasse la limite — rare, mais
     * laisser passer un pavé reviendrait à ne rien avoir découpé.
     */
    private List<String> scinder(String fragment) {
        String[] paragraphes = fragment.split("\\n\\s*\\n");
        if (paragraphes.length < 2) return List.of(fragment);
        int milieu = paragraphes.length / 2;
        return List.of(
            String.join("\n\n", List.of(paragraphes).subList(0, milieu)),
            String.join("\n\n", List.of(paragraphes).subList(milieu, paragraphes.length)));
    }

    static int compterMots(String texte) {
        return texte.isBlank() ? 0 : texte.strip().split("\\s+").length;
    }
}
