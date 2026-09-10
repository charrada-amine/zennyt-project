# -*- coding: utf-8 -*-
"""L'assistant documentaire, en conditions réelles.

Trois choses à prouver : il répond aux questions du corpus, il cite sa source, et
il avoue son ignorance quand la question en sort.
"""
import json, time, urllib.request, urllib.error, uuid

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


def compte(role):
    st, tok = call("/auth/register", "POST", {
        "firstName": "T", "lastName": "U",
        "email": f"agent-{uuid.uuid4().hex[:8]}@zennyt.local",
        "password": "zennyt123", "role": role, "city": "Tunis",
        "country": "Tunisie", "termsAccepted": True})
    assert st == 201, (st, tok)
    return tok["accessToken"]


def demander(token, question, attente=14):
    """Pose une question et attend la réponse de l'assistant."""
    st, chat = call("/help-chats", "POST", None, token=token)
    assert st == 201, (st, chat)
    st, _ = call(f"/help-chats/{chat['id']}/messages", "POST",
                 {"text": question}, token=token)
    assert st == 201

    for _ in range(attente):
        time.sleep(1)
        st, messages = call(f"/help-chats/{chat['id']}/messages", token=token)
        if st == 200 and any(not m["isFromUser"] for m in messages):
            return next(m["text"] for m in messages if not m["isFromUser"])
    return None


ok = True


def verifier(libelle, condition, detail=""):
    global ok
    ok = ok and condition
    marque = "OK " if condition else "ECHEC"
    print(f"  [{marque}] {libelle}")
    if detail:
        print(f"         {detail}")


candidat = compte("CANDIDATE")
recruteur = compte("RECRUITER")

print("1. Question d'un candidat sur son Fit Score")
r = demander(candidat, "Pourquoi mon Fit Score est vide sur une offre ?")
verifier("l'assistant a repondu", r is not None)
if r:
    verifier("la source est citee", "Source :" in r)
    verifier("ce n'est pas un aveu d'ignorance", "ne trouve pas de reponse" not in r.lower())
    print(f"\n         --- reponse ---\n         {r[:400].replace(chr(10), chr(10) + '         ')}\n")

print("2. Question d'un recruteur sur le metier obligatoire")
r = demander(recruteur, "Pourquoi dois-je choisir un metier pour publier mon offre ?")
verifier("l'assistant a repondu", r is not None)
if r:
    verifier("la source est citee", "Source :" in r)
    print(f"\n         --- reponse ---\n         {r[:400].replace(chr(10), chr(10) + '         ')}\n")

print("3. LE TEST QUI COMPTE — question hors corpus")
r = demander(candidat, "Quelle est la recette de la tarte aux pommes ?")
verifier("l'assistant a repondu", r is not None)
if r:
    verifier("il avoue son ignorance", "ne trouve pas de r" in r.lower())
    verifier("il propose l'escalade", "personne" in r.lower())
    verifier("il ne cite aucune source", "Source :" not in r)
    print(f"\n         --- reponse ---\n         {r[:300].replace(chr(10), chr(10) + '         ')}\n")

print("4. Cloisonnement — un candidat ne recoit pas la doc recruteur")
r = demander(candidat, "Comment creer une offre d'emploi et choisir le niveau ?")
verifier("l'assistant a repondu", r is not None)
if r:
    verifier("aucune source reservee au recruteur",
             not any(t in r for t in ["Comment creer une offre ?",
                                      "Quelle difference fait le niveau"]),
             r.split("Source :")[-1].strip() if "Source :" in r else "aveu d'ignorance")

print()
print("=" * 62)
print("RESULTAT :", "tout est vert" if ok else "AU MOINS UNE VERIFICATION A ECHOUE")
