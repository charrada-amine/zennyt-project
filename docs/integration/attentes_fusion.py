# -*- coding: utf-8 -*-
"""Valeurs attendues du Fit Score APRÈS fusion de Games-Progress.

Deux changements se cumulent, et c'est ce cumul que personne n'a encore calculé :

  1. (main, 10 août)  la flexibilité compte 3 jeux et la mémoire 2 — donc jouer
     un seul jeu ne couvre plus le module entièrement ;
  2. (Games-Progress) « Je Décide » devient mesurable — donc le dénominateur
     repasse de 70 à 100.

La branche Games-Progress a calculé ses attentes en ne tenant compte que du
second : elle suppose encore qu'un seul jeu couvre la flexibilité à 100 %.
Ce script applique l'algorithme réel du calculateur avec les deux.
"""

# Nombre de jeux DISPONIBLES par module, après fusion.
JEUX_DISPO = {"FLEX": 3, "MEM": 2, "DEC": 1, "PLAN": 1, "EMO": 1}

PROFILS = {
    "TECHNIQUE_SENIOR":   {"FLEX": 30, "MEM": 20, "DEC": 30, "PLAN": 15, "EMO": 5},
    "RELATIONNEL_SENIOR": {"FLEX": 10, "MEM": 10, "DEC": 20, "PLAN": 15, "EMO": 45},
}

JEU_VERS_MODULE = {
    "MOVE_FAST": "FLEX", "CONTINUOUS_ATTENTION": "FLEX", "VISUOMOTOR_COORDINATION": "FLEX",
    "MEMORY_QUEST": "MEM", "VISUOSPATIAL_MEMORY": "MEM",
    "DECISION": "DEC", "PLANIFIK": "PLAN", "EMOTIONAL_REGULATION": "EMO",
}


def calculer(joues, profil):
    """Réplique DeterministicFitScoreCalculator : couverture par module, puis pondération."""
    poids = PROFILS[profil]
    par_module = {}
    for jeu, (score, couv) in joues.items():
        module = JEU_VERS_MODULE.get(jeu)
        if module is None:
            continue                      # clé inconnue : ignorée
        par_module.setdefault(module, []).append((score, couv))

    somme_ponderee = 0.0
    couverture_ponderee = 0.0
    denominateur = 0
    for module, w in poids.items():
        denominateur += w                 # tous mesurables après fusion
        if module not in par_module:
            continue
        lot = par_module[module]
        couv_module = min(100.0, sum(c for _, c in lot) / JEUX_DISPO[module])
        score_module = sum(s for s, _ in lot) / len(lot)
        somme_ponderee += score_module * couv_module / 100 * w
        couverture_ponderee += couv_module * w

    if denominateur == 0 or not par_module:
        return None
    return (round(somme_ponderee / denominateur), round(couverture_ponderee / denominateur))


def plein(score):
    return (score, 100)


CAS = [
    ("un seul jeu joué",
     {"MOVE_FAST": plein(90)}, "TECHNIQUE_SENIOR", (27, 30)),
    ("couverture partielle 40 %",
     {"MOVE_FAST": (90, 40)}, "TECHNIQUE_SENIOR", (11, 12)),
    ("deux couvertures différentes",
     {"MOVE_FAST": plein(80), "MEMORY_QUEST": (80, 50)}, "TECHNIQUE_SENIOR", (32, 40)),
    ("régulation émotionnelle pondérée",
     {"MOVE_FAST": plein(80), "EMOTIONAL_REGULATION": plein(20)}, "TECHNIQUE_SENIOR", (25, None)),
    ("clé inconnue ignorée",
     {"MOVE_FAST": plein(80), "JEU_INCONNU": plein(10)}, "TECHNIQUE_SENIOR", (24, None)),
    ("candidat sur 3 modules — TECHNIQUE",
     {"MOVE_FAST": plein(50), "MEMORY_QUEST": plein(55), "PLANIFIK": plein(70)},
     "TECHNIQUE_SENIOR", (37, None)),
    ("candidat sur 3 modules — RELATIONNEL",
     {"MOVE_FAST": plein(50), "MEMORY_QUEST": plein(55), "PLANIFIK": plein(70)},
     "RELATIONNEL_SENIOR", (21, None)),
]

print("=" * 96)
print("Attentes des tests du Fit Score : ce que la branche Games-Progress annonce,")
print("et ce que le calcul donne réellement une fois les deux changements cumulés.")
print("=" * 96)
print(f"\n{'Cas':<38} {'Games-Progress':>15} {'Réel apres fusion':>20} {'Verdict':>12}")
print("-" * 96)

for nom, joues, profil, (attendu_soft, attendu_couv) in CAS:
    soft, couv = calculer(joues, profil)
    ok = "OK" if soft == attendu_soft else "A CORRIGER"
    couv_txt = f" / couv {couv}" if attendu_couv is not None else ""
    print(f"{nom:<38} {attendu_soft:>15} {str(soft) + couv_txt:>20} {ok:>12}")

print()
print("=" * 96)
print("Les deux cas structurants")
print("=" * 96)

parfait = {j: plein(100) for j in JEU_VERS_MODULE}
soft, couv = calculer(parfait, "TECHNIQUE_SENIOR")
print(f"\nCandidat parfait (les 8 jeux joues a 100)      : score {soft}, couverture {couv}")
print("  -> doit valoir 100/100, sinon un candidat irreprochable est plafonne.")

sans_dec = {j: plein(100) for j in JEU_VERS_MODULE if JEU_VERS_MODULE[j] != "DEC"}
soft, couv = calculer(sans_dec, "TECHNIQUE_SENIOR")
print(f"\nTout sauf « Je Decide » (TECHNIQUE, poids 30) : score {soft}, couverture {couv}")
print("  -> c'est le changement de comportement le plus visible pour un candidat :")
print("     ne pas jouer « Je Decide » coute desormais 30 points sur un metier technique,")
print("     alors que le module etait purement et simplement ignore avant.")

un_seul_flex = {"MOVE_FAST": plein(100)}
soft, couv = calculer(un_seul_flex, "TECHNIQUE_SENIOR")
print(f"\nMove Fast seul, a 100                         : score {soft}, couverture {couv}")
print("  -> Games-Progress attend 30 ici : leur branche ignore que la flexibilite")
print("     compte 3 jeux depuis le 10 aout, et suppose une couverture pleine.")
