# Détection de fraude dans l'appel Agora — où j'en suis

*Écrit le 22 août 2026 pour pouvoir reprendre sans relire le code. Complète
`PLAN_FRAUDE_DANS_AGORA.md`, qui dit le **quoi** ; ce document dit **où ça en est**.*

---

## En une phrase

Le code est écrit, éprouvé unitairement et contre le vrai module, et poussé. **Le dernier
maillon — la détection qui tourne pendant un vrai appel — n'est pas vérifié**, faute d'un
second participant.

---

## Où se trouve le travail

| | |
|---|---|
| Branche | `integration-agora-detection-fraude` |
| Dépôt | `amine` — github.com/charrada-amine/zennyt-project |
| Partie de | `IntergrationV1` au commit `ce96791` |
| Dernier commit | `f3ad3c6` |

Partie de leur branche à dessein : la différence ne porte que sur l'intégration, elle se
relit sans démêler mon travail du leur.

**Le module `fraud-detection/` reste hors du dépôt** — décision du 22 août, en attendant la
réunion avec l'équipe Engagement. Il vit sur ma machine : 19 fichiers Python, 3 de test.
À committer sans les modèles dès qu'une décision est prise, quelle qu'elle soit.

### Les trois commits

| Commit | Contenu |
|---|---|
| `48c171b` | Le cœur : consentement, dérivation audio, découpage, transport |
| `bc87534` | Le banc d'essai rendu atteignable, sous `kDebugMode` |
| `f3ad3c6` | L'adresse du WebSocket temps réel, qui était celle d'une machine |

---

## Ce qui est fait, et comment je le sais

### Les pièces

| Fichier | Rôle |
|---|---|
| `domain/services/speech_segmenter.dart` | Découpe le flux en phrases, dans les silences. Port de `vad.js`, constantes comprises |
| `data/datasources/fraud_audio_datasource.dart` | Ouvre la salle, enregistre l'accord, envoie les phrases en WAV |
| `presentation/services/fraud_detection_service.dart` | Relie Agora aux deux précédents |
| `presentation/widgets/call_consent_gate.dart` | L'écran bloquant, avant l'appel |

### Les preuves, pas les impressions

- **12 tests** — dont celui qui vérifie que le découpage **ne dépend pas de la taille des
  tampons** qu'Agora livre, ce qui est le piège de ce genre de portage.
- **Le WAV produit en Dart relu par le vrai décodeur du module** (PyAV) : 1,0 s exactement,
  float32 mono 16 kHz. Le contrat tient entre les deux langages.
- **Le protocole rejoué contre le module en marche** —
  `docs/fraude/verif_protocole_mobile.py` : `join`, consentement, accusé de 38 444 octets,
  date de purge fixée à la réception.
- **Sur l'émulateur** : écran de consentement affiché avant l'appel, permission micro
  demandée **après** l'accord, session d'appel créée côté serveur (`callId` non nul).

### Trois choses vérifiées plutôt que supposées

1. **Le SDK Flutter livre-t-il vraiment les octets audio ?** Oui —
   `AudioFrameBufferExt.fillBuffers` attache un `Uint8List` réel avant le rappel. Beaucoup
   d'enrobages ne transportent que les métadonnées ; celui-ci non.
2. **Le serveur doit-il changer ?** Non, **pas une ligne**. Le plan en annonçait une : PyAV
   sonde le contenu, donc l'extension `.webm` que le serveur impose n'empêche pas de lire
   un WAV.
3. **Quels rôles accepte le module ?** `candidate` et `recruiter`, en anglais. En français
   il répond « rôle inconnu ». Mon premier jet se serait fait refuser.

---

## Ce qui n'est PAS vérifié — le point à reprendre

**`onRecordAudioFrame` n'a jamais tourné sur un vrai appel.** Donc la chaîne complète —
micro → découpage → envoi → détection — n'a pas été observée de bout en bout.

### Pourquoi

Dans leur flux, pour un appel **sortant**, `_joinAgoraChannel()` n'est pas appelé au
démarrage : seulement quand l'autre partie répond (`call_page_controller.dart`, lignes 346
et 359). Seul dans le canal, `onJoinChannelSuccess` ne se déclenche jamais — donc ni leur
enregistrement ni ma détection ne démarrent.

**C'est leur conception, pas un défaut**, et ça vaut pour les deux fonctionnalités.

### Comment le finir

Deux voies, la seconde plus rapide :

1. **Un second appareil** — autre émulateur ou téléphone, autre compte, qui **accepte**
   l'appel. C'est le cas nominal.
