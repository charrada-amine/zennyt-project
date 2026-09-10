# -*- coding: utf-8 -*-
"""Vérification bout en bout du centre d'aide — étape 1.

Le circuit complet : ouvrir une conversation, écrire, relire, noter, commenter.
Et surtout le cas qui compte : un utilisateur ne doit pas pouvoir noter la
conversation d'un autre.
"""
import json, urllib.request, urllib.error, uuid

BASE = "http://localhost:8080/api/v1"


def call(path, method="GET", body=None, token=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")[:200]


def compte(role="CANDIDATE"):
    status, tok = call("/auth/register", "POST", {
        "firstName": "T", "lastName": "U",
        "email": f"help-{uuid.uuid4().hex[:8]}@zennyt.local",
        "password": "zennyt123", "role": role, "city": "Tunis",
        "country": "Tunisie", "termsAccepted": True})
    assert status == 201, (status, tok)
    return tok["accessToken"]


ok = True


def verifier(libelle, condition, detail=""):
    global ok
    ok = ok and condition
    print(f"  [{'OK ' if condition else 'ECHEC'}] {libelle}{('  -> ' + str(detail)) if detail else ''}")


alice = compte()
bob = compte()

print("1. Ouvrir une conversation")
st, chat = call("/help-chats", "POST", {"title": "Probleme de connexion",
                                        "subtitle": "Compte"}, token=alice)
verifier("HTTP 201", st == 201, st)
verifier("titre conserve", chat.get("title") == "Probleme de connexion")
verifier("pas encore notee", chat.get("rating") is None)
chat_id = chat["id"]

print("\n2. Ouvrir sans titre — les valeurs de repli s'appliquent")
st, generique = call("/help-chats", "POST", None, token=alice)
verifier("HTTP 201", st == 201, st)
verifier("titre de repli", generique.get("title") == "Assistance", generique.get("title"))

print("\n3. Envoyer un message")
st, message = call(f"/help-chats/{chat_id}/messages", "POST",
                   {"text": "Je n'accede pas a ma liste."}, token=alice)
verifier("HTTP 201", st == 201, st)
verifier("attribue a l'utilisateur", message.get("isFromUser") is True)

print("\n4. Relire la conversation")
st, messages = call(f"/help-chats/{chat_id}/messages", token=alice)
verifier("HTTP 200", st == 200, st)
verifier("le message est la", len(messages) == 1, f"{len(messages)} message(s)")

print("\n5. La conversation apparait dans la liste, horodatee")
st, liste = call("/help-chats", token=alice)
mienne = next((c for c in liste if c["id"] == chat_id), None)
verifier("presente dans la liste", mienne is not None)
verifier("lastMessageAt renseigne", mienne and mienne.get("lastMessageAt") is not None,
         mienne.get("lastMessageAt") if mienne else None)

print("\n6. Noter l'echange")
st, notee = call(f"/help-chats/{chat_id}/rating", "POST", {"rating": "GREAT"}, token=alice)
verifier("HTTP 200", st == 200, st)
verifier("note enregistree", notee.get("rating") == "GREAT", notee.get("rating"))
verifier("date de notation posee", notee.get("ratedAt") is not None)
verifier("pas de commentaire", notee.get("ratingComment") is None)

print("\n7. Ajouter le commentaire (le formulaire s'ouvre apres la note)")
st, commentee = call(f"/help-chats/{chat_id}/rating", "POST",
                     {"rating": "GREAT", "comment": "J'apprecie votre service"}, token=alice)
verifier("commentaire enregistre",
         commentee.get("ratingComment") == "J'apprecie votre service",
         commentee.get("ratingComment"))

print("\n8. Une note invalide est refusee")
st, _ = call(f"/help-chats/{chat_id}/rating", "POST", {"rating": "EXCELLENT"}, token=alice)
verifier("HTTP 4xx", 400 <= st < 500, st)

print("\n9. LE TEST QUI COMPTE — Bob ne peut pas toucher la conversation d'Alice")
st, _ = call(f"/help-chats/{chat_id}/rating", "POST",
             {"rating": "POOR", "comment": "sabotage"}, token=bob)
verifier("notation refusee", st == 404, st)
st, _ = call(f"/help-chats/{chat_id}/messages", "POST", {"text": "intrusion"}, token=bob)
verifier("envoi refuse", st == 404, st)
st, messages_bob = call(f"/help-chats/{chat_id}/messages", token=bob)
verifier("lecture refusee ou vide",
         st == 404 or messages_bob == [], st)
st, liste_bob = call("/help-chats", token=bob)
verifier("absente de la liste de Bob",
         all(c["id"] != chat_id for c in liste_bob), len(liste_bob))

print("\n10. La note d'Alice est intacte")
st, apres = call(f"/help-chats", token=alice)
mienne = next((c for c in apres if c["id"] == chat_id), None)
verifier("toujours GREAT", mienne and mienne.get("rating") == "GREAT",
         mienne.get("rating") if mienne else None)

print()
print("=" * 60)
print("RESULTAT :", "tout est vert" if ok else "AU MOINS UNE VERIFICATION A ECHOUE")
