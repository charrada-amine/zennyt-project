# Brancher la détection de fraude sur l'appel vidéo Agora

*Plan établi le 22 août 2026 sur l'état réel du dépôt et du module. Le module vit
aujourd'hui hors du dépôt ; l'appel Agora appartient à l'équipe Engagement.*

*Vérifié contre `amine/IntergrationV1` au commit `ce96791` du 20 août : les quatre fichiers
qui portent l'appel — le contrôleur de page, le service d'enregistrement, le client de dépôt
des fragments et le `CallController` côté serveur — y sont **identiques** à ceux sur
lesquels ce plan est bâti. La version d'Agora est inchangée (`6.6.3`). Rien à réviser.*

---

## 1. Ce qui rend l'intégration possible

Trois faits, vérifiés dans le code, qui décident du reste :

**a) Agora sait rendre l'audio brut sur Flutter.** Le SDK `agora_rtc_engine 6.6.3` expose
`registerAudioFrameObserver` avec un rappel `onRecordAudioFrame` — le microphone local,
**avant mixage** — et `setRecordingAudioFrameParameters` permet de demander directement le
format voulu. Ce n'est donc pas un contournement : c'est une API prévue pour ça.

Le point qui méritait d'être vérifié plutôt que supposé : **les octets arrivent-ils vraiment
jusqu'à Dart ?** Beaucoup d'enrobages Flutter transportent les métadonnées d'une trame audio
sans son contenu. Ici non — `AudioFrameBufferExt.fillBuffers` attache un `Uint8List` réel à
l'`AudioFrame` avant que le rappel ne se déclenche. Le chemin est praticable, pas seulement
plausible.

**b) Le format demandé est exactement celui du pipeline.** Le pipeline travaille en
**mono 16 kHz**. `setRecordingAudioFrameParameters(16000, 1, …)` livre précisément cela :
aucun rééchantillonnage, ni sur le téléphone ni sur le serveur.

**c) Le serveur accepte déjà n'importe quel conteneur.** `decode_to_mono16k` passe par
PyAV, qui lit tout ce que ffmpeg lit. Le navigateur envoie du `.webm/opus` ; le téléphone
enverra du WAV — un en-tête de 44 octets autour du PCM. **Le pipeline ne change pas.**

Conséquence importante pour l'estimation : le gros du travail est **côté mobile**. Le
serveur de détection reste presque tel quel.

---

## 2. Ce qui ne bouge pas

| | |
|---|---|
| Agora | reste le transport de l'appel — on ne le remplace pas |
| Le pipeline de détection | STT, filtre, qualification, décision : inchangés |
| Le protocole d'ingestion | `WS /ws/audio/{session_id}?role=…` : une trame texte `{seq, started_at}` puis une trame binaire |
| Le module Python | reste un service séparé — voir §6 |

Le module a été écrit autonome pour être contesté avant d'être branché. Cette autonomie
devient un avantage : l'intégration consiste à lui **parler**, pas à le fondre dans le
backend Spring.

---

## 3. Les étapes, dans l'ordre où elles doivent être faites

### Étape 0 — Le consentement, à faire même si tout le reste est repoussé

**C'est l'étape la plus importante et la plus indépendante.** Aujourd'hui, le mot
« consentement » n'apparaît nulle part dans le code d'appel : l'enregistrement démarre à
`onJoinChannelSuccess` sans que personne ait accepté quoi que ce soit.

Ce que le module fournit déjà : écran bloquant avant tout accès au micro, clic actif exigé
à **chaque** session, enregistrement qui ne démarre qu'après l'accord des **deux** parties,
et journalisation par rôle du délai de réflexion.

Ce qu'il faut faire côté mobile : insérer cet écran **avant** `joinChannel`, et ne déclencher
`_startRecordingIfNeeded()` qu'une fois l'accord des deux côtés reçu.

> Cette étape corrige une exposition juridique qui existe **aujourd'hui**, indépendamment de
> la détection de fraude. Elle vaut d'être livrée seule si le reste attend.

### Étape 1 — Corriger l'identifiant de session

`channelName` vaut aujourd'hui :

```
dotenv.env['AGORA_TEST_CHANNEL'] ?? conversationId ?? 'call_<timestamp>'
```

La variable d'environnement passe **en premier**. Dans toute installation où elle est
renseignée, **tous les appels partagent le même canal** — et donc la même session côté
détection. Tant que ce raccourci de test est là, rien de ce qui suit n'est traçable.

Le module a besoin d'un identifiant stable et unique par entretien. Le plus naturel est
l'identifiant de `CallSession`, déjà créé par `POST /calls/start`.

### Étape 2 — La dérivation audio sur le téléphone

