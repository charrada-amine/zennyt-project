# -*- coding: utf-8 -*-
"""Qui paie le bonus ? Balayage de TOUTES les combinaisons autorisées par le CdC.

Le CdC autorise jusqu'à 2 modules bonifiés par offre, jusqu'à +10 points chacun, et
interdit de bonifier un module déjà dominant. On énumère donc chaque paire de modules
non dominants et on regarde ce que les 3 modules restants doivent absorber.
"""
from itertools import combinations

MATRICE = {
    "TECHNIQUE":     [30, 20, 30, 15, 5],
    "ANALYTIQUE":    [25, 20, 30, 15, 10],
    "RELATIONNEL":   [10, 10, 20, 15, 45],
    "MANAGERIAL":    [10, 10, 20, 30, 30],
    "CONVENTIONNEL": [15, 30, 15, 30, 10],
    "ARTISTIQUE":    [40, 15, 15, 15, 15],
}
MODULES = ["Flexibilite", "Memoire", "Decision", "Planification", "Regulation"]
BONUS = 9   # milieu de la fourchette 8-10 du CdC


def scenarios(poids):
    """Toutes les paires de modules bonifiables (on exclut le module dominant)."""
    dominant = poids.index(max(poids))
    candidats = [i for i in range(5) if i != dominant]
    return combinations(candidats, 2)


print("=" * 92)
print("Le pire cas de chaque profil : deux modules bonifies de +9, trois absorbeurs")
print("=" * 92)
print(f"\n{'Profil':<14} {'Modules bonifies':<30} {'A absorber':>10} "
      f"{'Parts egales':>14} {'Proportionnel':>14}")
print("-" * 92)

impossibles_egal = 0
impossibles_prop = 0
total = 0

for profil, poids in MATRICE.items():
    pire = None
    for paire in scenarios(poids):
        total += 1
        absorbeurs = [j for j in range(5) if j not in paire]
        capacite = sum(poids[j] for j in absorbeurs)
        a_absorber = BONUS * 2

        min_egal = min(poids[j] - a_absorber / len(absorbeurs) for j in absorbeurs)
        min_prop = min(poids[j] - a_absorber * poids[j] / capacite for j in absorbeurs)

        if min_egal < 0:
            impossibles_egal += 1
        if min_prop < 0:
            impossibles_prop += 1
        if pire is None or min_egal < pire[2]:
            pire = (paire, a_absorber, min_egal, min_prop, capacite)

    paire, a_abs, me, mp, cap = pire
    noms = " + ".join(MODULES[i] for i in paire)
    fe = " IMPOSSIBLE" if me < 0 else ""
    print(f"{profil:<14} {noms:<30} {a_abs:>10} {me:>13.2f}{fe} {mp:>13.2f}")

print(f"""
Sur {total} combinaisons autorisees par le CdC (2 modules bonifies parmi les non dominants) :
  - repartition a parts egales   : {impossibles_egal} produisent un poids negatif -> methode inapplicable
  - repartition proportionnelle  : {impossibles_prop} produisent un poids negatif

La repartition proportionnelle ne peut JAMAIS rendre un poids negatif : chaque module
cede une fraction de ce qu'il possede, donc il ne peut pas ceder plus qu'il n'a.""")

print()
print("=" * 92)
print("Le meme calcul, mais avec un plancher a 5 % par module")
print("=" * 92)
print("""
Un module tombe a 1 % n'est plus mesure, il est efface. Un plancher garde le module
vivant, mais reduit la capacite d'absorption : on regarde ici si le bonus demande
tient encore.""")
print(f"\n{'Profil':<14} {'Capacite au-dessus du plancher':>32} {'Bonus max tenable':>20}")
print("-" * 70)
PLANCHER = 5
for profil, poids in MATRICE.items():
    pires = []
    for paire in scenarios(poids):
        absorbeurs = [j for j in range(5) if j not in paire]
        marge = sum(max(0, poids[j] - PLANCHER) for j in absorbeurs)
        pires.append(marge)
    marge_min = min(pires)
    print(f"{profil:<14} {marge_min:>30} pts {min(marge_min, 20):>17} pts")

print("""
Lecture : « bonus max tenable » = ce que les absorbeurs peuvent ceder sans passer sous
5 %, plafonne au maximum demande par le CdC (2 modules x 10 pts = 20).""")
