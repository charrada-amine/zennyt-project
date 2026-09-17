# Plan 001 — Intégrer les 82 emotes aux tâches de Day Stack

> **Instructions pour Claude :** lis ce plan entièrement, puis `AGENTS.md` et `GAMES_MODULE.md` à la racine. Exécute les étapes dans l’ordre et leurs vérifications. Préserve les modifications déjà présentes dans le workspace. Cette demande de plan n’autorise pas encore une modification de `mobile/pubspec.yaml` : obtenir l’autorisation explicite décrite à l’étape 4. Ne régénère pas les images.

## Statut

- Priorité : P2 ; effort : M ; risque : moyen (assets et rendu pendant le glissement).
- Dépendance : aucune autre planification ; déclaration des assets soumise à autorisation.
- Catégorie : direction / interface.
- Préparé le 2026-09-17, HEAD `ca70f4b`, **avec des changements non commités**.
- État : DONE le 2026-09-17 (autorisation `pubspec.yaml` accordée ; voir changelog 75 de `GAMES_MODULE.md`).

## Résultat attendu

Chaque tâche affiche une petite illustration correspondant à son action, dans le style Zennyt : objets arrondis en relief léger, mauve, marine, magenta et blanc cassé, sur fond transparent. La même illustration reste visible quand la carte est déplacée. La mission verte, le calendrier mauve, les heures, le défilement et le bouton Valider conservent leur comportement actuel.

## État actuel et références

Racine du projet : `/Users/mac/Documents/GitHub/zennyt-private/zennyt-project`.
Les chemins ci-dessous sont relatifs à cette racine.

- `mobile/assets/Day Stack/emotes-v1/` contient déjà **82 PNG transparents**, leur `manifest.json`, `validation.json`, `README.md`, le catalogue `index.html` et les planches `review/`.
- Répartition : restaurant 12, gestion 12, organisation 12, chantier 11, logistique 12, soins 11, déménagement 12 (`demenagement` dans les chemins).
- Le manifest fournit `universeId`, `taskId`, `file`, `label` et les variantes. Exemple : `restaurant/reception_livraison.png`.
- La banque `mobile/assets/games/day_stack_bank.json` contient `universes[].id` et `tasks[].id`. Les 82 couples correspondent au manifest au moment de rédaction.
- Les PNG originaux mesurent 1254 × 1254 ; le lot représente environ 72 Mio. Limiter la taille de décodage dans Flutter, sans modifier les originaux dans cette intégration.
- `mobile/lib/features/games/presentation/widgets/day_stack_badges.dart:125` définit déjà le composant à réutiliser :

```dart
const DayStackTaskBadge({
  super.key,
  required this.category,
  required this.icon,
  this.compact = false,
});
// Actuellement : icône Material dans un carré coloré.
// Taille compact : 28 ; taille normale : 38.
```

- `mobile/lib/features/games/presentation/widgets/day_stack_calendar.dart` affiche les cartes et leur aperçu pendant le glissement. `_CalendarItem._event()` construit `_CalendarEvent`, qui appelle `DayStackTaskBadge(category: task.category, icon: task.icon, compact: true)` vers la ligne 430.
- Le calendrier utilise déjà `ListView`, `LongPressDraggable`, une grille fixe et un paramètre `bottomInset` réservé au bouton Valider. **Conserver ces mécanismes.**
- Le parent `task_scheduling_screen.dart` transmet déjà l’univers au calendrier : aucune modification du parent prévue.
- Les dossiers des nouvelles emotes ne sont pas déclarés dans `mobile/pubspec.yaml`.

Règles applicables d’`AGENTS.md` : « Réutilise les composants partagés » ; « Ne touche jamais au […] pubspec.yaml sans autorisation explicite ». La création des emotes a été demandée par l’utilisateur ; leurs fichiers existent déjà. Aucune nouvelle image, couleur ou dépendance à inventer.

## Périmètre

Seuls fichiers à modifier ou créer pendant l’exécution :

