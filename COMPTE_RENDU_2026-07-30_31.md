# Compte rendu — 30 et 31 juillet 2026

**Module Recrutement — Fit Score (score de compatibilité candidat / offre)**

---

## 1. Le problème de départ

Le Fit Score est la note qui mesure à quel point un candidat correspond à une offre. C'est
elle qui classe les offres dans « Recommended for you ».

Deux problèmes ont été traités :

**a) Certaines notes n'étaient jamais calculées.** Le calcul se déclenchait à trois moments
(un candidat joue à un mini-jeu, une offre est publiée, un test est passé), mais chaque
déclenchement était limité à 20 paires candidat/offre. Au-delà d'une vingtaine d'offres ou de
candidats, certaines paires ne recevaient **jamais** de note. Ce n'était pas un retard : c'était
un trou permanent, qui grandissait avec la plateforme.

**b) La note ne variait pas selon le métier.** En vérifiant les données, j'ai constaté qu'un
candidat obtenait exactement la **même note sur 30 offres différentes**, alors que ces offres
correspondaient à des métiers très différents.

---

## 2. Ce que j'ai fait

### Un rattrapage automatique

J'ai ajouté une tâche qui tourne en fond, cherche les paires sans note et les calcule par petits
lots. Elle reprend aussi les notes devenues fausses (par exemple quand un candidat rejoue un
mini-jeu). Les trois déclencheurs existants n'ont pas été modifiés : le rattrapage vient en plus,
sans risque de casser ce qui marchait déjà.

Pour que ce soit tenable, j'ai d'abord réduit le coût du calcul : il fallait 8 allers-retours vers
la base de données par paire. En chargeant les données par lot, on passe d'environ 1 600 requêtes
à 7 pour un lot de 200 — soit **10× plus rapide et 200× moins de requêtes**.

### La correction de la formule

Pour le deuxième problème, j'avais d'abord conclu que c'était normal, conforme au cahier des
charges. **Mon encadrant a contesté ce diagnostic**, chiffres à l'appui. En reprenant le code de
plus près, il avait raison : c'était bien un bug.

Le cahier des charges (§3.2) prévoit que le score se calcule en pondérant les 5 modules
psychométriques selon le métier de l'offre. Le programme, lui, faisait d'abord la **moyenne** de
tous les modules du candidat, puis essayait d'appliquer les pondérations. Or pondérer une moyenne
déjà calculée ne change rien mathématiquement : la pondération n'avait plus aucun effet.

Corrigé : les scores de chaque module sont maintenant transmis tels quels jusqu'au calcul final.
**Vérification sur base réelle** — même candidat, mêmes résultats aux mini-jeux, aucun test passé :
score de **56** sur une offre technique, **60** sur une offre relationnelle. La note varie enfin
selon le métier, comme prévu.

---

## 3. Bugs découverts au passage

Quatre défauts trouvés et corrigés, tous **silencieux** : aucune erreur affichée, aucun message
dans les journaux — simplement une fonctionnalité qui ne faisait pas ce qu'elle devait.

- L'application **ne démarrait plus** dès qu'un profil candidat existait en base.
- **Remplir son profil n'avait aucun effet** sur le classement des offres jusqu'au redémarrage
  suivant du serveur.
- **Fermer ou publier une offre ne déclenchait rien.**
- Le rattrapage aurait pu **tourner en boucle indéfiniment** sur les offres sans métier validé
  (repéré avant la mise en service).

Chacun est maintenant couvert par un test qui empêche le problème de revenir.

---

## 4. Comment c'est vérifié

Le travail n'a pas été validé seulement par des tests automatiques. Chaque mécanisme a été
éprouvé sur une **vraie base de données**, créée puis détruite pour l'occasion, avec de vraies
inscriptions et de vraies offres :

| Vérification | Résultat |
|---|---|
| Rattrapage | 700 paires (25 candidats × 28 offres) toutes calculées en 4 passages |
| Notes périmées | Un mini-jeu rejoué a rafraîchi **les 28** notes du candidat (avant : 20 seulement) |
| Fermeture d'offre | Les 28 notes supprimées correctement |
| Métier validé par un admin | Calcul automatique des 25 candidats, sans mécanisme dédié |

**Suite de tests complète : 314 tests, 0 échec.** Tout est fusionné dans la branche principale.

---

## 5. Ce qui reste

**Une décision à prendre** (elle ne relève pas de la technique) : le cahier des charges est
ambigu sur un point. Le poids des compétences techniques doit-il s'activer dès qu'une offre a un
test configuré, ou seulement quand le candidat l'a effectivement passé ? Le code a choisi la
deuxième option, mais ce choix n'a jamais été confirmé explicitement.

**Deux dépendances externes :**

- L'écran mobile de création d'offre doit ajouter un sélecteur de métier, devenu obligatoire côté
  serveur (l'équipe mobile est prévenue).
- Le mini-jeu « Prise de décision » n'est pas encore jouable, donc ce module ne compte pas encore
  dans le calcul. Les 4 autres fonctionnent.

**Un point non mesuré :** la charge que le rattrapage peut imposer à la base de données en
conditions réelles. C'est la vraie limite du système. Une mesure a été mise en place pour
surveiller le retard et alerter **avant** saturation.

---

*Compte rendu établi pour le suivi du projet Zennyt — module Recrutement.
Tous les chiffres cités proviennent de mesures réelles, aucun n'est estimé.*