Le cœur technique. Dans `CallPageController`, une fois le canal rejoint et le consentement
obtenu :

```dart
await engine.setRecordingAudioFrameParameters(
  sampleRate: 16000, channel: 1,
  mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadOnly,
  samplesPerCall: 1024);

engine.getMediaEngine().registerAudioFrameObserver(
  AudioFrameObserver(onRecordAudioFrame: (channelId, frame) {
    segmenteur.pousser(frame.buffer);   // voir étape 3
  }));
```

`onRecordAudioFrame` donne **le micro local uniquement**. C'est exactement ce qu'il faut :
le dispositif actuel envoie déjà une piste par participant, sur sa propre connexion, avec
son propre rôle. Chacun reste responsable de son propre consentement.

### Étape 3 — Porter le découpage par silences en Dart

**C'est le vrai travail de cette intégration**, et la seule partie qu'on ne peut pas
recycler : `vad.js` est écrit pour l'`AudioContext` du navigateur.

Ce qu'il fait, et qu'il faut refaire à l'identique : mesurer l'énergie du signal toutes les
50 ms, apprendre le bruit de fond dans les silences, déclarer « ça parle » après 120 ms de
son continu, et **couper uniquement dans un silence de 700 ms, une fois une phrase
prononcée**.

Pourquoi ne pas découper à intervalle fixe, ce qui serait trivial : une coupure au milieu
d'une phrase oblige soit à recoller le texte après coup, soit — pire — à demander aux gens
de marquer des pauses artificielles. Un entretien doit se parler normalement. Les
constantes sont déjà réglées et éprouvées ; il s'agit de les transposer, pas de les
retrouver.

Bonne nouvelle : en Dart on reçoit du PCM brut, donc le calcul d'énergie est plus simple
qu'en JavaScript — pas d'`AnalyserNode`, une moyenne quadratique sur le tampon suffit.

### Étape 4 — Le transport

Une WebSocket depuis le téléphone vers le module, **au même protocole que le navigateur** :
une trame texte `{"seq": n, "started_at": "…"}`, puis la trame binaire du segment.

Le segment est du PCM 16 kHz mono ; on lui ajoute un en-tête WAV de 44 octets avant
l'envoi. Côté serveur, seule la ligne qui fixe l'extension du fichier change.

**Le volume, à surveiller.** Le PCM 16 kHz 16 bits pèse 32 Ko/s. Le découpage par silences
n'envoie que la parole, ce qui retire déjà une bonne moitié d'un entretien réel — comptons
environ **1 Mo par minute de parole**. Acceptable en Wi-Fi, sensible en 4G. Si la mesure le
confirme sur un vrai entretien, encoder en Opus avant l'envoi divise ce chiffre par dix ;
c'est une optimisation à faire *après* avoir mesuré, pas avant.

### Étape 5 — Authentifier la connexion

Aujourd'hui `/ws/audio/{session_id}` n'exige rien d'autre que l'existence de la session :
c'était suffisant pour un banc d'essai en local, ça ne l'est plus dès que le module écoute
autre chose que `localhost`.

Le plus simple et le plus cohérent avec le reste de la plateforme : le backend Spring
délivre un jeton court, lié à `(callId, userId, rôle)`, que le téléphone présente à
l'ouverture de la WebSocket et que le module vérifie. Le module n'a pas besoin de connaître
les comptes Zennyt — seulement de vérifier une signature.

### Étape 6 — Les alertes doivent arriver quelque part

Le module produit des extraits destinés à un humain. Sa console de modération est protégée
par un simple jeton partagé : utilisable en démonstration, pas en production.

**C'est la seule étape que je ne peux pas planifier seul** — voir §5.

---

## 4. Ce que ça donne, bout à bout

```
téléphone                          module de détection            back-office
─────────                          ───────────────────            ───────────
consentement (étape 0)
      │
      ├──▶ Agora : l'appel, inchangé
      │
      └──▶ onRecordAudioFrame
             │  PCM 16 kHz mono
             ▼
        découpage par silences (étape 3)
             │  un segment = une phrase
             ▼
        WS /ws/audio/{callId}?role=  ──────▶  STT local ×2
                                              filtre regex / NER
                                              extrait minimisé ──▶ qualification
                                              décision
                                                   │
                                                   └──▶ alerte ──▶ ???  (§5)
```

L'audio ne quitte jamais le serveur de détection : seul un extrait de texte d'environ
240 caractères, noms et chiffres masqués, part vers le service de qualification.

---

## 5. Ce qui n'est pas technique et qu'il faut trancher