- `mobile/lib/features/games/presentation/widgets/day_stack_badges.dart`.
- `mobile/lib/features/games/presentation/widgets/day_stack_calendar.dart`.
- `mobile/lib/features/games/presentation/widgets/day_stack_emotes.dart` — helper à créer.
- `mobile/test/features/games/presentation/day_stack_badges_test.dart`.
- `mobile/test/features/games/presentation/day_stack_emotes_test.dart` — tests à créer.
- `mobile/test/features/games/presentation/task_scheduling_screen_test.dart`.
- Les trois goldens de ce calendrier : `mobile/test/features/games/presentation/goldens/day-stack-calendar-purple.png`, `day-stack-calendar-bottom.png`, `day-stack-calendar-drag.png`.
- `mobile/pubspec.yaml` : **uniquement les sept déclarations d’assets, après autorisation**.
- `GAMES_MODULE.md` et la ligne de statut de `plans/README.md`.

Exclus : backend, contrat OpenAPI, `core/`, autres jeux, banque de tâches, entités du domaine, barèmes, métriques, durée des tâches, ordre initial, paramètres de dépendances et fichiers PNG originaux. Ne pas embarquer le catalogue HTML, les prompts, le manifest ni les planches de revue dans l’application.

## Workflow et contrôle de dérive

Depuis la racine, enregistrer `git status --short`, puis lancer :

```sh
git diff --stat ca70f4b..HEAD -- mobile/lib/features/games mobile/test/features/games mobile/assets/Day\ Stack/emotes-v1 mobile/pubspec.yaml GAMES_MODULE.md
git diff -- mobile/lib/features/games/presentation/widgets/day_stack_badges.dart mobile/lib/features/games/presentation/widgets/day_stack_calendar.dart mobile/pubspec.yaml
```

Comparer aussi les fichiers **non suivis** et les extraits ci-dessus : la comparaison de HEAD seule ne couvre pas le travail en cours. Préserver notamment `bottomInset` et les corrections récentes de glissement. Ne pas réinitialiser, stasher, changer de branche ni repartir de HEAD en perdant ces assets. Si une branche est demandée, utiliser le préfixe `codex/`, par exemple `codex/day-stack-emotes`. Aucun commit, push ou PR sans demande ; message proposé si demandé : `feat(games): intégrer les emotes Day Stack`.

## Étapes

### 1. Vérifier la couverture et enregistrer la référence

Lire le module en entier, notamment les zones protégées et décisions à valider. Vérifier les 82 identités composites et les fichiers avec cette commande depuis la racine :

```sh
python3 - <<'PY'
import json
from pathlib import Path
root = Path('mobile/assets/Day Stack/emotes-v1')
bank = json.loads(Path('mobile/assets/games/day_stack_bank.json').read_text())
entries = json.loads((root / 'manifest.json').read_text())['emotes']
expected = {(u['id'], t['id']) for u in bank['universes'] for t in u['tasks']}
actual = {(e['universeId'], e['taskId']) for e in entries}
assert len(entries) == len(actual) == len(expected) == 82
assert actual == expected, (expected - actual, actual - expected)
for e in entries:
    assert e['file'] == f"{e['universeId']}/{e['taskId']}.png"
    assert (root / e['file']).is_file(), e['file']
print('82 identités couvertes, 82 fichiers présents')
PY
```

Exécuter les tests existants ci-dessous **avant modification** et enregistrer leurs résultats. Ne pas présenter les résultats historiques comme une validation actuelle.

```sh
cd /Users/mac/Documents/GitHub/zennyt-private/zennyt-project/mobile
flutter test --no-pub test/features/games/presentation/day_stack_badges_test.dart test/features/games/presentation/task_scheduling_screen_test.dart test/features/games/domain/day_stack_schedule_test.dart test/features/games/data/day_stack_bank_test.dart test/features/games/data/day_stack_variants_test.dart
```

**Vérification :** couverture exacte, fichiers présents, tests de référence verts ; sinon identifier et signaler les problèmes préexistants avant de poursuivre.

### 2. Étendre le badge existant

Créer `day_stack_emotes.dart` avec un helper de chemin, sans parsing du manifest au runtime :

```dart
String? dayStackEmoteAssetPath({String? universeId, String? taskId});
// null si une identité est absente ou vide ; sinon :
// assets/Day Stack/emotes-v1/<universeId>/<taskId>.png
```

Ne pas utiliser le texte, sa variante, l’index, la catégorie ou l’ancienne icône pour choisir l’emote. Certains identifiants sont répétés dans différents univers : le couple est obligatoire.

