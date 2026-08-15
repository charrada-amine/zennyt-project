package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le signal « données partielles » (CdC Fit Score v3 §3.3, mécanisme 2).
 *
 * <p>Ce signal n'ajuste jamais le score : il décide seulement d'un badge côté client.
 * Personne ne le testait jusqu'ici — ni le seuil renforcé de F04, ni le mode
 * d'évaluation du métier — alors qu'il porte deux règles qui se sont déjà trompées.
 */
class FitScorePartialDataTest {

    private static FitScore avecCouverture(int couverture) {
        return FitScore.rehydrate(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            72, 75, 68, couverture, Instant.now());
    }

    /**
     * F04 — le seuil dépend de la présence d'un QCM sur l'OFFRE, pas de la tentative du
     * candidat. Une offre qui porte un QCM a une dimension hard capable de compenser
     * l'incertitude du soft : 60 % suffisent. Sans QCM, tout repose sur le soft et le
     * seuil monte à 70 %.
     */
    @Test
    @DisplayName("Le seuil de couverture dépend du QCM de l'offre, pas de la tentative")
    void seuilRenforceSansQcmSurLOffre() {
        FitScore entreLesDeuxSeuils = avecCouverture(65);

        assertThat(entreLesDeuxSeuils.partialData(true, TypeEvaluationHard.QCM))
            .as("65 %% dépasse le seuil de 60 %% applicable quand l'offre porte un QCM")
            .isFalse();
        assertThat(entreLesDeuxSeuils.partialData(false, TypeEvaluationHard.QCM))
            .as("65 %% reste sous le seuil de 70 %% applicable sans QCM")
            .isTrue();
    }

    @Test
    @DisplayName("Une couverture pleine ne déclenche aucun signal")
    void couverturePleineAucunSignal() {
        assertThat(avecCouverture(100).partialData(true, TypeEvaluationHard.QCM)).isFalse();
        assertThat(avecCouverture(100).partialData(false, TypeEvaluationHard.QCM)).isFalse();
    }

    /**
     * <b>Le cœur de ce fichier.</b> Un métier en mode Mixte attend deux mesures techniques
     * — un QCM <i>et</i> un portfolio (CdC §4.3) — et le portfolio n'a aucune note dans le
     * système : il n'existe que comme une URL sur le profil du candidat, qu'aucun mécanisme
     * n'évalue. La mesure est donc incomplète par construction, même quand le candidat a
     * tout joué et tout réussi.
     *
     * <p>Le score, lui, reste juste : on retire le terme non mesurable au lieu de le mettre
     * à zéro. C'est le signal qui manquait, pas le chiffre.
     */
    @Test
    @DisplayName("Un métier Mixte est toujours signalé partiel, même parfaitement couvert")
    void metierMixteToujoursPartiel() {
        FitScore parfaitementCouvert = avecCouverture(100);

        assertThat(parfaitementCouvert.partialData(true, TypeEvaluationHard.MIXTE))
            .as("le portfolio attendu par le métier n'est mesuré par personne")
            .isTrue();
        assertThat(parfaitementCouvert.partialData(false, TypeEvaluationHard.MIXTE)).isTrue();
    }

    /**
     * Symétrique du précédent, et c'est ce qui rend la règle défendable : en mode
     * Portfolio, le portfolio <b>est</b> l'évaluation. Rien ne manque, donc rien à
     * signaler. Si le mode Portfolio déclenchait lui aussi le badge, celui-ci deviendrait
     * permanent sur tout le profil ARTISTIQUE et cesserait d'être lu.
     */
    @Test
    @DisplayName("Un métier Portfolio n'est pas partiel : le portfolio EST l'évaluation")
    void metierPortfolioNestPasPartiel() {
        assertThat(avecCouverture(100).partialData(false, TypeEvaluationHard.PORTFOLIO)).isFalse();
        assertThat(avecCouverture(100).partialData(true, TypeEvaluationHard.PORTFOLIO)).isFalse();
    }

    @Test
    @DisplayName("Le mode ne masque jamais une couverture insuffisante")
    void leModeNeMasqueJamaisUneCouvertureFaible() {
        FitScore malCouvert = avecCouverture(30);

        for (TypeEvaluationHard mode : TypeEvaluationHard.values()) {
            assertThat(malCouvert.partialData(true, mode))
                .as("mode %s avec 30 %% de couverture", mode)
                .isTrue();
        }
    }

    /**
     * Une offre pas encore reliée au référentiel n'a pas de mode. Le signal doit alors se
     * décider sur la seule couverture, sans planter.
     */
    @Test
    @DisplayName("Sans métier résolu, seule la couverture décide")
    void sansMetierResoluSeuleLaCouvertureDecide() {
        assertThat(avecCouverture(100).partialData(true, null)).isFalse();
        assertThat(avecCouverture(30).partialData(true, null)).isTrue();
    }
}
