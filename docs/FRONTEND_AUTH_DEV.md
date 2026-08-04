# Authentification en profil `dev` — Guide Frontend

> **Contexte** : le backend Zennyt tourne en local avec le profil Spring `dev`.
> Le contexte Identity (login réel) n'est pas encore mergé. On simule l'utilisateur connecté
> avec un simple header HTTP — aucun token JWT requis.

---

## TL;DR

| Ce que tu dois envoyer | Valeur |
|---|---|
| Header optionnel | `X-Dev-User: <uuid>` |
| Token Bearer | **rien** — pas nécessaire en dev |
| CORS | **ouvert** sur toutes les origines |

---

## Comment fonctionne la simulation

En profil `dev`, un filtre Spring (`DevAuthFilter`) s'exécute **avant chaque requête** et
injecte automatiquement un utilisateur authentifié dans le contexte de sécurité.

- **Sans header** → tu es le **candidat de démo** par défaut.
- **Avec `X-Dev-User: <uuid>`** → tu es l'utilisateur correspondant à cet UUID.

```
┌─────────────────────────────────────────────────────┐
│  Ta requête HTTP                                    │
│                                                     │
│  GET /api/v1/candidates/me/matches                  │
│  X-Dev-User: 22222222-2222-2222-2222-222222222222   │
│                                                     │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
          DevAuthFilter (profil dev)
          lit le header X-Dev-User
                     │
                     ▼
       SecurityContext ← userId = "22222222-..."
       Rôles : ROLE_DEV, ROLE_CANDIDATE, ROLE_RECRUITER
                     │
                     ▼
          Controller → principal.getName()
          retourne l'UUID injecté
```

---

## Les deux identités de démo

| Rôle | Header à envoyer |
|---|---|
| **Candidat** (défaut) | `X-Dev-User: 22222222-2222-2222-2222-222222222222` |
| **Recruteur** | `X-Dev-User: 11111111-1111-1111-1111-111111111111` |

> En pratique, si tu ne mets pas le header du tout, tu es automatiquement le candidat.
> Le header est utile pour tester les routes recruteur ou pour basculer entre les deux rôles.

---

## Règle importante sur l'acteur

**L'acteur (qui fait l'action) vient toujours du header, jamais du body.**

Exemple — un candidat swipe une offre à droite :

```http
POST /api/v1/swipes
X-Dev-User: 22222222-2222-2222-2222-222222222222   ← qui swipe (candidat)

{
  "targetId": "<uuid-de-l-offre>",
  "targetType": "JOB_OFFER",
  "direction": "LIKE"
}
```

Le backend lit `candidateId` depuis le header (via `principal.getName()`), pas depuis le body.
→ Ne jamais envoyer `candidateId` ou `recruiterId` dans le JSON des requêtes.

---

## CORS en profil `dev`

Toutes les origines sont autorisées (`*`). Tu peux appeler le backend depuis :
- Flutter Web (`localhost:quelconque`)
- Un navigateur directement
- Postman / Bruno / Insomnia

Méthodes autorisées : `GET POST PUT PATCH DELETE OPTIONS`
Headers autorisés : tous (`*`)

---

## Ce qui changera en prod

En production, le header `X-Dev-User` n'existe plus. Le backend devient un **OAuth2 Resource Server** :
- Chaque requête doit porter un **JWT Bearer token** émis par le contexte Identity.
- Le backend lit le `sub` claim du JWT — c'est l'UUID de l'utilisateur.
- Aucun changement dans la logique métier ni dans les endpoints : le `principal.getName()`
  des contrôleurs retournera l'UUID du JWT exactement comme il retourne celui du header en dev.

---

## Résumé des headers à configurer dans ton client HTTP

```
# Pour toutes tes requêtes en dev :
Content-Type: application/json
X-Dev-User: 22222222-2222-2222-2222-222222222222   # candidat (ou l'UUID recruteur selon le test)

# NE PAS ajouter :
# Authorization: Bearer ...   → inutile en dev, ignoré
```
