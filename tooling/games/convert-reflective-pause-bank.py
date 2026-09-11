#!/usr/bin/env python3
"""Convertit la banque « Temps Réflexif » (.docx) en asset JSON.

Le document client décrit 60 situations (TR-001 à TR-060) : 10 catégories × 3
niveaux × 2 situations. Chaque fiche porte, en plus du texte joué, une cotation
0-3 par choix et un délai de réponse calculé sur le nombre de mots à lire.

Deux partis pris, tenus volontairement :

1. **Les prompts vidéo sont ignorés.** La banque vidéo est en cours de
   production ; l'asset ne garde que le support attendu, à charge pour l'écran
   d'afficher un emplacement en attendant le média — comme le radar émotionnel.

2. **Rien n'est deviné.** Un champ manquant ou un tableau de cotation mal formé
   arrête la conversion. Une banque à moitié lue se verrait au premier jeu, pas
   avant.

Usage : python3 tooling/games/convert-reflective-pause-bank.py <docx> <json>
"""
import html
import json
import re
import sys
import unicodedata
import zipfile

# Les cinq catégories de réaction du référentiel, dans l'ordre du barème.
CATEGORIES = {
    'répondre impulsivement': 'RESPOND_IMPULSIVELY',
    'respirer et analyser': 'BREATHE_ANALYZE',
    'attendre': 'WAIT',
    'demander plus d\'informations': 'ASK_FOR_MORE_INFORMATION',
    'reformuler calmement': 'REFORMULATE_CALMLY',
}

DIFFICULTIES = {'FAIBLE': 'LOW', 'MODÉRÉE': 'MODERATE', 'ÉLEVÉE': 'HIGH'}

def text_of(docx_path):
    with zipfile.ZipFile(docx_path) as z:
        xml = z.read('word/document.xml').decode('utf-8')
    xml = re.sub(r'</w:p>', '\n', xml)
    xml = re.sub(r'<w:tab[^>]*/>', '\t', xml)
    return html.unescape(re.sub(r'<[^>]+>', '', xml)).split('\n')


def fail(msg):
    sys.exit(f'ERREUR : {msg}')


def field(lines, start, end, label):
    prefix = label + ' : '
    for i in range(start, end):
        if lines[i].startswith(prefix):
            return lines[i][len(prefix):].strip()
    fail(f'champ « {label} » absent entre les lignes {start} et {end}')


def normalize(s):
    """Minuscule sans accents ni apostrophe typographique, pour comparer."""
    s = s.replace('’', "'").strip().lower()
    return unicodedata.normalize('NFKD', s)


def category_code(raw):
    key = normalize(raw)
    for label, code in CATEGORIES.items():
        if normalize(label) == key:
            return code
    fail(f'catégorie de réaction inconnue : « {raw} »')


def parse_choices(lines, start, end, sid):
    """Lit le tableau de cotation : 5 lignes par choix, A à E."""
    head = None
    for i in range(start, end):
        if lines[i].strip() == 'Choix de réponse et cotation':
            head = i
            break
    if head is None:
        fail(f'{sid} : tableau de cotation introuvable')
    # En-tête : #, Réponse, Catégorie, Justification, Score.
    cur = head + 1
    while cur < end and lines[cur].strip() != '#':
        cur += 1
    if cur >= end:
        fail(f'{sid} : en-tête du tableau de cotation introuvable')
    cur += 5

    choices = []
    for letter in 'ABCDE':
        if lines[cur].strip() != letter:
            fail(f'{sid} : choix {letter} attendu, trouvé « {lines[cur].strip()} »')
        score = lines[cur + 4].strip()
        if score not in ('0', '1', '2', '3'):
            fail(f'{sid} : score hors 0-3 pour {letter} — « {score} »')
        choices.append({
            'letter': letter,
            'text': lines[cur + 1].strip(),
            'responseType': category_code(lines[cur + 2].strip()),
            'rationale': lines[cur + 3].strip(),
            'score': int(score),
        })
        cur += 5

    types = {c['responseType'] for c in choices}
    if len(types) != 5:
        fail(f'{sid} : les 5 catégories de réaction ne sont pas toutes présentes')
    return choices


