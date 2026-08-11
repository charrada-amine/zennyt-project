# -*- coding: utf-8 -*-
"""Deux expériences chiffrées pour le cadrage « pondération culture ».

A. Le comptage d'expressions distinctes distingue-t-il une entreprise réellement
   typée d'une entreprise qui écrit du texte RH standard ?
B. Quand on ajoute des points à un module, les autres peuvent-ils les absorber ?
   Calculé sur la matrice réelle des 6 profils.
"""
import unicodedata, re

DICO = {
    "Innovation":    ["innovation", "creativite", "experimentation", "agilite", "disruption",
                      "nouvelles idees", "prototypage", "veille technologique"],
    "Rigueur":       ["rigueur", "precision", "procedures", "conformite", "methode",
                      "controle qualite", "normes", "tracabilite"],
    "Autonomie":     ["autonomie", "ownership", "initiative", "oriente data", "prise de risque",
                      "sens des responsabilites", "force de proposition", "autonome"],
    "Performance":   ["excellence operationnelle", "oriente resultats", "discipline", "delivery",
                      "performance", "productivite", "respect des delais", "execution"],
    "Collaboration": ["bienveillance", "collectif", "ecoute", "diversite", "esprit d equipe",
                      "entraide", "inclusion", "communication", "travail en equipe"],
}


def norm(t):
    t = unicodedata.normalize("NFD", t.lower())
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return " " + re.sub(r"[^a-z0-9]+", " ", t).strip() + " "


def detecter(texte):
    n = norm(texte)
    return {p: sum(1 for e in exprs if f" {e} " in n) for p, exprs in DICO.items()}


def palier(distinctes):
    """Table du CdC v3.0 section 3."""
    if distinctes < 2:
        return 0
    if distinctes <= 2:
        return 4
    if distinctes <= 4:
        return 6
    return 9   # milieu de la fourchette 8-10


TEXTES = {
    "A. PME standard, texte RH generique (98 mots)": """
        Rejoignez une entreprise a taille humaine ou la bienveillance et l esprit d equipe
        sont au coeur de notre quotidien. Nous favorisons l entraide, l ecoute et une
        communication ouverte entre les equipes. Notre politique d inclusion et de diversite
        est un engagement fort. Nous encourageons l initiative et l autonomie de chacun, dans
        le respect des delais et avec une exigence de qualite constante. L innovation fait
        partie de notre ADN et nous investissons dans la formation continue de nos
        collaborateurs pour accompagner leur montee en competences.
    """,
    "B. Studio creatif reellement type innovation (94 mots)": """
        Notre studio vit de l experimentation. Chaque semaine, une journee entiere est
        banalisee pour le prototypage de nouvelles idees, sans obligation de resultat. La
        veille technologique est une mission a part entiere confiee a un binome tournant.
        Nous assumons une culture de la disruption : nous preferons un echec rapide a un
        consensus mou. La creativite prime sur la procedure, et nos revues de projet sont
        organisees autour de l agilite plutot que du planning. Nous ne recrutons pas des
        executants.
    """,
    "C. Industriel reellement type rigueur (91 mots)": """
        Notre site est certifie et audite chaque annee. La tracabilite de chaque lot est
        assuree de bout en bout, et le controle qualite intervient a cinq etapes distinctes
        du process. Le respect des procedures n est pas negociable : la conformite aux
        normes en vigueur conditionne notre licence d exploitation. Nous recherchons des
        profils attaches a la precision et a la methode, capables de documenter leur travail
        avec rigueur. La securite prime sur la cadence, toujours.
    """,
}

print("=" * 78)
print("EXPERIENCE A — le comptage distingue-t-il le typage reel du texte standard ?")
print("=" * 78)
for nom, texte in TEXTES.items():
    res = {p: c for p, c in detecter(texte).items() if c > 0}
    domine = max(res, key=res.get) if res else "-"
    print(f"\n{nom}")
    print(f"  profils declenches : {len(res)}  ->  {res}")
    print(f"  profil dominant    : {domine} ({res.get(domine, 0)} expressions) "
          f"=> bonus suggere +{palier(res.get(domine, 0))} pts")
    if len(res) >= 3:
        print("  /!\\ regle CdC : 3 profils ou plus = signal juge trop dilue, "
              "seuls les 2 plus forts sont retenus")

print()
print("=" * 78)
print("EXPERIENCE B — qui absorbe les points ajoutes ? (matrice reelle)")
print("=" * 78)
MATRICE = {
    "TECHNIQUE":     [30, 20, 30, 15, 5],
    "ANALYTIQUE":    [25, 20, 30, 15, 10],
    "RELATIONNEL":   [10, 10, 20, 15, 45],
    "MANAGERIAL":    [10, 10, 20, 30, 30],
    "CONVENTIONNEL": [15, 30, 15, 30, 10],
    "ARTISTIQUE":    [40, 15, 15, 15, 15],
}
MODULES = ["Flex.cogn.", "Memoire", "Decision", "Planif.", "Reg.emo."]

print(f"\n{'Profil':<14} {'Module bonifie':<12} {'Bonus':>6} {'Absorbeurs':>11} "
      f"{'A parts egales':>16} {'Proportionnel':>14}")
print("-" * 78)
for profil, poids in MATRICE.items():
    # On bonifie le module le PLUS FAIBLE (le cas le plus favorable au signal culture,
    # et celui que la regle « pas de bonus au module dominant » rend le plus probable).
    i = poids.index(min(poids))
    bonus = 9
    autres = [j for j in range(5) if j != i]
    total_absorbeurs = sum(poids[j] for j in autres)
    egal = min(poids[j] - bonus / len(autres) for j in autres)
    prop = min(poids[j] - bonus * poids[j] / total_absorbeurs for j in autres)
    flag_e = " NEGATIF" if egal < 0 else ""
    flag_p = " NEGATIF" if prop < 0 else ""
    print(f"{profil:<14} {MODULES[i]:<12} {'+' + str(bonus):>6} {total_absorbeurs:>11} "
          f"{egal:>15.2f}{flag_e} {prop:>13.2f}{flag_p}")

print("""
Lecture : la colonne « a parts egales » donne le poids du module le plus faible APRES
absorption. Un nombre negatif veut dire que la methode est impossible a appliquer.""")

print()
print("=" * 78)
print("EXPERIENCE B bis — effet reel sur la note, denominateur < 100")
print("=" * 78)
print("""
« Prise de decision » sort du calcul (aucun jeu livre), donc le denominateur du
sous-score soft n est pas 100 mais 100 moins le poids de ce module.""")
print(f"\n{'Profil':<14} {'Denominateur':>13} {'+9 pts vaut':>13} {'Ecart vs +9/100':>17}")
print("-" * 62)
for profil, poids in MATRICE.items():
    denom = 100 - poids[2]
    effet = 9 * 100 / denom
    print(f"{profil:<14} {denom:>13} {effet:>12.1f}% {effet - 9:>16.1f} pts")
