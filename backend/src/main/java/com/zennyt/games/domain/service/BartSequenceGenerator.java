package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.BartConfig;
import com.zennyt.games.domain.service.ObjectLocationLayoutGenerator.XorShift32;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Points d'éclatement des 32 ballons, dérivés de l'UUID de session.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : même hachage FNV-1a 32 bits et même xorshift32 que
 * « Je place » — la classe est RÉUTILISÉE, pas recopiée. Chaque ballon tire
 * {@code 1 + nextInt(MAX_PUMPS)}, soit une loi uniforme sur {@code 1..128}.
 * Miroir mobile : {@code mobile/lib/features/games/domain/config/bart_config.dart}.
 *
 * <p>Limite assumée, commune aux jeux à génération déterministe du module : un
 * client rétro-conçu peut recalculer la séquence. Le serveur garantit que le score
 * est RECALCULÉ depuis les pompes brutes et que toute issue impossible est rejetée ;
 * il ne peut pas empêcher un joueur qui connaît l'avenir de s'arrêter juste avant.
 */
public final class BartSequenceGenerator {

    public List<Integer> generate(UUID sessionId) {
        String material = sessionId.toString().toLowerCase(Locale.ROOT)
            + "|" + BartConfig.PROTOCOL_VERSION;
        XorShift32 random = new XorShift32(ObjectLocationLayoutGenerator.fnv1a32(material));
        List<Integer> explosionPoints = new ArrayList<>(BartConfig.TOTAL_BALLOON_COUNT);
        for (int i = 0; i < BartConfig.TOTAL_BALLOON_COUNT; i++) {
            explosionPoints.add(1 + random.nextInt(BartConfig.MAX_PUMPS));
        }
        return List.copyOf(explosionPoints);
    }
}