def medium_of(lines, start, end, sid):
    """Support d'affichage, tel que le document le déclare.

    Le client attend « une vidéo OU un message écrit selon le scénario », mais
    la banque livrée ne fait pas ce partage : les soixante fiches portent un
    prompt vidéo ET une durée vidéo recommandée, y compris celles dont la scène
    est un SMS ou un message de chat — TR-001 est une notification lue à
    l'écran, spécifiée comme une vidéo de 10 s dont le prompt interdit
    explicitement de rendre le texte lisible.

    Une version antérieure de ce script déduisait le support de l'événement
    déclencheur. C'était une invention : elle produisait six situations
    « écrites » que le document ne désigne nulle part comme telles, et elle
    aurait affiché en clair, dans une bulle de message, un texte que la fiche
    demande de ne jamais montrer. On s'en tient donc à ce qui est écrit.
    """
    has_prompt = any(
        lines[i].startswith('Prompt vidéo complet') for i in range(start, end))
    has_duration = any(
        lines[i].startswith('Durée vidéo recommandée') for i in range(start, end))
    if not (has_prompt and has_duration):
        fail(f'{sid} : ni prompt ni durée vidéo — support indéterminable')
    return 'VIDEO'


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    lines = text_of(src)

    heads = [i for i, l in enumerate(lines) if re.match(r'^\s+TR-\d{3} — ', l)]
    if len(heads) != 60:
        fail(f'{len(heads)} fiches détectées, 60 attendues')

    situations = []
    for n, start in enumerate(heads):
        end = heads[n + 1] if n + 1 < len(heads) else len(lines)
        sid, title = re.match(r'^\s+(TR-\d{3}) — (.+)$', lines[start]).groups()

        meta = lines[start + 1].strip()
        m = re.match(r'^(FAIBLE|MODÉRÉE|ÉLEVÉE) · (\d+)\. (.+?)(?:\s{2,}PILOTE VALIDÉ)?$', meta)
        if not m:
            fail(f'{sid} : en-tête de difficulté illisible — « {meta} »')
        difficulty, cat_no, cat_label = m.groups()

        question = field(lines, start, end, 'Question affichée')
        q = question.strip()
        if q.startswith('«') and q.endswith('»'):
            q = q[1:-1].strip()

        delay = field(lines, start, end, 'Délai de réponse recommandé')
        dm = re.match(r'^(\d+)\s+secondes?$', delay)
        if not dm:
            fail(f'{sid} : délai illisible — « {delay} »')

        words = field(lines, start, end, 'Nombre de mots à lire')
        wm = re.match(r'^(\d+)\s+mots?$', words)
        if not wm:
            fail(f'{sid} : nombre de mots illisible — « {words} »')

        trigger = field(lines, start, end, 'Événement déclencheur')
        context = field(lines, start, end, 'Contexte (interface joueur)')

        situations.append({
            'id': sid,
            'title': title.strip(),
            'categoryNumber': int(cat_no),
            'category': cat_label.strip().capitalize(),
            'difficulty': DIFFICULTIES[difficulty],
            'pilotValidated': 'PILOTE VALIDÉ' in meta,
            'capability': field(lines, start, end, 'Capacité principale observée'),
            'context': context,
            'trigger': trigger,
            'question': q,
            # Support déclaré par la fiche. Le média lui-même n'existe pas
            # encore : l'écran affiche un emplacement, la banque vidéo viendra
            # s'y brancher.
            'medium': medium_of(lines, start, end, sid),
            'responseDeadlineSec': int(dm.group(1)),
            'wordsToRead': int(wm.group(1)),
            'choices': parse_choices(lines, start, end, sid),
        })

    ids = [s['id'] for s in situations]
    if len(set(ids)) != 60:
        fail('identifiants dupliqués')

    bank = {
        'source': 'Temps_Reflexif_Banque_60_Situations_prompts_positifs.docx',
        'situations': situations,
    }
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(bank, f, ensure_ascii=False, indent=2)
        f.write('\n')

    by_cat = {}
    for s in situations:
        by_cat.setdefault(s['categoryNumber'], []).append(s['difficulty'])
    print(f'{len(situations)} situations · {sum(len(s["choices"]) for s in situations)} choix')
    print(f'{len(by_cat)} catégories')
    supports = {}
    for s in situations:
        supports[s['medium']] = supports.get(s['medium'], 0) + 1
    print('supports : ' + ' · '.join(f'{k} {v}' for k, v in supports.items()))
    delays = [s['responseDeadlineSec'] for s in situations]
    print(f'délais : {min(delays)}–{max(delays)} s')


if __name__ == '__main__':
    main()
