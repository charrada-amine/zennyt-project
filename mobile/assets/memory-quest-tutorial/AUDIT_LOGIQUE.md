# Vérification des règles et du câblage — 2026-09-17

Analyse préalable à la refonte des tutoriels. Les routes Digits et Image utilisent
`InvestigateScreen` et ses modes séparés. `MemoryImagesGame` est un moteur pur testé
indépendamment, mais n’est pas utilisé par ces routes : ses garanties ne prouvent
donc pas à elles seules le bon fonctionnement du câblage de l’écran.

## Règles effectivement jouées

| Aspect | Digits | Image |
|---|---|---|
| Départ | Trois chiffres, révélés un par un, clavier bloqué | Trois objets, ordre initial visible, réponse bloquée |
| Restitution | Même séquence dans l’ordre puis à l’envers | Ordre initial après échanges automatiques ; aucun rappel inverse |
| Interférence | Question arithmétique dès le niveau 3, avant le rappel direct | Intrus ou pièce manquante dès le niveau 2, avant la restitution |
| Réponse | Pavé numérique, effacement du dernier chiffre | Appuis successifs ; retoucher un objet retire son rang et renumérote |
| Validation | Séquence complète requise | Classement complet requis ; à zéro, validation du classement partiel |
| Progression | Un chiffre supplémentaire après un tour parfait | Une image supplémentaire après un tour parfait |
| Arrêt | Deux tours ratés au même niveau, dernier niveau ou borne de session | Même règle |

Les parcours séparés ont sept niveaux (trois à neuf éléments effectivement).
Les temps d’observation sont administrables/adaptatifs ; aucun délai fixe n’est
ajouté au tutoriel. En mode historique combiné, l’interférence reste celle des
chiffres : pas de casse-tête d’images supplémentaire dans le même tour.

## Défauts préexistants reproduits, correction ouverte

1. **Mode incorrect dans la soumission Image.** `_buildMetrics()` ne transmet pas
   `mode` à `MemoryQuestMetrics`, qui prend `FULL` par défaut. Deux restitutions
   laissées expirer au niveau 1 produisent effectivement `mode=FULL` et
   `observedDigits=0`. La validation Java refuse un mode jouant les chiffres sans
   chiffre observé ; le mock ne permet pas de prouver la réussite de cette API.
   Corriger ultérieurement la projection du mode et tester le payload de chaque route.
2. **Chrono de restitution non gelé en pause.** `_openPause()` annule le timer de
   distraction, mais ne gèle pas `_restoreTimer`. Reproduction : ouvrir le menu
   pendant la restitution, attendre trois secondes. La progression descend de
   `0.830508` à `0.186441` (attente et animation d’ouverture comprises). L’expiration
   peut donc avancer le jeu sous le menu. Le `Stopwatch` de réponse n’est pas non
   plus arrêté, d’après la lecture du code. Définir et tester une suspension complète.

Deux sondes widget temporaires ont reproduit ces défauts puis ont été retirées :
aucun test permanent n’impose le maintien de ces comportements incorrects.

## Écarts supplémentaires constatés par lecture du code

- Le budget Image de la tâche parasite utilise `_distractSeconds=8`, au lieu de
  `challenge.timeLimitMs` calculé par la factory/config selon le niveau. Le moteur
  `MemoryImagesGame` utilise bien le budget du challenge ; l’écran ne le branche pas.
- L’écran ne renseigne pas les compteurs `distractionChallengesPlayed/Solved/Timeouts`
  et ne journalise aucune tâche `distractionChallenge`, contrairement au moteur pur.
  La restitution après distraction est bien journalisée une seule fois.
- Le compteur `restoreCorrect` est cumulé sur les tours alors que `objectCount`
  prend uniquement la longueur du dernier lot dans `_buildMetrics()` ; la validation
  Java borne pourtant `restoreCorrect` par `objectCount`. Un parcours Image de
  plusieurs niveaux mérite un test de soumission dédié.

Ces écarts concernent le câblage et les métriques, pas les nouvelles illustrations.
Ils sont laissés ouverts ; aucune règle métier, donnée de partie ou notation n’a
été modifiée pendant cette refonte. Les textes n’affirment pas que le casse-tête
Image est déjà intégré au score ni que tous les timers sont gelés en pause.

## Vérifications

- Baseline : 66 tests Flutter ciblés verts, avant modification.
- Refonte : 84 tests Flutter ciblés verts ; deux tests de captures existantes de
  restitution verts en complément. Neuf tests du tutoriel vérifiés ensuite sans
  régénération des captures. Analyse ciblée de cinq fichiers Dart sans diagnostic.
- Scoring Java : les 18 méthodes `@Test` de `MemoryQuestScoringTest` passent,
  compilées et exécutées isolément avec Java 21 et les assertions JUnit existantes.
  La commande Maven standard bloque à `testCompile` dans des tests Recruitment
  préexistants (`saveIfNotOlder` et symboles associés). Aucun fichier Recruitment
  modifié, suite backend globale et ArchUnit non vérifiés par cette exécution isolée.
