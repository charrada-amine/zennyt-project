# -*- coding: utf-8 -*-
"""Verse les deux propositions validées dans les banques du jeu.

Les identifiants sont disjoints — TR-101+ et CS-101+ contre les identifiants
client — de sorte que les nouvelles situations S'AJOUTENT aux fiches du client
au lieu de les remplacer. Une nouvelle exécution remplace uniquement une
proposition portant le même identifiant, sans la dupliquer.
"""
import json, unicodedata

RACINE = "/Users/mac/Documents/GitHub/zennyt-private/zennyt-project"

# ── Temps Réflexif ────────────────────────────────────────────────────────
CAPACITE = {
    1: "Inhibition d'une réaction impulsive face à une provocation",
    2: "Gestion de l'impulsivité face à une mise en cause",
    3: "Décision sous contrainte de temps",
    4: "Régulation face à l'exposition d'une erreur",
    5: "Régulation dans une interaction qui se tend",
    6: "Tolérance à l'ambiguïté avant décision",
    7: "Arbitrage sous demandes concurrentes",
    8: "Régulation face à un obstacle ou un refus",
    9: "Adaptation à un changement imposé",
    10: "Maintien du jugement sous pression sociale",
}

prop_tr = json.load(open("temps_reflexif_proposition.json"))["situations"]
converties_tr = []
for x in prop_tr:
    # `trigger` porte l'événement déclencheur : le message pour un écrit, la
    # scène décrite pour une vidéo. Le laisser vide casserait l'affichage.
    declencheur = x["message"] or x["context"]
    converties_tr.append({
        "id": x["id"], "title": x["title"],
        "categoryNumber": x["categoryNumber"], "category": x["category"],
        "difficulty": x["difficulty"],
        "pilotValidated": False,
        "capability": CAPACITE[x["categoryNumber"]],
        "context": x["context"], "trigger": declencheur,
        "question": x["question"], "medium": x["medium"],
        "responseDeadlineSec": x["responseDeadlineSec"],
        "wordsToRead": x["wordsToRead"],
        # Champs propres à la proposition, conservés pour la traçabilité.
        "targetEmotion": x.get("targetEmotion"),
        "source": "PROPOSITION_STEM",
        "choices": [
            {"letter": chr(ord("A") + i), "text": c["text"],
             "responseType": c["responseType"], "rationale": c["rationale"],
             "score": c["score"]}
            for i, c in enumerate(x["choices"])
        ],
    })

banque_tr = json.load(open(f"{RACINE}/mobile/assets/games/reflective_pause_bank.json"))
ids_proposition_tr = {s["id"] for s in converties_tr}
# Une régénération remplace la version précédente de la proposition au lieu de
# l'ajouter une deuxième fois. Les fiches client restent strictement intactes.
banque_tr["situations"] = [
    s for s in banque_tr["situations"] if s["id"] not in ids_proposition_tr
]
banque_tr["situations"].extend(converties_tr)

# ── Choix Stratégiques ────────────────────────────────────────────────────
LIBELLE = {
    "AVOID_FLEE": "Avoid / flee", "RUMINATE": "Ruminate",
    "BREATHE_PAUSE": "Breathe / pause",
    "COGNITIVE_REAPPRAISAL": "Cognitive reappraisal",
    "ASSERTIVE_COMMUNICATION": "Assertive communication",
    "HUMOR": "Humor", "SEEK_SUPPORT": "Seek support",
    "DIRECT_ACTION": "Direct action",
}
prop_cs = json.load(open("choix_strategiques_proposition.json"))["situations"]
converties_cs = []
for x in prop_cs:
    situation = {
        "id": x["id"], "title": x["title"],
        "context": x["context"], "scene": x["scene"], "medium": x["medium"],
        "needsPsychologistValidation": True,
        "controllability": x.get("controllability"),
        "source": "PROPOSITION_GOODNESS_OF_FIT",
        "choices": [
            {"strategy": c["strategy"], "label": LIBELLE[c["strategy"]],
             "score": c["score"],
             # La justification est portée au niveau de la situation : la clé
             # découle de la contrôlabilité, pas d'un argument par stratégie.
             "rationale": x["rationale"]}
            for c in x["choices"]
        ],
    }
    if x.get("message"):
        situation["message"] = x["message"]
    converties_cs.append(situation)

banque_cs = json.load(open(f"{RACINE}/mobile/assets/games/strategic_choices_bank.json"))
ids_proposition_cs = {s["id"] for s in converties_cs}
banque_cs["situations"] = [
    s for s in banque_cs["situations"] if s["id"] not in ids_proposition_cs
]
banque_cs["situations"].extend(converties_cs)

for chemin, data in [
    (f"{RACINE}/mobile/assets/games/reflective_pause_bank.json", banque_tr),
    (f"{RACINE}/mobile/assets/games/strategic_choices_bank.json", banque_cs),
    (f"{RACINE}/backend/src/main/resources/games/strategic_choices_bank.json", banque_cs),
]:
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

print(f"Temps Réflexif      : {len(banque_tr['situations'])} situations "
      f"(+{len(converties_tr)})")
print(f"Choix Stratégiques  : {len(banque_cs['situations'])} situations "
      f"(+{len(converties_cs)})")
