package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Détail du calcul du score, sous forme de lignes « comme des logs » — pour que
 * le joueur comprenne d'où viennent ses points.
 *
 * <p><b>Calculé côté serveur</b> à partir des mêmes métriques et du même barème
 * que le score (aucune nouvelle règle) ; le client ne fait que l'afficher. Le
 * mock mobile reproduit ces lignes à l'identique (parité).
 *
 * <p>Chaque ligne porte un {@link Kind} qui indique comment l'afficher :
 * <ul>
 *   <li>{@code NOTE} — phrase d'explication (detail seul) ;</li>
 *   <li>{@code INFO} — mesure informative « label : detail » (sans points) ;</li>
 *   <li>{@code CRITERION} — critère noté « label (detail) : points/max » ;</li>
 *   <li>{@code SUBTOTAL} — sous-total d'un niveau « label = points/max » ;</li>
 *   <li>{@code TOTAL} — total/moyenne « label : points/max ».</li>
 * </ul>
 */
public record ScoreBreakdown(List<Line> lines) {

    public ScoreBreakdown {
        lines = List.copyOf(lines);
    }

    public enum Kind { NOTE, INFO, CRITERION, SUBTOTAL, TOTAL }

    public record Line(Kind kind, String label, String detail, Integer points, Integer maxPoints) {

        public static Line note(String text) {
            return new Line(Kind.NOTE, text, null, null, null);
        }

        public static Line info(String label, String detail) {
            return new Line(Kind.INFO, label, detail, null, null);
        }

        public static Line criterion(String label, String detail, int points, int maxPoints) {
            return new Line(Kind.CRITERION, label, detail, points, maxPoints);
        }

        public static Line subtotal(String label, int points, int maxPoints) {
            return new Line(Kind.SUBTOTAL, label, null, points, maxPoints);
        }

        public static Line total(String label, int points, int maxPoints) {
            return new Line(Kind.TOTAL, label, null, points, maxPoints);
        }
    }
}