1. **Où atterrissent les alertes.** Aucune interface d'administration n'existe dans le
   projet. Trois fonctionnalités attendent désormais le même back-office : la modération de
   fraude, l'approbation des métiers, et l'escalade du centre d'aide. Sans lui, chacune
   produit une file d'attente que personne ne lit.

2. **Le refus d'un participant.** Par défaut : continuer l'entretien **sans aucun
   enregistrement**. L'autre option — bloquer l'entretien — est implémentée et s'active par
   configuration.

3. **La rétention chez le fournisseur de qualification.** Écart de coût négligeable à ce
   volume ; le critère est l'engagement contractuel de non-conservation. Deux adaptateurs
   sont prêts.

4. **Qui héberge le module Python.** Il ne peut pas être réécrit en Java : faster-whisper,
   Vosk et spaCy n'ont pas d'équivalent sur la JVM. Il restera donc un service à part, avec
   son déploiement, sa supervision et son coût. C'est une décision d'infrastructure, pas de
   code.

---

## 6. Pourquoi le module reste un service séparé

La question se posera, autant y répondre d'avance.

Le fondre dans le backend Spring supposerait de réécrire la transcription, la
reconnaissance d'entités et le filtrage — soit des mois, pour un résultat moins bon que des
bibliothèques éprouvées. Le garder à part coûte un service de plus à déployer, et impose de
définir un contrat entre les deux. C'est le moindre des deux prix.

Cela a un avantage qu'il faut souligner : **si le module tombe, l'entretien continue**. La
détection est un observateur, jamais un passage obligé du chemin de l'appel. Aucune panne de
la détection ne doit empêcher deux personnes de se parler — et l'architecture actuelle le
garantit par construction.

---

## 7. Les plateformes, qui ne se comportent pas toutes pareil

L'application déclare six cibles, et Windows n'est pas décoratif : l'équipe a écrit tout un
document (`FIX_agora_windows_iris_sdk.md`) pour débloquer la compilation d'Agora dessus.

| Cible | Comment l'audio se dérive | Remarque |
|---|---|---|
| Android, iOS | `onRecordAudioFrame` (§3, étape 2) | le chemin nominal |
| Windows, macOS, Linux | même API | à **vérifier** ; la compilation d'Agora sur Windows demande déjà le Mode développeur et un SDK Iris pré-extrait |
| Web | **rien à écrire** | le module a déjà son code navigateur — `vad.js` et la WebSocket tournent tels quels |

Le cas du web mérite d'être souligné : sur cette cible, l'intégration est **déjà faite**. Le
découpage par silences et le transport existent depuis le banc d'essai ; il suffit de les
brancher sur le flux micro de la page d'appel plutôt que sur celui de la salle de
démonstration. L'étape 3 — la plus lourde — ne concerne que les cibles natives.

Recommandation : livrer d'abord sur **Android**, où l'application est réellement utilisée et
où j'ai vérifié le SDK. Les autres cibles suivent, chacune avec sa vérification propre.

---

## 8. Estimation

| Étape | Nature | Durée |
|---|---|---|
| 0 — Consentement dans le flux d'appel | Flutter + une route | 1 à 2 j |
| 1 — Identifiant de session propre | Correctif | 0,5 j |
| 2 — Dérivation audio Agora | Flutter | 1 j |
| 3 — Découpage par silences en Dart | **Flutter, le vrai morceau** | **2 à 3 j** |
| 4 — Transport WebSocket + WAV | Flutter + 1 ligne serveur | 1 j |
| 5 — Jeton d'accès au module | Spring + module | 1 j |
| 6 — Back-office de modération | **à décider** | — |

**Environ 6 à 8 jours** de travail technique, hors back-office.

L'étape 0 est livrable seule et devrait l'être en premier, quelle que soit la décision sur
le reste.

---

## 9. Comment vérifier que ça marche

Le module contient déjà de quoi le prouver, et il faut s'en servir plutôt que d'inventer
une recette :

- les six phrases de test du README, qui couvrent le numéro dicté, le canal externe,
  l'e-mail épelé, la formulation indirecte, **le faux positif à rattraper** et la phrase
  anodine ;
- `GET /api/compliance`, qui renvoie les six règles du cahier des charges avec leur preuve
  mesurée sur l'instance en cours ;
- les deux cas qui comptent vraiment : « entre nous, on peut régler ça directement » — que
  le filtre seul manquerait — et « j'ai appelé le support au zéro un… » — que le filtre seul
  signalerait à tort.

Le critère d'acceptation de cette intégration n'est pas « ça détecte », c'est **« ça détecte
depuis un téléphone aussi bien que depuis le navigateur »** : le même jeu de phrases, dit
dans l'application, doit produire les mêmes scores qu'en démonstration navigateur.

---

*Squad Recrutement — Ghassen Bousselem*
