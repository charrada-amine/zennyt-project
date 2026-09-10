# Zennyt — refonte de l’expérience mobile

**Dernière mise à jour : 2026-09-08**

## Statut et périmètre

Implémentation en cours ; tous les écrans ne sont pas encore terminés. Application confirmée par
l’utilisateur : `mobile/`. Demande : repenser l’interface en conservant son
identité, avec davantage d’interactions, de fluidité et de retours haptiques.

La refonte concerne la présentation des parcours existants. L’utilisateur a
autorisé le socle transversal `core/`, les widgets partagés et la création du
document Identity manquant, puis demandé l’implémentation de tous les écrans. Aucun changement de backend ou de contrat n’est nécessaire
pour cette direction visuelle.

## Références inspectées

Figma Desktop, via Computer : **Progress Careers Application File**, page
**Mobile Version**, variantes claires et sombres.

- Vue d’ensemble des parcours mobile.
- Games list : catégories cognitives, illustrations, couverture, navigation et
  variantes de vérification d’identité.
- Profile : identité professionnelle, compétences, expérience et formulaires
  d’ajout/modification.
- Fits job : fiche de poste, cartes de correspondance, critères et actions.

Fichier : https://www.figma.com/design/ghxKgyhlxIHfRuAOR2uGYB/Progress-Careers-Application-File

Identité à conserver : bleu marine, magenta, surfaces claires légèrement teintées,
illustrations ludiques, angles arrondis. Les tokens Flutter existants fournissent
notamment `#21438A`, `#D12E7D` et `#001D55`. Les variantes sombres doivent recevoir
le même travail de hiérarchie et de contraste.

## Diagnostic

- Les bordures, séparateurs et petites cartes donnent un poids similaire à trop
  d’éléments. La prochaine action se distingue peu du contenu secondaire.
- Les formulaires Figma occupent des modales denses et répétitives.
- La navigation Flutter conserve correctement l’état des onglets, mais manque
  d’une transition visuelle et tactile cohérente.
- Le hub jeux définit sa propre palette et un fond blanc fixe ; il se détache du
  thème partagé et affiche actuellement une couverture `0%` codée en dur.
- L’application possède déjà `flutter_animate`, `flutter_svg`, une police Inter
  locale et un service de retours haptiques. Lottie n’est pas installé.
- Le mode démonstration verrouille volontairement certains onglets. Cette règle
  ne doit pas être supprimée comme un simple défaut d’interaction.

## Direction proposée

Une expérience de découverte professionnelle plus expressive et tactile :
titres plus affirmés, contenus mieux espacés, illustrations plus présentes et
actions principales immédiatement lisibles.

| Surface | Refonte envisagée | Interaction |
| --- | --- | --- |
| Navigation | Barre arrondie, sélection clairement matérialisée, icônes existantes | Indicateur mobile, légère compression au toucher, retour de sélection |
| Accueil | En-tête allégé, composition éditoriale du fil et du formulaire de publication | Entrée discrète des contenus, réactions animées selon leurs actions existantes |
| Fits | Carte principale plus immersive, critères regroupés, détails hiérarchisés | Déplacement direct de la carte, retour élastique, actions accessibles par boutons |
| Progress / jeux | Introduction plus expressive, catégories plus lisibles, logos officiels mis en valeur | Expansion fluide, cartes tactiles, transition vers les jeux disponibles |
| Profil | Identité mieux mise en avant, sections plus aérées, édition plus claire | Expansion des détails, feedback des champs et confirmation des sauvegardes |
| Authentification et onboarding | Composition renouvelée autour de la marque et des éléments existants | Transitions entre étapes, état de saisie lisible, chargement intégré au bouton |
| Recherche / notifications / recrutement | Même vocabulaire de surfaces, actions et typographie | Filtres réactifs, changements d’état animés, traitement cohérent des erreurs |

Ces propositions restent des choix de présentation à vérifier dans chaque
parcours. Elles n’ajoutent ni score, ni série quotidienne, ni récompense métier.

## Système de mouvement

Valeurs initiales de présentation, à ajuster en vérification sur appareil :

- Pression : compression légère sur 100–140 ms, retour amorti sur 220–300 ms.
- Navigation et expansion : 260–360 ms, priorité à la continuité spatiale.
- Apparition : opacité et petit déplacement, décalage limité entre éléments.
- Illustration : animation locale lors d’une interaction ou d’un changement
  d’état ; éviter le mouvement permanent dans les écrans de lecture.
- Haptique : service existant, avec distinction entre sélection, succès et erreur,
  et respect du réglage de désactivation.
- Accessibilité : réduction des animations système, cibles tactiles suffisantes,
  lecture avec texte agrandi, sémantique des actions et alternatives aux gestes.
- Jeux : aucune animation ne doit changer les durées d’exposition, le verrouillage
  des entrées, le chronométrage, les règles de pause ou les métriques mesurées.

SVG et animations Flutter permettent une première réalisation sans dépendance.
Lottie nécessite une autorisation distincte pour `mobile/pubspec.yaml` et des
animations adaptées à l’identité du produit.

## Composants à réutiliser et fichiers concernés

Socle transversal proposé :