Ajouter deux paramètres **optionnels** `universeId` et `taskId` à `DayStackTaskBadge`, en conservant les anciens appels valides. Si l’identité est fournie, afficher `Image.asset` dans une boîte fixe, `BoxFit.contain`, sans carré coloré supplémentaire : les PNG sont transparents et ont leur propre contour. Proposition de présentation : compact 32 px, normal 38 px ; tracer cette nouvelle taille comme provisoire à valider visuellement.

Limiter le décodage avec `cacheWidth` égal à la taille affichée multipliée par le ratio de pixels de l’écran, arrondie au supérieur. Éviter de décoder une image de 1254 px pour une emote de 32 px.

Conserver l’ancienne icône comme repli si l’identité manque ou si `errorBuilder` reçoit une erreur. Sans identité, conserver les dimensions historiques 28/38 px ; en cas d’échec de chargement d’une emote, conserver la boîte 32/38 px pour éviter un saut de disposition. Garder les couleurs de catégories et le liseré des cartes. L’image reste décorative pour l’accessibilité ; éviter les annonces doublées du titre ou de la catégorie.

**Vérification :** les tests du badge historique et les nouveaux tests du helper/repli passent via `flutter test --no-pub test/features/games/presentation/day_stack_badges_test.dart test/features/games/presentation/day_stack_emotes_test.dart`. À cette étape, les tests de couverture du bundle nécessitent encore l’étape 4 ; ne pas masquer leur absence par le repli.

### 3. Transmettre l’identité dans le calendrier

Dans `DayStackCalendar`, transmettre `widget.universe.id` à `_CalendarItem`. Ajouter le champ requis correspondant à `_CalendarItem` et `_CalendarEvent`, le propager dans `_CalendarItem._event()`, puis passer au badge `universeId` et `taskId: task.id`.

Le chemin commun `_event()` doit servir à la carte normale, à sa source atténuée et à l’aperçu déplacé. Ne pas reconstruire la ligne complète dans l’aperçu, ne pas déplacer les repères horaires ni les périodes d’attente. Conserver les clés, callbacks, contraintes de hauteur, auto-défilement et espace réservé à Valider.

**Vérification :** depuis `mobile/`, `flutter analyze --no-pub lib/features/games/presentation/widgets/day_stack_emotes.dart lib/features/games/presentation/widgets/day_stack_badges.dart lib/features/games/presentation/widgets/day_stack_calendar.dart` termine sans erreur. La validation complète du rendu suit la déclaration des assets.

### 4. Déclarer les sept dossiers après autorisation explicite

Préparer ce diff précis dans la section `flutter: assets:` de `mobile/pubspec.yaml`, puis obtenir l’autorisation avant de l’appliquer si elle n’a pas déjà été fournie dans la session d’exécution :

```yaml
    - "assets/Day Stack/emotes-v1/restaurant/"
    - "assets/Day Stack/emotes-v1/gestion/"
    - "assets/Day Stack/emotes-v1/organisation/"
    - "assets/Day Stack/emotes-v1/chantier/"
    - "assets/Day Stack/emotes-v1/logistique/"
    - "assets/Day Stack/emotes-v1/soins/"
    - "assets/Day Stack/emotes-v1/demenagement/"
```

Une entrée pour le dossier parent ne suffit pas à couvrir ces sous-dossiers. Ne modifier aucune dépendance. Après autorisation et application, depuis `mobile/`, lancer `flutter pub get`.

**Vérification :** commande terminée avec code 0 ; `git diff -- mobile/pubspec.yaml mobile/pubspec.lock` depuis la racine montre uniquement les sept ajouts autorisés par cette tâche, sans changement de versions. Ne pas effacer d’éventuels changements préexistants.

### 5. Vérifier le bundle, le rendu et le glissement

Dans les tests existants du badge et du calendrier, ajouter les cas utiles :

