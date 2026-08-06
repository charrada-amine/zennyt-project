# Compte rendu — 27, 28 et 29 juillet 2026

**Projet :** Zennyt — module Recrutement (backend)

## Résumé en une phrase

Finalisation et vérification de 4 fonctionnalités backend, puis remise à
niveau complète de la documentation de l'API (le contrat) pour qu'elle
corresponde exactement à ce que le backend fait vraiment.

---

## 1. Finalisation des fonctionnalités backend

Quatre fonctionnalités développées récemment ont été validées et
enregistrées définitivement dans le projet, chacune séparément et testée
avant d'être validée :

- Le recruteur présélectionne un candidat, mais c'est désormais le
  **candidat qui confirme ou refuse** l'étape suivante (avant, le recruteur
  pouvait décider seul).
- **Génération de test technique par IA**, à partir d'une description de
  poste ou d'un fichier envoyé par le recruteur.
- **Résumé IA du candidat** pour le recruteur (compétences humaines +
  techniques), généré automatiquement.
- **Référentiel de 142 métiers**, avec validation par un administrateur
  avant d'apparaître dans la liste partagée.

## 2. Vérification en conditions réelles

Ces fonctionnalités n'avaient jamais tourné sur une vraie base de données —
seulement testées de façon isolée. Une vérification complète a été faite :
environnement relancé, base de données neuve, jeux d'essai automatisés
étendus de 56 à 67 scénarios de test.

Cette vérification a permis de trouver et corriger **deux vrais bugs**
invisibles avec les tests habituels :
- Le serveur ne démarrait pas du tout sur une vraie base de données
  (mauvaise configuration technique sur 3 tables).
- Une erreur technique brute (erreur 500) s'affichait au lieu d'un message
  propre en cas de doublon.

La suite de tests de démonstration a aussi été rendue plus fiable : elle
peut désormais être rejouée plusieurs fois de suite sans tout casser.

## 3. Mise en conformité du contrat de l'API

Le plus gros chantier des trois jours : le document officiel qui décrit
l'API (le « contrat ») et le code réel du backend avaient fini par diverger,
après plusieurs mois de développement.

**Méthode :** 14 fichiers de comparaison ont été fournis, un par un. Pour
chacun, chaque différence signalée a été vérifiée directement dans le vrai
code avant toute correction — pour éviter de corriger sur la base d'une
information fausse ou périmée.

**Principaux résultats :**
- Pagination des listes corrigée et uniformisée sur toute l'API.
- Le système de « candidature » a été simplifié : une notion redondante
  avec le système de « match » a été retirée, au profit d'un mécanisme
  unique et plus clair.
- Le système de test technique a été entièrement repensé : questions et
  réponses mélangées aléatoirement à chaque tentative, seuil de réussite
  unifié à 70 % pour tout le monde.
- Le format des messages d'erreur a été uniformisé sur toute l'API
  (recrutement et identité).
- Plusieurs bugs silencieux trouvés et corrigés en chemin (une date qui
  n'était jamais correctement enregistrée, un tri qui ne fonctionnait pas,
  des champs non attendus qui n'étaient pas rejetés).

Chaque changement important a été proposé et validé avant d'être appliqué,
avec un choix clair à chaque fois plutôt qu'une supposition.

**Résultat final :** contrat et backend sont maintenant cohérents, avec la
suite de tests automatiques toujours au vert (161 tests) après chaque étape.

---

## En résumé

| | |
|---|---|
| Fonctionnalités finalisées et vérifiées | 4 |
| Bugs réels trouvés et corrigés | 4 |
| Scénarios de démonstration automatisés | 67 |
| Fichiers de comparaison du contrat traités | 14 |
| Tests automatiques (backend) | 161, tous au vert |

**Reste à faire :** portage de ces nouveautés côté application mobile
(non traité sur cette période, backend uniquement).