- `mobile/lib/core/theme/` : thème, typographie, espacement et surfaces.
- `mobile/lib/shared/widgets/` : évolution des boutons, champs, en-têtes et
  chargeurs existants ; paramètres compatibles avec leurs usages actuels.
- `mobile/lib/core/router/app_router.dart` : harmonisation des transitions de
  présentation si nécessaire, en conservant routes et gardes.
- `mobile/lib/core/audio/sound_service.dart` : réutilisation du service ; ne pas
  créer un circuit haptique concurrent.

Application progressive aux composants de présentation dans
`mobile/lib/features/`, en commençant par `navigation`, `home`, `fits` et le hub
`games`, puis les parcours d’authentification, profil, recherche, notifications et
recrutement. Lire intégralement les documents de chaque module avant leurs edits.
`IDENTITY_AUTH_README.md` a été créé avec autorisation. L’ancien
`docs/FRONTEND_AUTH_DEV.md` décrit une authentification dev par header, dépassée
par l’implémentation actuelle à tokens.

## Ordre de réalisation et validation

1. Autoriser le socle transversal, puis établir le vocabulaire visuel et de mouvement
   dans les composants existants.
2. Réaliser navigation, accueil, Fits et hub Progress ; vérifier les parcours,
   l’état conservé entre onglets, les modes clair/sombre et les tailles d’écran.
3. Étendre la direction aux autres écrans existants après lecture de leurs docs
   et références. Préserver les changements locaux déjà présents dans le dépôt.
4. Vérifier `flutter analyze`, les tests mobile pertinents puis la suite mobile,
   et inspecter les écrans dans le simulateur. Le ressenti haptique nécessite un
   appareil physique ; un simulateur ne suffit pas à le valider.
5. Mettre à jour les documents des modules touchés avec des entrées numérotées,
   sans réécrire leur historique.

Validation au 2026-09-08 : 14 tests ciblés verts (6 socle/auth, 4 Fits/recherche,
4 profils/réglages). Captures des écrans de connexion et réglages générées dans
`output/redesign/`. `flutter analyze --no-pub` : aucune erreur ni warning,
10 informations préexistantes dans les autres fichiers. Suite mobile complète et
inspection sur appareil encore à effectuer. Aucun test backend/ArchUnit exécuté
pour cette refonte : aucun code backend, contrat, score ou domaine modifié par ce
travail. Le dépôt contient des changements antérieurs sur les jeux, à préserver.

## Décisions à valider

- Socle visuel partagé `core/` et `shared/widgets/` : autorisation obtenue.
- Choix de présentation décrits ci-dessus : propositions de refonte, pas de
  nouvelles fonctionnalités métier validées.
- Document Identity : création autorisée et réalisée.
- Choix de présentation à revoir : découverte séparée du deck de matching,
  fiches détaillées en feuille, identité profil plus expressive, actions sans
  implémentation désactivées explicitement. Aucun nouveau barème ou endpoint.
- Les filtres Lead/Manager reprennent les valeurs du modèle existant ; les anciens
  contrôles sans effet (expérience, champs non câblés) ont été retirés de la page.
- Les valeurs de démonstration du profil recruteur ne doivent pas apparaître comme
  des données réelles : les champs absents montrent désormais une valeur vide.
- Lottie reste optionnel ; aucune modification de dépendance à ce stade.
- Couverture des jeux codée en dur : problème préexistant signalé, à traiter dans
  une intégration validée si les données nécessaires ne sont pas déjà disponibles.

## Couverture de l’implémentation

| Parcours | État actuel |
| --- | --- |
| Thèmes, boutons, champs, logo SVG, chargement | Réalisé ; pression, révélation et réduction du mouvement |
| Navigation principale | Réalisé ; état des onglets conservé, restrictions Lot 1 conservées |
| Login, inscription, OTP, récupération e-mail | Refonte partielle réalisée et formulaires vérifiés |
| Onboarding | Composition et progression renouvelées ; vérification dédiée restante |
| Fits, recherche et filtres | Réalisé ; détails, recherche, swipe et états testés |
| Profils candidat/recruteur et réglages | En cours ; carte identité, menu commun, langue réalisés |
| Édition, CV, accessibilité, centre de compte | Refonte complémentaire restante |
| Accueil et notifications | Restant ; intégrations préexistantes à clarifier |
| Recrutement et évaluations | Restant |
| Hub et écrans de jeux | Restant ; lecture complète des docs/assets avant édition |
| Splash, finalisation du profil | Restant |

Aucune dépendance ajoutée ; `pubspec.yaml` et `pom.xml` inchangés par cette refonte.
Les SVG et les animations natives Flutter servent de base, sans bibliothèque Lottie.

## Changelog

1. **2026-09-07** — Audit initial Figma via Computer, confirmation de `mobile/`,
   direction visuelle et interactive proposée, inventaire des composants
   réutilisables et périmètre transversal à autoriser. Aucun code applicatif modifié.

2. **2026-09-08** — Implémentation du socle thème/mouvement, navigation,
   authentification et onboarding, Fits/recherche/filtres, profils et réglages.
   14 tests d’interaction ciblés verts ; suivi explicite des écrans restants.
