# -*- coding: utf-8 -*-
"""Comparer les deux modeles de remplacement sur les taches reelles du projet.

Trois usages a couvrir, et ils n'ont pas les memes exigences :
  - generation de tests      -> JSON structure, francais, contenu technique juste
  - resume de competences    -> JSON bilingue francais/anglais
  - reponse du centre d'aide -> prose francaise breve, fidele aux extraits
"""
import json, os, re, time, urllib.request, urllib.error

racine = r"C:\Users\Ghassen\Documents\zennyt-project\zennyt-project"
env = open(os.path.join(racine, ".env"), encoding="utf-8", errors="ignore").read()
CLE = re.search(r"^GROQ_API_KEY=(.+)$", env, re.M).group(1).strip()
URL = "https://api.groq.com/openai/v1/chat/completions"

MODELES = ["openai/gpt-oss-120b", "qwen/qwen3.6-27b"]


def appeler(modele, systeme, utilisateur, json_strict):
    corps = {"model": modele, "temperature": 0.2,
             "messages": [{"role": "system", "content": systeme},
                          {"role": "user", "content": utilisateur}]}
    if json_strict:
        corps["response_format"] = {"type": "json_object"}
    req = urllib.request.Request(URL, data=json.dumps(corps).encode(),
        headers={"Content-Type": "application/json", "Authorization": "Bearer " + CLE,
                 "User-Agent": "curl/8.0.1"})
    debut = time.time()
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            data = json.load(r)
        return data["choices"][0]["message"]["content"], time.time() - debut, None
    except urllib.error.HTTPError as e:
        return None, time.time() - debut, f"HTTP {e.code}: {e.read().decode(errors='replace')[:120]}"
    except Exception as e:
        return None, time.time() - debut, str(e)[:120]


EPREUVES = [
    ("QCM structure (generation de tests)", True,
     "Tu generes des QCM techniques en francais. Reponds en JSON: "
     '{"questions":[{"text":"...","options":["a","b","c","d"],"correctIndex":0}]}',
     "Genere exactement 2 questions sur les bases de Docker, niveau senior."),
    ("Resume bilingue (profil candidat)", True,
     'Tu rediges des resumes de competences. Reponds en JSON: {"fr":"...","en":"..."}',
     "Redige 2 phrases sur un candidat: flexibilite cognitive 82, memoire 74, "
     "planification 90, regulation emotionnelle 55."),
    ("Reponse d'aide (prose fidele)", False,
     "Tu reponds UNIQUEMENT a partir des extraits. N'ajoute aucun fait. "
     "Deux a quatre phrases, francais, sans formule de politesse.",
     "Question: Puis-je rejouer a un mini-jeu ?\n\nExtrait: Oui. Le resultat le plus "
     "recent remplace le precedent, et les scores se recalculent automatiquement dans "
     "les minutes qui suivent. Il n'y a pas de penalite a rejouer."),
]

resultats = {m: {"ok": 0, "temps": 0.0} for m in MODELES}

for titre, strict, systeme, utilisateur in EPREUVES:
    print(f"\n{'=' * 74}\n{titre}\n{'=' * 74}")
    for modele in MODELES:
        contenu, duree, erreur = appeler(modele, systeme, utilisateur, strict)
        resultats[modele]["temps"] += duree

        if erreur:
            print(f"\n  {modele:<22} ECHEC en {duree:.1f}s — {erreur}")
            continue

        valide = True
        note = ""
        if strict:
            try:
                obj = json.loads(contenu)
                note = "JSON valide, cles: " + ", ".join(list(obj.keys())[:4])
            except Exception:
                valide = False
                note = "JSON INVALIDE"
        else:
            phrases = contenu.count(".") + contenu.count("!")
            valide = 1 <= phrases <= 6 and len(contenu) < 900
            note = f"{phrases} phrases, {len(contenu)} caracteres"

        if valide:
            resultats[modele]["ok"] += 1
        print(f"\n  {modele:<22} {'OK ' if valide else 'ECHEC'} en {duree:>5.1f}s — {note}")
        apercu = " ".join(contenu.split())[:260]
        print(f"    {apercu}")

print(f"\n{'=' * 74}\nBILAN\n{'=' * 74}")
print(f"{'modele':<24}{'epreuves reussies':>20}{'temps total':>16}")
for modele in MODELES:
    r = resultats[modele]
    print(f"{modele:<24}{f'{r[chr(111)+chr(107)]}/{len(EPREUVES)}':>20}{f'{r[chr(116)+chr(101)+chr(109)+chr(112)+chr(115)]:.1f}s':>16}")
