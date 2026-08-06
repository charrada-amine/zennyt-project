# Compte rendu — 3, 4 et 5 août 2026

**Sujet : le Fit Score (le score de compatibilité candidat ↔ offre).**

---

## En trois lignes

J'ai comparé tout le Fit Score à son cahier des charges, ligne par ligne : **32 écarts** trouvés.
En cherchant, j'ai découvert que la branche principale **ne démarrait pas** — réparé.
J'ai ensuite commencé les corrections : **3 corrections livrées**, dont deux bugs qui faussaient les scores.

---

## Lundi 3 août — L'audit

J'ai repris le cahier des charges du Fit Score (les 10 sections) et la matrice des 142 métiers, et j'ai vérifié **chaque règle** dans le code réel.

Pour ne pas me tromper, je n'ai pas fait confiance à ma lecture : j'ai **exécuté le vrai calculateur** sur des candidats fictifs de plusieurs métiers (développeur, infirmier, comptable, designer, analyste financier…) et comparé les résultats aux règles écrites.

**Résultat : 32 écarts**, dont 6 graves.

Les plus importants :

| Ce qui ne va pas | Conséquence concrète |
|---|---|
| Un module de jeu inconnu du système devient **tout** le score | Un futur jeu non déclaré piloterait le score à lui seul |
| Aucune donnée = score de **0** enregistré | Un candidat jamais évalué apparaît comme ayant échoué |
| Sauter un mini-jeu qu'on rate **rapporte 11 points** | N'importe quel candidat peut en profiter |
| Les alertes recruteur sont fausses sur **12 lignes sur 24** | Une offre de Manager sans test n'alerte presque pas |
| Le mobile n'envoie pas le métier | **La création d'offre échoue** |
| Le client n'affiche aucun avertissement de fiabilité | Le recruteur voit un pourcentage nu, sans réserve |

J'ai tout écrit dans un document de travail (`FITSCORE_REMEDIATION.md`) avec, pour chaque écart, le fichier concerné, la gravité, et qui doit le corriger.

---

## Mardi 4 août — Le blocage caché, et la remise en ordre

### La découverte

En préparant le partage du travail, je me suis aperçu que mon audit tournait sur une branche **incomplète** : elle n'avait pas le travail de l'équipe Jeux.

En allant chercher ce travail, j'ai trouvé le vrai problème : **la branche principale ne démarrait pas.**

Trois fichiers de base de données portaient un numéro déjà utilisé — notre équipe et l'équipe Jeux avaient pris la même série chacune de son côté. Personne ne l'avait vu, parce que les deux branches fonctionnaient **séparément**. C'est la fusion qui a cassé.

**Réparé, et vérifié** : base recréée à zéro, 51 fichiers appliqués, application démarrée, API qui répond.

### Une très bonne nouvelle au passage

L'équipe Jeux avait livré le module **« Régulation émotionnelle »** — que mon audit signalait comme manquant. En le récupérant, l'erreur la plus grave a fondu :

> Deux infirmières, l'une excellente en régulation émotionnelle (95/100), l'autre faible (20/100) — sur un métier où cette qualité compte pour **45 %** du score — obtenaient **toutes les deux 61**. Le système ne pouvait pas les distinguer.
>
> Après récupération du module : **80** et **38**.

Sur les métiers relationnels, l'erreur est passée de **23 points à 0**.

### Remise en ordre

- Fusion de tout le travail (recrutement + jeux + mobile) sur une branche unique, `main`.
- Fusion de mon travail mobile en cours : vérifiée, **0 erreur**.
- Préparation du partage à deux avec mon collègue, par zones **sans fichiers communs** — pour qu'on ne se marche pas dessus.

---

## Mercredi 5 août — Les corrections

### Préparation commune (« Phase 0 »)

Six décisions bloquaient le travail. Elles ont été tranchées, puis appliquées :

- **Les niveaux d'expérience remis à l'échelle du cahier des charges.** Un renommage passé avait déplacé la pondération : un recruteur qui choisissait « Senior » obtenait en réalité les réglages d'un chef d'équipe. Corrigé.
  ⚠️ *C'est un changement qui casse l'API de l'équipe web — il faut les prévenir avant la mise en production.*
- Ajout de l'horodatage manquant sur le référentiel de pondération (prérequis pour recalculer les scores après l'atelier RH).
- Correction du seuil de fiabilité, qui regardait la mauvaise information.
- Mise en place d'un **filet de test** partagé, qui fige les scores actuels : chacun peut désormais prouver qu'il n'a pas cassé le travail de l'autre.

### Corrections du moteur de calcul (3 livrées)

| # | Correction | Effet |
|---|---|---|
| 1 | Le repli sur module inconnu, l'absence de donnée traitée comme un zéro, un arrondi prématuré, et du code mort | Les scores ne peuvent plus être pilotés par une donnée non reconnue |
| 2 | **La couverture réelle par module** — combien de chaque jeu a été réellement joué | Le cahier des charges le prévoyait ; ça n'existait nulle part, la valeur était figée à 100 % |
| 3 | Les jeux **envoient maintenant un résultat à chaque mini-jeu**, plus seulement à la fin | Avant, une partie interrompue ne produisait **rien du tout** |

Deux choses trouvées en chemin, qui n'étaient pas dans le plan :

- **L'information de couverture existait déjà** dans les jeux, et était **jetée** au passage.
- **Un piège de double pénalité** : un joueur parfait sur 1 des 3 mini-jeux aurait été pénalisé deux fois (une fois par le score, une fois par la couverture). Évité.

**Vérifié à chaque étape : 328 tests au vert, base recréée à zéro, application démarrée.**

---

## Ce qui reste — et une question ouverte

Les corrections suivantes sont prêtes mais **en attente d'un arbitrage**.

En corrigeant le bug « sauter un jeu rapporte 11 points », on tombe sur un effet de bord : le mini-jeu **« Je Décide »** n'est **pas jouable**. Pas parce qu'il n'est pas développé — il l'est entièrement, écrans mobiles compris — mais parce que ses **30 scénarios attendent le psychologue**.

Si on applique la règle telle quelle, ce module compte pour zéro, et **plafonne tous les développeurs à 70/100** — soit exactement le seuil de « bon profil ».

**Ma proposition** : distinguer deux cas différents.

| Situation | Traitement |
|---|---|
| Le candidat **a sauté** un jeu qui existe | il perd les points — sinon sauter reste rentable |
| Le jeu **n'existe pour personne** | il ne compte pas — personne ne doit être puni pour un jeu qui n'existe pas |

Le jour où les 30 scénarios arrivent, le module rentre automatiquement dans le calcul, sans retoucher au code.

**👉 Deux questions pour vous :**
1. Est-ce que cette approche vous convient ?
2. **Savez-vous où en sont les 30 scénarios de « Je Décide » ?** S'ils existent quelque part, le sujet se règle complètement.

---

## Bilan

| | |
|---|---|
| Écarts identifiés et documentés | **32** |
| Corrections livrées | **6** (3 de préparation + 3 du moteur) |
| Bug bloquant réparé | la branche principale ne démarrait pas |
| Erreur de calcul la plus grave | passée de **23 points à 0** |
| Travail partagé avec mon collègue | prêt, zones séparées |
