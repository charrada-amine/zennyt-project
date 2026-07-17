# Plan 004 : Authentifier les callbacks et rendre les OTP réels

> **Instructions exécuteur** : ne considérer aucun code OTP comme valide sans challenge serveur.
> Ne stocker ni secret de callback ni OTP en clair. Ne toucher à aucune migration existante.
>
> **Drift check** : `git diff --stat 2359b37..HEAD -- backend/src/main/java/com/zennyt/recruitment backend/src/main/resources/db/migration contracts/recruitment.openapi.yaml`

## Statut

- **Priorité** : P1
- **Effort** : L
- **Risque** : HIGH — callbacks externes et confirmation de paiement
- **Dépend de** : plan 003
- **Catégorie** : sécurité, correction
- **Planifié au** : commit `2359b37`, 2026-07-14

## Pourquoi

`CallbackController` reçoit `X-Callback-Secret` mais ne le valide pas. Un faux secret a été accepté
avec 200 et a modifié les données. `VideoConferencePayment.verifyOtp` et
`JobOpportunityOffer.verifyOtp` acceptent actuellement toute chaîne, permettant de confirmer une
opération sans preuve de possession.

## Périmètre

- Contrat Recruitment pour callbacks/OTP.
- Ports et use cases Recruitment pour authentification de callback et OTP.
- Modèles/persistance Recruitment nécessaires.
- Nouvelle migration `V14__recruitment_otp_challenges.sql` après stabilisation de V13.
- Tests unitaires et HTTP Recruitment.

Hors périmètre : modification de V13, fournisseur SMS choisi sans validation, appel direct à
Identity/Engagement, traitement bancaire réel, `pom.xml`.

## Étapes

### 1. Valider le secret avant tout accès repository

Lire le secret depuis la configuration, comparer en temps constant, refuser secret absent/invalide
avant désérialisation métier ou écriture. Refuser le démarrage production si le secret est absent ;
autoriser un profil test avec valeur injectée.

**Vérifier** : absent/invalide = 401/403 et zéro appel repository ; valide = traitement attendu.

### 2. Rendre les callbacks idempotents et contrôlés par état

Un callback répété avec le même résultat doit être sans effet et retourner 200/204. Un callback
contradictoire ou portant sur une ressource terminale doit retourner 409. Valider plages de score,
enums et existence des corrélations.

**Vérifier** : tests duplicate, out-of-order, unknown id, invalid range et terminal conflict.

### 3. Introduire un challenge OTP

Créer un agrégat/VO avec hash du code, finalité, resourceId, destinataire, expiration, nombre
d’essais, consumedAt. Générer avec `SecureRandom`, durée et essais configurables. La nouvelle
migration doit créer une table/index sans modifier V13.

**Vérifier** : tests domaine pour code correct, incorrect, expiré, réutilisé et dépassement d’essais.

### 4. Séparer génération, livraison et vérification

À la création d’un paiement/offre, générer un challenge et publier un Domain Event de livraison.
La livraison effective doit être implémentée par un consommateur autorisé dans un plan séparé si
elle implique Engagement. Sans consommateur configuré, l’environnement production doit rester
bloqué ou la feature désactivée — jamais accepter un code arbitraire.

**Vérifier** : test application prouvant que l’événement ne contient pas le hash persistant et que
la confirmation n’arrive qu’après consommation du challenge.

### 5. Ne pas confondre OTP et paiement

Renommer/documenter l’état pour indiquer que l’OTP autorise seulement l’étape prévue. Ne déclarer
`CONFIRMED` financièrement qu’après callback signé du fournisseur de paiement si un fournisseur
existe. Sinon tracer cette limite dans « Décisions à valider ».

**Vérifier** : aucun test ne simule un débit bancaire inexistant ; la machine à états correspond au contrat.

## Critères de fin

- [ ] Faux secret et secret absent ne mutent jamais les données.
- [ ] Les callbacks sont idempotents et auditables sans journaliser de secret.
- [ ] Un OTP est hashé, expirant, limité en essais et à usage unique.
- [ ] Aucun code arbitraire ne confirme payment/opportunity.
- [ ] V13 est intacte ; seule une nouvelle migration est ajoutée.

## Conditions STOP

- V13 n’est pas encore stabilisée/commitée.
- Le canal de livraison OTP n’est pas choisi.
- Le fournisseur impose une nouvelle dépendance Maven non autorisée.
- La livraison exige de modifier Engagement sans extension explicite du périmètre.