- Chargement réel des **82 fichiers via `rootBundle.load`**, avec comparaison aux couples de la banque. Le manifest peut être lu depuis le disque dans les tests, sans déclaration d’asset supplémentaire.
- Un même `taskId` dans deux univers produit deux chemins distincts, notamment `chargement_camion` dans logistique et déménagement.
- Les variantes textuelles d’une tâche conservent la même emote.
- Identité absente et chemin volontairement invalide : ancien pictogramme visible, aucun crash, disposition stable.
- Décodage adapté au ratio de pixels ; taille fixe du badge.
- La carte et son aperçu déplacé ont la même image ; elle reste liée à la tâche après réorganisation.
- Les régressions existantes de petits écrans, textes agrandis, dernière tâche accessible, heures et attentes pendant le glissement, auto-défilement et Valider restent couvertes.

Attendre le chargement effectif des images avant captures et goldens. Un test ne doit pas passer avec l’icône de repli à la place d’un asset connu.

Depuis `mobile/` :

```sh
flutter test --no-pub test/features/games/presentation/day_stack_badges_test.dart test/features/games/presentation/day_stack_emotes_test.dart test/features/games/domain/day_stack_schedule_test.dart test/features/games/data/day_stack_bank_test.dart test/features/games/data/day_stack_variants_test.dart
flutter test --no-pub --update-goldens test/features/games/presentation/task_scheduling_screen_test.dart
flutter test --no-pub test/features/games/presentation/task_scheduling_screen_test.dart
```

**Vérification :** tous les tests verts, 82 assets accessibles dans le bundle ; seules les trois captures Day Stack prévues changent. Inspecter les captures : emotes nettes sur mauve, texte lisible, aucun débordement ni changement de grille pendant le glissement. Ne pas régénérer les goldens d’autres jeux. En cas d’échec de référence, ne pas utiliser une régénération pour le masquer.

### 6. Documenter et livrer

Mettre à jour `GAMES_MODULE.md` : arborescence du helper/tests, statut et roadmap des emotes désormais intégrées, clé composite, fallback et taille de décodage. Conserver les barèmes et l’historique. Ajouter une entrée datée avec le **prochain numéro disponible**, actualiser « Dernière mise à jour » et tracer la taille proposée dans les décisions à valider. Ne pas déclarer la validation visuelle acquise sans revue.

Depuis la racine : `git diff --check` doit terminer avec code 0. Comparer `git status --short` au relevé initial : seuls les fichiers du périmètre ont été changés par cette tâche. Formater uniquement les fichiers Dart touchés, puis relancer les vérifications ciblées après toute correction.

La CI mobile existante exécute également `flutter analyze --no-fatal-infos` et `flutter test --coverage` depuis `mobile/` ; exécuter ces contrôles de fin et distinguer précisément les échecs préexistants. Aucun test backend supplémentaire nécessaire : backend et contrat restent inchangés.

Mettre le statut du plan à DONE uniquement quand toutes les étapes sont terminées. Fournir les fichiers créés/modifiés, le nombre réel de tests verts, les décisions de présentation, les éventuels points ouverts et confirmer que les zones protégées n’ont pas été touchées.

## Critères de fin

- [ ] Les 82 couples banque/manifest correspondent et les 82 PNG chargent depuis le bundle.
- [ ] Chaque tâche affiche son emote, même après changement de variante et déplacement.
- [ ] Le repli fonctionne ; les anciens appels du badge restent valides.
- [ ] Calendrier, heures, attente, auto-défilement, mission et Valider conservent leurs régressions vertes.
- [ ] Déclaration des sept dossiers explicitement autorisée ; aucune dépendance modifiée.
- [ ] Tests ciblés et analyse passent ; différences de goldens examinées.
- [ ] Documentation et statut actualisés ; aucun changement hors périmètre attribuable à cette tâche.

## Conditions d’arrêt et suites

Signaler avant d’improviser si la banque ne correspond plus aux 82 fichiers, si les extraits décrivent un autre mécanisme de cartes, si une modification hors périmètre devient nécessaire, ou si un même contrôle échoue deux fois après une correction raisonnable. L’absence d’autorisation pour `pubspec.yaml` bloque l’étape 4 et la validation du bundle ; les préparatifs autorisés peuvent être achevés et présentés pour revue.

Une future nouvelle tâche exige une nouvelle emote et la mise à jour du manifest/contrôle de couverture. La réduction du poids des PNG à l’installation est un travail séparé : `cacheWidth` réduit le coût de décodage, pas la taille des fichiers embarqués. Ne pas promettre une réduction du poids de l’application avec cette seule intégration.