2. **Tester le sens entrant** — pour un appel *reçu*, `_joinAgoraChannel()` est appelé
   immédiatement à l'initialisation (ligne 171). La détection démarrerait donc dès
   l'ouverture de l'écran, sans attendre personne.

La seconde voie est celle à essayer en premier : elle ne demande qu'un appareil.

---

## Comment relancer l'environnement

```
# 1. Le module de detection
cd fraud-detection && .\run.ps1              # http://localhost:8800

# 2. Le backend Zennyt
cd backend && ./mvnw spring-boot:run          # profil dev, port 8080

# 3. L'emulateur, puis
cd mobile && flutter run -d emulator-5554
```

`mobile/.env` porte tout ce qu'il faut : `API_BASE_URL`, `FRAUD_WS_URL`, et les
identifiants Agora. **Il n'est pas versionné, et ne doit pas l'être.** Le jeton Agora du
22 août était valable 24 h — il faut en redemander un.

### Le parcours de test

1. Réglages → **Banc d'essai (debug)**
2. Remplacer l'identifiant de conversation par un vrai UUID (voir ci-dessous)
3. **Connecter**, puis **Appel Audio**
4. Accepter le consentement
5. Regarder : `adb logcat -s flutter | findstr Fraude`
6. Les alertes arrivent sur <http://localhost:8800/moderation>

### La conversation de test

La page de test envoie `conv-test-001`, qui n'est pas un UUID : `/calls/start` refuse. J'ai
créé une conversation en base pour contourner :

```sql
INSERT INTO engagement.conversations
  (id, application_id, job_offer_id, candidate_id, recruiter_id, job_title,
   candidate_unread_count, recruiter_unread_count, version)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', gen_random_uuid(), gen_random_uuid(),
        '<public_id du candidat>', '<public_id du recruteur>',
        'Entretien de demonstration', 0, 0, 0);
```

Les identifiants se lisent dans `public.users.public_id` — **`public_id`, pas `id`** : c'est
l'UUID que porte le jeton.

---

## Ce que j'ai trouvé chez eux en chemin

Aucun de ces trois défauts n'était visible avant d'essayer de s'en servir. Ils sont corrigés
sur la branche, mais **ils leur appartiennent** : à leur signaler, pas à leur imposer.

| Défaut | Portée |
|---|---|
| L'adresse du WebSocket temps réel codée en dur sur `192.168.100.4` | **Messagerie, appels entrants et notifications tombent ensemble** sur toute autre machine, et en production. La dérivation correcte était commentée juste au-dessus |
| Le dépôt d'un fragment d'enregistrement ne vérifie pas qui dépose | `UploadCallRecordingChunkUseCase` reçoit `(sessionId, sequenceNumber, file)` ; le `Principal` est déclaré au contrôleur mais jamais transmis. **Non corrigé** — c'est leur code, et je n'ai pas pu le tester |
| Aucune durée de conservation des enregistrements | Les fragments MP4 partent vers le stockage et y restent. **Non corrigé** |

Et un rappel qui ne dépend d'aucune décision : **la clé Cloudinary est dans l'historique
d'`IntergrationV1` depuis le 28 juin**. Elle n'est jamais entrée dans `main`, mais elle est
publique sur GitHub. À révoquer.

---

## Ce qui reste à trancher, et qui n'est pas technique

1. **Où atterrissent les alertes.** Aucune interface d'administration n'existe. Trois
   fonctionnalités attendent le même back-office : la modération de fraude, l'approbation
   des métiers, l'escalade du centre d'aide.
2. **Le refus d'un participant** — continuer sans enregistrer (défaut actuel), ou bloquer
   l'entretien. Les deux sont implémentés, un réglage suffit.
3. **La rétention chez le fournisseur de qualification.** Deux adaptateurs prêts.
4. **Qui héberge le module Python.** Il ne peut pas être réécrit en Java.

---

## Le reste du plan, non commencé

| Étape du plan | État |
|---|---|
| 0 — Consentement | **fait** |
| 1 — Identifiant de session propre | **non fait** — `channelName` retombe encore sur `AGORA_TEST_CHANNEL` en premier, donc tous les appels partagent un canal |
| 2 — Dérivation audio | fait, non éprouvé en appel |
| 3 — Découpage en Dart | **fait**, 8 tests |
| 4 — Transport | **fait**, protocole vérifié |
| 5 — Jeton d'accès au module | **non fait** — `/ws/audio` n'exige rien d'autre que l'existence de la session |
| 6 — Back-office | à décider |

L'étape 5 est la plus importante des deux restantes : tant qu'elle n'est pas faite, le
module ne doit écouter que sur `localhost`.

---

*Squad Recrutement — Ghassen Bousselem*
