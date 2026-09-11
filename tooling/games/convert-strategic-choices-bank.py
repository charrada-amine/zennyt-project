#!/usr/bin/env python3
"""Convertit la banque « Choix Stratégiques » (.docx) en asset JSON.

Le document décrit 60 situations (CS-001 à CS-060). Chaque fiche porte un
contexte inféré, une description de scène, et les huit stratégies du
référentiel cotées de 0 à 3 avec leur justification.

Deux partis pris, les mêmes que pour la banque du « Temps Réflexif » :

1. **Les prompts vidéo IA sont ignorés.** La banque vidéo est en cours de
   production ; l'écran affiche un emplacement en attendant, et la description
   de scène tient lieu de contexte jouable.

2. **Rien n'est deviné.** Un tableau mal formé, un score hors 0-3 ou une
   stratégie inconnue arrête la conversion.

⚠️ Ce barème est, de l'aveu du document lui-même, « établi indépendamment du
script du psychologue » et reconstruit par inférence à partir des titres. Cinq
fiches portent un signal [ATTENTION] demandant une validation. L'asset conserve
ce signal tel quel.

L'asset est écrit à DEUX endroits : l'app mobile l'affiche, le serveur s'en sert
comme barème. Une seule source de vérité, deux copies engendrées ensemble —
laisser les deux dériver donnerait un écran et un score qui ne parlent pas de la
même situation.

Usage : python3 tooling/games/convert-strategic-choices-bank.py <docx> <json>
        [<json-serveur>]
"""
import html
import json
import re
import sys
import zipfile

# Les huit stratégies du référentiel, avec leur nom dans le code mobile.
STRATEGIES = {
    'Avoid / flee': 'AVOID_FLEE',
    'Ruminate': 'RUMINATE',
    'Breathe / pause': 'BREATHE_PAUSE',
    'Cognitive reappraisal': 'COGNITIVE_REAPPRAISAL',
    'Assertive communication': 'ASSERTIVE_COMMUNICATION',
    'Humor': 'HUMOR',
    'Seek support': 'SEEK_SUPPORT',
    'Direct action': 'DIRECT_ACTION',
}

CONTEXT = 'Contexte inféré : '
SCENE = 'Prompt mini-vidéo (contexte utilisé pour l’analyse) : '


def text_of(docx_path):
    with zipfile.ZipFile(docx_path) as z:
        xml = z.read('word/document.xml').decode('utf-8')
    xml = re.sub(r'</w:p>', '\n', xml)
    xml = re.sub(r'<w:tab[^>]*/>', '\t', xml)
    return html.unescape(re.sub(r'<[^>]+>', '', xml)).split('\n')


def fail(msg):
    sys.exit(f'ERREUR : {msg}')


def field(lines, start, end, prefix, sid):
    for i in range(start, end):
        if lines[i].startswith(prefix):
            return lines[i][len(prefix):].strip()
    fail(f'{sid} : champ « {prefix.strip()} » absent')


def parse_choices(bloc, sid):
    """Lit le tableau : en-tête à trois colonnes puis huit lignes de trois."""
    try:
        head = next(i for i, l in enumerate(bloc) if l.strip() == 'Choix stratégique')
    except StopIteration:
        fail(f'{sid} : tableau des stratégies introuvable')
    if bloc[head + 1].strip() != 'Score' or bloc[head + 2].strip() != 'Justification':
        fail(f'{sid} : en-tête de tableau inattendu')

    choices = []
    for k in range(8):
        base = head + 3 + k * 3
        if base + 2 >= len(bloc):
            fail(f'{sid} : tableau tronqué à la ligne {k + 1}')
        label = bloc[base].strip()
        if label not in STRATEGIES:
            fail(f'{sid} : stratégie inconnue « {label} »')
        score = bloc[base + 1].strip()
        if score not in ('0', '1', '2', '3'):
            fail(f'{sid} : score hors 0-3 pour « {label} » — « {score} »')
        choices.append({
            'strategy': STRATEGIES[label],
            'label': label,
            'score': int(score),
            'rationale': bloc[base + 2].strip(),
        })

    if len({c['strategy'] for c in choices}) != 8:
        fail(f'{sid} : les huit stratégies ne sont pas toutes présentes')
    return choices


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    mirror = sys.argv[3] if len(sys.argv) == 4 else None
    lines = text_of(src)

    heads = [i for i, l in enumerate(lines) if re.match(r'^CS-\d{3} — ', l)]
    if len(heads) != 60:
        fail(f'{len(heads)} fiches détectées, 60 attendues')

    situations = []
    for n, start in enumerate(heads):
        end = heads[n + 1] if n + 1 < len(heads) else len(lines)
        bloc = lines[start:end]
        sid, title = re.match(r'^(CS-\d{3}) — (.+)$', lines[start]).groups()

        context = field(lines, start, end, CONTEXT, sid)
        # Le signal de validation vit dans le contexte : on l'en sort pour en
        # faire une donnée, plutôt que de le laisser s'afficher au joueur.
        needs_validation = '[ATTENTION]' in context
        context = context.replace('[ATTENTION]', '').strip()

        scene = field(lines, start, end, SCENE, sid)
        # Le document cite la scène en bloc de citation Markdown.
        if scene.startswith('>'):
            scene = scene[1:].strip()
        if not scene:
            fail(f'{sid} : description de scène vide')

        situations.append({
            'id': sid,
            'title': title.strip(),
            'context': context,
            'scene': scene,
            # Le support : toutes les fiches décrivent une mini-vidéo, aucune
            # n'est livrée comme message écrit. On ne le déduit pas, on le lit.
            'medium': 'VIDEO',
            'needsPsychologistValidation': needs_validation,
            'choices': parse_choices(bloc, sid),
        })

    if len({s['id'] for s in situations}) != 60:
        fail('identifiants dupliqués')

    payload = {
        'source': 'Choix_strategique_OPTIMISE_Independant_60_Situations.docx',
        'situations': situations,
    }
    for path in [dst] + ([mirror] if mirror else []):
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(f'écrit : {path}')

    flagged = [s['id'] for s in situations if s['needsPsychologistValidation']]
    print(f'{len(situations)} situations · '
          f'{sum(len(s["choices"]) for s in situations)} cotations')
    print(f'à valider par le psychologue : {len(flagged)} — {", ".join(flagged)}')


if __name__ == '__main__':
    main()
