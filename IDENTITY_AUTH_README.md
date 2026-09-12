# Identity — authentification et profils mobiles

**Dernière mise à jour : 2026-09-11**

## Périmètre et référence

Document créé avec l’autorisation de l’utilisateur lors de la refonte de `mobile/`.
Il décrit les frontières à préserver pendant cette refonte. Le contrat existant
dans `contracts/` reste la référence des opérations backend ; aucune évolution
d’API n’est prévue ici. `docs/FRONTEND_AUTH_DEV.md` décrit un ancien fonctionnement
dev par header et ne doit pas remplacer l’implémentation actuelle par tokens.

## Arborescence mobile

- `features/auth/data/auth_repository_impl.dart` : appels Dio, persistance des
  tokens et chargement de l’utilisateur courant.
- `features/auth/domain/` : utilisateur et port de repository.
- `features/auth/presentation/` : contrôleur de session, providers, login,
  inscription, OTP et récupération du mot de passe.
- `features/profile_setup/` : rôle, domaine professionnel et finalisation du profil.
- `features/profile_settings/` : profils candidat/recruteur, édition, réglages et CV.
- `features/onboarding/`, `features/splash/` : entrée dans l’application.
- `shared/widgets/` : boutons, champs, en-têtes, sélection de rôle, logo et dialogues.
- `core/router/`, `core/network/`, `core/storage/` : navigation, authentification
  HTTP et stockage partagé ; changements visuels transversaux autorisés pour la refonte.

## Parcours et statut

| Parcours | État observé avant refonte |
| --- | --- |
| Login et inscription | Écrans existants, repository Dio et contrôleur Riverpod |
| Inscription | Données conservées dans le viewmodel jusqu’à la fin du profil |
| Mot de passe oublié | Écrans méthode, e-mail et OTP ; SMS marqué indisponible |
| Profil et réglages | Écrans existants, variantes candidat et recruteur |
| CV | Capture, traitement OCR/API, revue et affichage existants |

## Zones protégées

- Gardes de navigation, restauration de session, token storage et refresh.
- Validation des champs, consentement explicite aux conditions, rôles et identités.
- Contrats, repositories, payloads et comportement des endpoints.
- Les actions indisponibles ne doivent pas simuler une authentification réussie.
- Le mode de démonstration Lot 1 et ses restrictions restent la règle existante.
- Aucun changement de dépendance ou de schéma de base de données **sans autorisation
  explicite**. Exception tracée : la table `user_preferences` (migration V77) a été ajoutée
  le 2026-09-11 avec l'accord de l'utilisateur, pour les préférences synchronisées.

## Refonte et décisions à valider

Direction de présentation autorisée : voir `docs/MOBILE_REDESIGN.md`.
Réutiliser les widgets partagés, conserver les textes localisés, introduire des
surfaces plus aérées et des retours visuels/haptiques respectant l’accessibilité.
L’état des intégrations externes et des fonctions actuellement indisponibles reste
à vérifier séparément ; la refonte ne constitue pas une validation de celles-ci.

## Validation et roadmap

Refonte en cours. Vérifier les formulaires, erreurs, chargements, navigation,
tailles d’écran, texte agrandi et modes clair/sombre. 10 tests ciblés socle/auth et profils/réglages sont verts ; la suite complète
et la vérification de tous les parcours restent à effectuer. Aucun barème métier dans ce périmètre.

## Présentation réalisée

- AuthHeader, PrimaryButton, AppTextField, logo SVG et chargeur partagés : mouvement
  réduit pris en compte, états désactivés/chargement, retours haptiques existants.
- Login, inscription, OTP et récupération e-mail : hiérarchie et surfaces renouvelées.
- Onboarding : progression visible et étape suivante accessible sur chaque page.
- `ProfileIdentityCard` dans `profile_header_section.dart` : carte commune aux profils
  candidat, recruteur et réglages ; édition et visibilité conservées.
- `SettingsMenuList(recruiter: ...)` : un menu partagé remplace les deux duplications.
- `LanguageSettingsScreen` : sélection accessible, persistance existante et retour
  haptique, animation respectant la réduction du mouvement.

Décisions de présentation à valider visuellement : les boutons antérieurement sans
handler sont indiqués indisponibles ; les raccourcis non implémentés restent en bas
des réglages. Les valeurs de démonstration du profil recruteur (société, lieu,
« Verified », biographie fictive) sont remplacées par des états sans données.
Les réglages notifications/consentement qui ne persistaient pas auparavant restent
un point d’intégration ouvert, sans prétendre modifier un réglage serveur.

## Changelog

1. **2026-09-07** — Création du document de référence manquant, inventaire mobile
   et invariants de session/profil pour la refonte autorisée.

2. **2026-09-08** — Refonte auth/onboarding, identité des profils, menus communs
   et langue. 10 tests ciblés verts ; session, tokens, contrats et repositories
   inchangés. Édition/CV et autres écrans encore à poursuivre.

3. **2026-09-11** — Préférences d'application synchronisées :
   `GET/PUT /users/me/preferences` (notifications + accessibilité : contraste, taille de
   texte), table `user_preferences` (migration V77, ajout de schéma explicitement
   autorisé). Contrat identity porté à 48 opérations (parité runtime vérifiée) ; tests
   domaine + mise à jour des tests IdentityService qui construisaient le service. Côté
   mobile, les réglages lisent/écrivent ces préférences (les providers locaux restent la
   source d'affichage instantané et du redimensionnement global du texte) ; synchro
   serveur best-effort, repli local hors-ligne.

4. **2026-09-11** — Changement d'e-mail / de téléphone confirmé par OTP :
   `POST /users/me/email`, `/email/verify`, `/users/me/phone`, `/phone/verify`
   (table `account_change_codes`, migration V78 ; contrat identity porté à 52 opérations).
   **Décision : le SMS n'est pas intégré — les deux types de code sont livrés par e-mail
   (Resend)**, y compris le changement de téléphone, faute de fournisseur SMS. Le code
   reste hashé SHA-256, TTL 10 min, 5 tentatives. Côté mobile, `PersonalInformationsScreen`
   ouvre le dialogue OTP quand l'e-mail/le téléphone change, puis un écran « Changes saved ».
   Le canal SMS reste une décision à valider (fournisseur + module de résolution
   destinataire → numéro).

5. **2026-09-11** — Option de développement pour ignorer la vérification à l'inscription :
   `SKIP_SIGNUP_VERIFICATION=true` (via `--dart-define` ou `mobile/.env`, gitignoré). L'écran
   OTP d'inscription est purement visuel (le backend n'expose aucune vérification e-mail/SMS
   à l'enregistrement), donc le flag route directement vers la configuration du profil.
   **À ne jamais activer en production.**
