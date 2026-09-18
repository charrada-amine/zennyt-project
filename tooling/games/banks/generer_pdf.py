# -*- coding: utf-8 -*-
"""Rend les deux propositions de banque en PDF de relecture."""
import json
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                TableStyle, PageBreak, KeepTogether)

import temps_reflexif_proposition as TR
import choix_strategiques_proposition as CS

S = getSampleStyleSheet()
H1 = ParagraphStyle('H1', parent=S['Title'], fontSize=17, spaceAfter=4)
H2 = ParagraphStyle('H2', parent=S['Heading2'], fontSize=12, spaceBefore=10, spaceAfter=4)
P = ParagraphStyle('P', parent=S['Normal'], fontSize=9.5, leading=13)
SMALL = ParagraphStyle('SMALL', parent=S['Normal'], fontSize=8, leading=10.5,
                       textColor=colors.HexColor('#555555'))
CELL = ParagraphStyle('CELL', parent=S['Normal'], fontSize=8, leading=10)
ITEM = ParagraphStyle('ITEM', parent=S['Heading3'], fontSize=10.5, spaceBefore=13, spaceAfter=2)

GRILLE = TableStyle([
    ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#BBBBBB')),
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#EFEFEF')),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('LEFTPADDING', (0, 0), (-1, -1), 4),
    ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
])

AVERTISSEMENT = (
    "<b>Statut : proposition à valider.</b> Cette banque a été rédigée pour être "
    "confrontée au jugement du psychologue. Les cotations sont une clé de départ, "
    "destinée à être remplacée par une cotation de panel : dans la littérature du "
    "Situational Judgment Test, le score se mesure comme une distance à la moyenne "
    "d'experts, non comme la conformité à une clé unique. Aucune situation ci-dessous "
    "n'a été validée cliniquement."
)

TYPE_FR = {
    "RESPOND_IMPULSIVELY": "Répondre impulsivement",
    "BREATHE_ANALYZE": "Respirer et analyser",
    "WAIT": "Attendre",
    "ASK_FOR_MORE_INFORMATION": "Demander plus d'informations",
    "REFORMULATE_CALMLY": "Reformuler calmement",
}
STRAT_FR = {
    "AVOID_FLEE": "Éviter / fuir", "RUMINATE": "Ruminer",
    "BREATHE_PAUSE": "Respirer / faire une pause",
    "COGNITIVE_REAPPRAISAL": "Réévaluation cognitive",
    "ASSERTIVE_COMMUNICATION": "Communication assertive",
    "HUMOR": "Humour", "SEEK_SUPPORT": "Chercher du soutien",
    "DIRECT_ACTION": "Action directe",
}
FAM_FR = {"PROBLEM_FOCUSED": "centrée problème", "EMOTION_FOCUSED": "centrée émotion",
          "DYSFUNCTIONAL": "dysfonctionnelle", "UNRESOLVED": "non tranchée"}
EMO_FR = {"FEAR": "peur", "ANGER": "colère", "SADNESS": "tristesse"}
CTRL_FR = {"CONTROLLABLE": "contrôlable", "UNCONTROLLABLE": "non contrôlable", "MIXED": "partiellement contrôlable"}
DIFF_FR = {"LOW": "Faible", "MODERATE": "Modérée", "HIGH": "Élevée"}


