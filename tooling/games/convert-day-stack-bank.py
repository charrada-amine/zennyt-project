"""Convertit la banque client « Planning journalier » en asset normalisé.

Ce que le JSON client laisse implicite et que la conversion rend explicite :
  - les dépendances, écrites en LIBELLÉS, deviennent des identifiants ;
  - les durées (« 20 min + 60 min repos ») deviennent des minutes ;
  - les contraintes horaires, cinq formes distinctes en prose, deviennent des
    objets typés avec leurs minutes depuis minuit.

Le script ÉCHOUE plutôt que de deviner : toute donnée qu'il ne sait pas lire
est signalée, jamais approximée.
"""
import json, re, sys, unicodedata

# Usage :
#   python3 tooling/games/convert-day-stack-bank.py <banque_client.json> \
#       > mobile/assets/games/day_stack_bank.json
#
# L'asset mobile est GÉNÉRÉ : ne pas l'éditer à la main. Quand le client livre
# une nouvelle banque, relancer ce script et vérifier que
# `test/features/games/data/day_stack_bank_test.dart` passe toujours — c'est lui
# qui garde les effectifs du tableau de normalisation.
SRC = sys.argv[1] if len(sys.argv) > 1 else None
if SRC is None:
    sys.exit(__doc__ + '\nUsage : convert-day-stack-bank.py <banque_client.json>')

# Échéances relatives : la prose désigne une autre tâche. Résolu à la main et
# non par similarité de texte — quatre cas, et une erreur de rapprochement
# fausserait silencieusement le graphe.
RELATIVE = {
    ('Gestion de projet / Bureau', 'prep_ordre_jour'): 'reunion_equipe',
    ("Organisation d'un événement", 'test_sono'): 'accueil_invites',
    ('Chantier de construction', 'passage_reseaux'): 'demande_inspection',
    ('Logistique / Entrepôt', 'edition_documents'): 'chargement_camion',
}

PRIORITY = {'Critique': 'CRITICAL', 'Haute': 'HIGH', 'Moyenne': 'MEDIUM', '—': 'NONE'}

def slug(name):
    s = unicodedata.normalize('NFKD', name).encode('ascii', 'ignore').decode()
    s = re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')
    return s.split('_')[0]

def minutes(h, m=None):
    return int(h) * 60 + (int(m) if m else 0)

def parse_duration(raw):
    """« 15 min » ou « 20 min + 60 min repos » -> (travail, repos)."""
    m = re.fullmatch(r'(\d+)\s*min(?:\s*\+\s*(\d+)\s*min\s*repos)?', raw.strip())
    if not m:
        sys.exit(f'durée illisible : {raw!r}')
    return int(m.group(1)), int(m.group(2) or 0)

def resolve_deps(raw, labels):
    """Consomme la chaîne par plus long libellé connu.

    Le découpage naïf sur la virgule est FAUX : « Commander le matériel
    (chaises, son, déco) » en contient trois et produirait trois fausses
    dépendances.
    """
    if raw == 'Aucune':
        return []
    s, out = raw.strip(), []
    while s:
        cand = [l for l in labels if s.startswith(l)]
        if not cand:
            sys.exit(f'dépendance non résolue : reste {s!r}')
        best = max(cand, key=len)
        out.append(labels[best])
        s = s[len(best):].lstrip(' ,')
    return out

WINDOW = re.compile(r'(\d{1,2})h(\d{2})?\s*-\s*(\d{1,2})h(\d{2})?')
BETWEEN = re.compile(r'[Ee]ntre\s+(\d{1,2})h(\d{2})?\s+et\s+(\d{1,2})h(\d{2})?')
ANCHOR = re.compile(r'[Dd]émarre à (\d{1,2})h(\d{2})?\s*pile')
DEADLINE = re.compile(r'(?:[Aa]vant|[Dd]eadline|[Tt]erminé avant)\s+(\d{1,2})h(\d{2})?')
MINDELAY = re.compile(r'[Mm]ini\.?\s*(\d+)\s*(h|min)')

def parse_constraint(raw, universe, task_id):
    fixed = 'loc horaire fixe' in raw
    if raw in ('—', ''):
        return {'kind': 'none'}

    m = ANCHOR.search(raw)
    if m:
        return {'kind': 'anchor', 'startMin': minutes(*m.groups()),
                'toleranceMin': 5, 'fixedBlock': fixed, 'raw': raw}
    m = BETWEEN.search(raw) or WINDOW.search(raw)
    if m:
        a, b, c, dmin = m.groups()
        return {'kind': 'window', 'startMin': minutes(a, b), 'endMin': minutes(c, dmin),
                'fixedBlock': fixed, 'raw': raw}
    m = MINDELAY.search(raw)
    if m:
        n = int(m.group(1)) * (60 if m.group(2) == 'h' else 1)
        return {'kind': 'minDelay', 'minDelayMin': n, 'fixedBlock': fixed, 'raw': raw}
    m = DEADLINE.search(raw)
    if m:
        return {'kind': 'deadline', 'beforeMin': minutes(*m.groups()),
                'fixedBlock': fixed, 'raw': raw}
    rel = RELATIVE.get((universe, task_id))
    if rel:
        return {'kind': 'relative', 'beforeTaskId': rel, 'fixedBlock': fixed, 'raw': raw}
    if fixed:
        # Le défaut que le client signale lui-même : « Bloc horaire fixe » sans
        # heure. Marqué tel quel — inventer une heure fausserait le barème.
        return {'kind': 'unspecified', 'fixedBlock': True, 'raw': raw}
    sys.exit(f'contrainte illisible : {universe}/{task_id} {raw!r}')

src = json.load(open(SRC, encoding='utf-8'))
universes = []
for name, u in src['univers'].items():
    icons = {i['tache_id']: i for i in u['icones']}
    labels = {t['variantes_libelle'][0]: t['id'] for t in u['taches']}
    tasks = []
    for t in u['taches']:
        work, rest = parse_duration(t['duree'])
        ic = icons.get(t['id'], {})
        tasks.append({
            'id': t['id'],
            'variants': t['variantes_libelle'],
            'durationMin': work,
            'restMin': rest,
            'deps': resolve_deps(t['dependances'], labels),
            'priority': PRIORITY[t['priorite']],
            'category': ic.get('categorie'),
            'icon': ic.get('icone_tabler'),
            'constraint': parse_constraint(t['contrainte_horaire'], name, t['id']),
        })
    universes.append({'id': slug(name), 'name': name, 'tasks': tasks})

out = {
    'version': 1,
    'source': "Banque de tâches par univers — Nejmeddine LABIDI",
    'note': ("Généré depuis le JSON client. Dépendances résolues en identifiants, "
             "durées en minutes, contraintes horaires typées."),
    'universes': universes,
}
print(json.dumps(out, ensure_ascii=False, indent=2))