def entete(story, titre, sous_titre, modele, refs, corrige, mesures, lecture):
    story.append(Paragraph(titre, H1))
    story.append(Paragraph(sous_titre, SMALL))
    story.append(Spacer(1, 8))
    story.append(Paragraph(AVERTISSEMENT, P))
    story.append(Paragraph("Modèle scientifique retenu", H2))
    story.append(Paragraph(modele, P))
    story.append(Paragraph("Références", H2))
    for r in refs:
        story.append(Paragraph("• " + r, SMALL))
    story.append(Paragraph("Défauts de la banque actuelle corrigés par construction", H2))
    for c in corrige:
        story.append(Paragraph("• " + c, P))
    story.append(Paragraph("Vérification de l'exploitabilité", H2))
    story.append(Paragraph(
        "Score moyen d'un candidat qui coche toujours la même réponse, sans lire les "
        "situations. Plus il approche du plafond, plus la banque se laisse jouer sans "
        "jugement.", SMALL))
    story.append(Spacer(1, 4))
    t = Table(mesures, colWidths=[75*mm, 28*mm, 62*mm])
    t.setStyle(GRILLE)
    story.append(t)
    story.append(Spacer(1, 6))
    story.append(Paragraph(lecture, SMALL))
    story.append(Paragraph("Méthode de développement — ce qui a été fait, et ce qui manque", H2))
    story.append(Paragraph(
        "La méthode de référence pour un SJT comporte quatre étapes : cadrage des construits "
        "avec des experts, recueil d'<b>incidents critiques réellement vécus</b> auprès de "
        "titulaires du poste, production des réactions possibles par d'autres titulaires, "
        "puis cotation de l'efficacité par un panel d'experts. Les SJT construits sur une "
        "analyse de poste atteignent une validité de 0,38 contre 0,29 pour les autres.<br/><br/>"
        "<b>Aucune de ces quatre étapes n'a été réalisée ici.</b> Les situations sont "
        "plausibles, non recueillies ; la clé est dérivée de la théorie et non d'un panel. "
        "Ce document apporte trois choses : un <b>gabarit</b> conforme aux instruments "
        "publiés, des <b>contraintes de conception vérifiées</b> (position neutre, clé "
        "distribuée, correspondance théorique) applicables à n'importe quel contenu, et une "
        "base de discussion concrète. Il ne remplace pas le recueil de terrain.", SMALL))
    story.append(PageBreak())


def validation():
    t = Table([[Paragraph("<b>Avis du psychologue</b> — cotation à confirmer ou corriger, "
                          "contexte à préciser :", CELL)]],
              colWidths=[165*mm], rowHeights=[14*mm])
    t.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#CCCCCC')),
        ('BACKGROUND', (0, 0), (0, 0), colors.HexColor('#FAFAFA')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    return t


def mesures_tr():
    s = TR.SITUATIONS
    lignes = [["Conduite", "Score moyen", "Part du plafond"]]
    for t in ["REFORMULATE_CALMLY", "ASK_FOR_MORE_INFORMATION", "BREATHE_ANALYZE",
              "WAIT", "RESPOND_IMPULSIVELY"]:
        v = [c[2] for x in s for c in x['choices'] if c[0] == t]
        moy = sum(v) / len(v)
        lignes.append([f"Toujours « {TYPE_FR[t]} »", f"{moy:.2f} / 3", f"{moy/3*100:.0f} %"])
    al = sum(sum(c[2] for c in x['choices']) / 5 for x in s) / len(s)
    lignes.append(["Réponses au hasard", f"{al:.2f} / 3", f"{al/3*100:.0f} %"])
    lignes.append(["Réponse optimale partout", "3,00 / 3", "100 %"])
    return lignes


def mesures_cs():
    s = CS.SITUATIONS
    lignes = [["Conduite", "Score moyen", "Part du plafond"]]
    ordre = sorted(STRAT_FR, key=lambda st: -sum(x['scores'][st] for x in s))
    for st in ordre:
        moy = sum(x['scores'][st] for x in s) / len(s)
        lignes.append([f"Toujours « {STRAT_FR[st]} »", f"{moy:.2f} / 3", f"{moy/3*100:.0f} %"])
    al = sum(sum(x['scores'].values()) / 8 for x in s) / len(s)
    lignes.append(["Réponses au hasard", f"{al:.2f} / 3", f"{al/3*100:.0f} %"])
    lignes.append(["Stratégie optimale partout", "3,00 / 3", "100 %"])
    return lignes


def pdf_temps_reflexif(chemin):
    doc = SimpleDocTemplate(chemin, pagesize=A4, topMargin=16*mm, bottomMargin=16*mm,
                            leftMargin=20*mm, rightMargin=20*mm,
                            title="Temps Réflexif — proposition de banque")
    story = []
    entete(
        story,
        "Temps Réflexif — proposition de banque",
        "20 situations · 10 catégories · format Situational Judgment Test · "
        "document de relecture",
        "Le jeu reproduit le format du <b>Situational Test of Emotion Management</b> (STEM), "
        "test publié et validé de gestion émotionnelle : une situation, plusieurs réactions "
        "possibles, une cotation par réaction, une clé établie par jugement d'experts. Le "
        "STEM couvre trois émotions — peur, colère, tristesse — et cette banque reprend ce "
        "blueprint. Les cinq types de réponse du jeu correspondent aux points d'action du "
        "modèle processuel de Gross : « reformuler calmement » relève de la réévaluation "
        "cognitive, « respirer » de la modulation de la réponse. Le délai et l'exactitude, "
        "tous deux déjà collectés, forment les axes du tempo conceptuel de Kagan.",
        ["MacCann, C., &amp; Roberts, R. D. (2008). New paradigms for assessing emotional "
         "intelligence: Theory and data. <i>Emotion</i>, 8(4), 540–551. <b>— le STEM, test "
         "publié dont cette banque reprend le format.</b>",
         "Allen, V. <i>et al.</i> (2015). The Situational Test of Emotional Management – "
         "Brief (STEM-B). <i>Personality and Individual Differences</i> — version courte, "
         "développée par théorie de réponse à l'item.",
         "Motowidlo, S. J., Dunnette, M. D., &amp; Carter, G. W. (1990). An alternative "
         "selection procedure: The low-fidelity simulation. <i>Journal of Applied "
         "Psychology</i>, 75, 640–647.",
         "McDaniel, M. A., Morgeson, F. P., Finnegan, E. B., Campion, M. A., &amp; "
         "Braverman, E. P. (2001). Use of situational judgment tests to predict job "
         "performance. <i>Journal of Applied Psychology</i>, 86(4), 730–740.",
         "McDaniel, M. A., Hartman, N. S., Whetzel, D. L., &amp; Grubb, W. L. III (2007). "
         "Situational judgment tests, response instructions, and validity: A meta-analysis. "
         "<i>Personnel Psychology</i>, 60, 63–91.",
         "Kagan, J. (1966). Reflection-impulsivity: The generality and dynamics of "
         "conceptual tempo. <i>Journal of Abnormal Psychology</i>, 71, 17–24.",
         "Gross, J. J. (1998). The emerging field of emotion regulation: An integrative "
         "review. <i>Review of General Psychology</i>, 2(3), 271–299."],
        ["<b>La position ne trahit plus la catégorie.</b> Dans la banque livrée, « A » est "
         "la réponse impulsive des soixante fiches et « B » toujours « respirer » : la "
         "grille s'apprend en deux ou trois situations et se répond sans lire la scène. "
         "Ici l'ordre est mélangé à la rédaction, item par item.",
         "<b>Un seul « 2 » par situation.</b> Une clé qui accorde un score élevé à une "
         "réponse globalement adaptée, même hors contexte, cesse de discriminer. Chaque "
         "item propose donc une seule seconde réponse défendable.",
         "<b>Des situations réellement écrites.</b> La banque livrée déclare soixante "
         "mini-vidéos et aucun message, et ne fournit le texte littéral d'aucun. Six "
         "situations ici sont des messages, avec leur contenu exact : elles sont jouables "
         "sans attendre la production vidéo."],
        mesures_tr(),
        "<b>Lecture.</b> L'écart entre la meilleure conduite constante et le hasard mesure "
        "ce qu'un candidat gagne en appliquant une règle sans juger. Il reste non nul : "
        "c'est une propriété connue des SJT, que la littérature traite par la cotation de "
        "panel plutôt qu'en aplatissant la clé.")

    for x in TR.SITUATIONS:
        mots = len(x['context'].split()) + len(x['question'].split()) + \
            sum(len(c[1].split()) for c in x['choices'])
        delai = round(mots / 3.5 + (3 if x['diff'] == "LOW" else 4 if x['diff'] == "MODERATE" else 5))
        bloc = [Paragraph(f"{x['id']} — {x['title']}", ITEM),
                Paragraph(f"Catégorie {x['cat']} · {x['cat_label']} — difficulté "
                          f"{DIFF_FR[x['diff']]} — support "
                          f"{'message écrit' if x['medium'] == 'WRITTEN' else 'mini-vidéo'} — "
                          f"délai calculé {delai} s ({mots} mots à lire) — émotion à gérer "
                          f"{EMO_FR[x['targetEmotion']]}", SMALL),
                Spacer(1, 3),
                Paragraph(f"<b>Contexte.</b> {x['context']}", P)]
        if x['message']:
            bloc.append(Spacer(1, 2))
            bloc.append(Paragraph(f"<b>Message affiché.</b> <i>{x['message']}</i>", P))
        bloc.append(Spacer(1, 2))
        bloc.append(Paragraph(f"<b>Question.</b> {x['question']}", P))
        bloc.append(Spacer(1, 4))
        lignes = [["Réaction proposée", "Type", "Score", "Justification"]]
        for t, texte, score, just in x['choices']:
            lignes.append([Paragraph(texte, CELL), Paragraph(TYPE_FR[t], CELL),
                           str(score), Paragraph(just, CELL)])
        tb = Table(lignes, colWidths=[52*mm, 32*mm, 11*mm, 70*mm])
        tb.setStyle(GRILLE)
        bloc.append(tb)
        bloc.append(Spacer(1, 3))
        bloc.append(validation())
        story.append(KeepTogether(bloc))
    doc.build(story)


def pdf_choix_strategiques(chemin):
    doc = SimpleDocTemplate(chemin, pagesize=A4, topMargin=16*mm, bottomMargin=16*mm,
                            leftMargin=20*mm, rightMargin=20*mm,
                            title="Choix Stratégiques — proposition de banque")
    story = []
    entete(
        story,
        "Choix Stratégiques — proposition de banque",
        "20 situations · 8 stratégies de coping · document de relecture",
        "Les huit stratégies du jeu recoupent les échelles du <b>Brief COPE</b> de Carver — "
        "« humour » et « chercher du soutien » en sont les intitulés exacts. Carver "
        "<b>regroupe</b> ses échelles en centrées problème, centrées émotion et "
        "dysfonctionnelles ; il ne les ordonne jamais, parce que l'efficacité d'une "
        "stratégie dépend du contexte.<br/><br/>"
        "La clé de cette banque ne repose donc pas sur un jugement au cas par cas, mais sur "
        "l'<b>hypothèse de correspondance</b> (goodness-of-fit) de Lazarus &amp; Folkman, "
        "testée par Forsythe &amp; Compas : le coping centré sur l'émotion est adapté aux "
        "situations <b>non contrôlables</b>, le coping centré sur le problème aux situations "
        "<b>contrôlables</b>. Chaque situation porte donc une appréciation explicite de "
        "contrôlabilité, et la cotation en découle. C'est une prédiction théorique — donc "
        "vérifiable, et réfutable par le psychologue.",
        ["Forsythe, C. J., &amp; Compas, B. E. (1987). Interaction of cognitive appraisals of "
         "stressful events and coping: Testing the goodness of fit hypothesis. <i>Cognitive "
         "Therapy and Research</i>, 11(4), 473–485. <b>— fonde la clé de cette banque.</b>",
         "Park, C. L., Folkman, S., &amp; Bove, D. (2001). Appraised control, coping, and "
         "stress in a community sample: A test of the goodness-of-fit hypothesis. <i>Annals "
         "of Behavioral Medicine</i>, 23(3), 158–165.",
         "Carver, C. S., Scheier, M. F., &amp; Weintraub, J. K. (1989). Assessing coping "
         "strategies: A theoretically based approach. <i>Journal of Personality and Social "
         "Psychology</i>, 56(2), 267–283.",
         "Carver, C. S. (1997). You want to measure coping but your protocol's too long: "
         "Consider the Brief COPE. <i>International Journal of Behavioral Medicine</i>, 4, "
         "92–100.",
         "Lazarus, R. S., &amp; Folkman, S. (1984). <i>Stress, Appraisal, and Coping</i>. "
         "New York : Springer.",
         "Skinner, E. A., Edge, K., Altman, J., &amp; Sherwood, H. (2003). Searching for the "
         "structure of coping. <i>Psychological Bulletin</i>, 129(2), 216–269.",
         "Garnefski, N., Kraaij, V., &amp; Spinhoven, P. (2001). Negative life events, "
         "cognitive emotion regulation and emotional problems. <i>Personality and Individual "
         "Differences</i>, 30, 1311–1327."],
        ["<b>La meilleure stratégie est distribuée.</b> Dans la banque livrée, "
         "« communication assertive » est la mieux cotée de 24 fiches sur 60 : la cocher "
         "partout rapporte 67 % du plafond sans lire les scènes. Ici, six stratégies se "
         "partagent les meilleures places, et aucune ne dépasse un quart des situations.",
         "<b>« Ruminer » n'est plus un leurre constant.</b> Cotée 0 dans les soixante "
         "fiches livrées, elle ne départageait plus personne au-delà du premier essai. "
         "Elle reste la moins adaptative, mais varie selon que ressasser coupe ou non "
         "l'action.",
         "<b>Deux stratégies restent explicitement non tranchées.</b> « Chercher du "
         "soutien » recouvre chez Carver deux échelles distinctes — soutien émotionnel et "
         "soutien instrumental — et « respirer » relève plutôt de la modulation de la "
         "réponse chez Gross que d'une échelle du COPE. Les ranger d'office fausserait le "
         "profil : elles sont comptées à part."],
        mesures_cs(),
        "<b>Lecture.</b> Aucune stratégie constante n'atteint les deux tiers du plafond, et "
        "l'écart au hasard de la meilleure d'entre elles est réduit de moitié par rapport à "
        "la banque actuelle.")

    story.append(Paragraph("Vérification de l'hypothèse de correspondance", H2))
    story.append(Paragraph(
        "Si la clé suit bien la théorie, le coping centré problème doit dominer dans les "
        "situations contrôlables, et le coping centré émotion dans les non contrôlables. "
        "Ce tableau le mesure sur la banque entière.", SMALL))
    story.append(Spacer(1, 4))
    lignes = [["Contrôlabilité", "Situations", "Centré problème", "Centré émotion", "Verdict"]]
    PB = [CS.ASSERTIVE, CS.ACTION]
    EM = [CS.REAPPRAISAL, CS.HUMOR]
    for c in ["CONTROLLABLE", "UNCONTROLLABLE", "MIXED"]:
        g = [x for x in CS.SITUATIONS if x['controllability'] == c]
        pb = sum(x['scores'][k] for x in g for k in PB) / (len(g) * 2)
        em = sum(x['scores'][k] for x in g for k in EM) / (len(g) * 2)
        if c == "CONTROLLABLE":
            v = "conforme" if pb > em else "NON CONFORME"
        elif c == "UNCONTROLLABLE":
            v = "conforme" if em > pb else "NON CONFORME"
        else:
            v = "les deux admises"
        lignes.append([CTRL_FR[c], str(len(g)), f"{pb:.2f}", f"{em:.2f}", v])
    t = Table(lignes, colWidths=[45*mm, 22*mm, 32*mm, 32*mm, 34*mm])
    t.setStyle(GRILLE)
    story.append(t)
    story.append(Spacer(1, 4))
    conformes = sum(1 for x in CS.SITUATIONS if (
        x['controllability'] == "CONTROLLABLE"
        and max(x['scores'][k] for k in PB) >= max(x['scores'][k] for k in EM))
        or (x['controllability'] == "UNCONTROLLABLE"
            and max(x['scores'][k] for k in EM) >= max(x['scores'][k] for k in PB))
        or x['controllability'] == "MIXED")
    story.append(Paragraph(
        f"<b>{conformes} situations sur {len(CS.SITUATIONS)}</b> sont individuellement "
        "conformes à la prédiction théorique.", SMALL))
    story.append(PageBreak())

    for x in CS.SITUATIONS:
        bloc = [Paragraph(f"{x['id']} — {x['title']}", ITEM),
                Paragraph(f"Situation {CTRL_FR[x['controllability']]} — stratégie la mieux "
                          f"cotée : {STRAT_FR[x['best']]} — support "
                          f"{'message écrit' if x.get('medium') == 'WRITTEN' else 'mini-vidéo'}",
                          SMALL),
                Spacer(1, 3),
                Paragraph(f"<b>Contexte.</b> {x['context']}", P)]
        if x.get('message'):
            bloc.extend([
                Spacer(1, 2),
                Paragraph(f"<b>Message affiché.</b> <i>{x['message']}</i>", P),
            ])
        bloc.extend([
            Spacer(1, 2),
            Paragraph(f"<b>Scène.</b> {x['scene']}", P),
            Spacer(1, 4),
        ])
        lignes = [["Stratégie", "Famille (Carver)", "Score"]]
        for st, sc in sorted(x['scores'].items(), key=lambda kv: -kv[1]):
            lignes.append([Paragraph(STRAT_FR[st], CELL),
                           Paragraph(FAM_FR[CS.FAMILLE[st]], CELL), str(sc)])
        tb = Table(lignes, colWidths=[62*mm, 45*mm, 14*mm])
        tb.setStyle(GRILLE)
        bloc.append(tb)
        bloc.append(Spacer(1, 3))
        bloc.append(Paragraph(f"<b>Justification.</b> {x['note']}", SMALL))
        bloc.append(Spacer(1, 3))
        bloc.append(validation())
        story.append(KeepTogether(bloc))
    doc.build(story)


def export_json():
    tr = []
    for x in TR.SITUATIONS:
        mots = len(x['context'].split()) + len(x['question'].split()) + \
            sum(len(c[1].split()) for c in x['choices'])
        tr.append(dict(
            id=x['id'], title=x['title'], categoryNumber=x['cat'], category=x['cat_label'],
            difficulty=x['diff'], medium=x['medium'], context=x['context'],
            message=x['message'], question=x['question'],
            wordsToRead=mots,
            responseDeadlineSec=round(mots / 3.5 + (3 if x['diff'] == "LOW" else 4 if x['diff'] == "MODERATE" else 5)),
            pilotValidated=False, needsPsychologistValidation=True,
            choices=[dict(text=t[1], responseType=t[0], score=t[2], rationale=t[3])
                     for t in x['choices']]))
    cs = []
    for x in CS.SITUATIONS:
        situation = dict(
            id=x['id'], title=x['title'], context=x['context'], scene=x['scene'],
            medium=x.get('medium', 'VIDEO'), needsPsychologistValidation=True,
            rationale=x['note'],
            choices=[dict(strategy=st, family=CS.FAMILLE[st], score=sc)
                     for st, sc in x['scores'].items()])
        if x.get('message'):
            situation['message'] = x['message']
        cs.append(situation)
    for nom, data in [("temps_reflexif_proposition.json", tr),
                      ("choix_strategiques_proposition.json", cs)]:
        with open(nom, "w", encoding="utf-8") as f:
            json.dump({"statut": "PROPOSITION — non validée cliniquement",
                       "situations": data}, f, ensure_ascii=False, indent=2)
            f.write("\n")


if __name__ == "__main__":
    pdf_temps_reflexif("Temps_Reflexif_proposition_banque.pdf")
    pdf_choix_strategiques("Choix_Strategiques_proposition_banque.pdf")
    export_json()
    print("PDF et JSON générés")
