# -*- coding: utf-8 -*-
"""Convertit un document Markdown du projet en PDF lisible par un encadrant.

Ne vise pas le Markdown complet : uniquement les constructions réellement employées
dans les documents de cadrage Zennyt — titres, tableaux, blocs de code, citations,
listes, gras/italique/code inline, filets horizontaux.

    python docs/md_to_pdf.py MON_DOCUMENT.md [sortie.pdf]

Les emoji sont remplacés par des marqueurs textuels : les polices intégrées de
reportlab ne les rendent pas, et un carré noir dans un tableau est pire que rien.
"""
import html
import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (HRFlowable, KeepTogether, Paragraph, SimpleDocTemplate,
                                Spacer, Table, TableStyle)

BLEU = colors.HexColor("#1B3B7B")
GRIS_FOND = colors.HexColor("#F1F5F9")
GRIS_TEXTE = colors.HexColor("#64748B")
GRIS_TRAIT = colors.HexColor("#CBD5E1")
ORANGE = colors.HexColor("#C2620A")

S = getSampleStyleSheet()
ST = {
    "titre": ParagraphStyle("titre", parent=S["Title"], fontSize=19, textColor=BLEU,
                            spaceAfter=2, alignment=TA_LEFT),
    "h1": ParagraphStyle("h1", parent=S["Heading1"], fontSize=15, textColor=BLEU,
                         spaceBefore=20, spaceAfter=8),
    "h2": ParagraphStyle("h2", parent=S["Heading2"], fontSize=12, textColor=BLEU,
                         spaceBefore=14, spaceAfter=6),
    "h3": ParagraphStyle("h3", parent=S["Heading3"], fontSize=10.5, textColor=colors.black,
                         spaceBefore=11, spaceAfter=5),
    "corps": ParagraphStyle("corps", parent=S["Normal"], fontSize=9.5, leading=14,
                            alignment=TA_LEFT, spaceAfter=7),
    "liste": ParagraphStyle("liste", parent=S["Normal"], fontSize=9.5, leading=14,
                            leftIndent=14, bulletIndent=4, spaceAfter=3),
    "cite": ParagraphStyle("cite", parent=S["Normal"], fontSize=9, leading=13,
                           leftIndent=12, textColor=ORANGE, spaceAfter=8,
                           borderPadding=0),
    "code": ParagraphStyle("code", parent=S["Normal"], fontName="Courier", fontSize=7.6,
                           leading=9.6, textColor=colors.black),
    # Les listes d'avantages / inconvenients : la couleur de la puce porte le sens,
    # puisque les coches et croix ne sont pas rendues par les polices de base.
    "pour": ParagraphStyle("pour", parent=S["Normal"], fontSize=9.5, leading=14,
                           leftIndent=16, bulletIndent=4, spaceAfter=3,
                           bulletFontName="Helvetica-Bold",
                           bulletColor=colors.HexColor("#1B7B4F")),
    "contre": ParagraphStyle("contre", parent=S["Normal"], fontSize=9.5, leading=14,
                             leftIndent=16, bulletIndent=4, spaceAfter=3,
                             bulletFontName="Helvetica-Bold",
                             bulletColor=colors.HexColor("#B91C1C")),
    "cellule": ParagraphStyle("cellule", parent=S["Normal"], fontSize=8.2, leading=11),
    "entete": ParagraphStyle("entete", parent=S["Normal"], fontSize=8.2, leading=11,
                             textColor=colors.white, fontName="Helvetica-Bold"),
    "pied": ParagraphStyle("pied", parent=S["Normal"], fontSize=8, textColor=GRIS_TEXTE),
}

# Les emoji ne sont pas rendus par les polices de base : on les traduit.
#
# Les coches et croix restent ici : en debut de ligne elles deviennent des puces
# colorees et sont retirees avant d'arriver a inline(), mais en milieu de phrase ou
# dans une cellule de tableau elles passent par ce dictionnaire. Sans lui, le PDF
# affichait un carre noir au milieu d'une colonne de resultats.
EMOJI = {
    "✅": "[OK]", "❌": "[NON]", "⚠️": "[!]", "⚠": "[!]",
    "🔧": "[option]", "📋": "[a faire]", "→": "->", "×": "x",
    "≈": "~", "≥": ">=", "≤": "<=", "±": "+/-", "─": "-", "│": "|",
    "┌": "+", "┐": "+", "└": "+", "┘": "+", "▼": "v", "═": "=",
}


def inline(texte):
    """Gras, italique, code inline — vers les balises que reportlab comprend."""
    for source, cible in EMOJI.items():
        texte = texte.replace(source, cible)
    texte = html.escape(texte)
    texte = re.sub(r"`([^`]+)`", r'<font face="Courier" size="8.5">\1</font>', texte)
    texte = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", texte)
    texte = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", texte)
    texte = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", texte)   # liens -> libellé seul
    return texte


def ligne_tableau(ligne):
    return [c.strip() for c in ligne.strip().strip("|").split("|")]


def construire_tableau(lignes, largeur_page):
    """Un tableau Markdown -> un Table reportlab, colonnes réparties au prorata."""
    lignes = [l for l in lignes if not re.match(r"^\s*\|[\s:|-]+\|\s*$", l)]
    donnees = [ligne_tableau(l) for l in lignes]
    nb_col = max(len(r) for r in donnees)
    donnees = [r + [""] * (nb_col - len(r)) for r in donnees]

    # Largeur proportionnelle au contenu, bornée pour qu'aucune colonne n'écrase les autres.
    poids = []
    for i in range(nb_col):
        longueurs = [len(r[i]) for r in donnees]
        poids.append(max(6, min(60, sum(longueurs) / len(longueurs) + max(longueurs) * 0.25)))
    total = sum(poids)
    largeurs = [largeur_page * p / total for p in poids]

    cellules = [[Paragraph(inline(c), ST["entete" if i == 0 else "cellule"]) for c in r]
                for i, r in enumerate(donnees)]

    t = Table(cellules, colWidths=largeurs, repeatRows=1, hAlign="LEFT")
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), BLEU),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.4, GRIS_TRAIT),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ]
    for i in range(1, len(cellules)):
        if i % 2 == 0:
            style.append(("BACKGROUND", (0, i), (-1, i), GRIS_FOND))
    t.setStyle(TableStyle(style))
    return t


def convertir(chemin_md, chemin_pdf):
    texte = Path(chemin_md).read_text(encoding="utf-8")
    lignes = texte.split("\n")

    doc = SimpleDocTemplate(str(chemin_pdf), pagesize=A4,
                            leftMargin=1.8 * cm, rightMargin=1.8 * cm,
                            topMargin=1.6 * cm, bottomMargin=1.6 * cm,
                            title=Path(chemin_md).stem, author="Module Recrutement - Zennyt")
    largeur = doc.width
    flux = []
    i = 0
    premier_titre = True

    while i < len(lignes):
        ligne = lignes[i]

        # Bloc de code encadré par ```
        if ligne.strip().startswith("```"):
            i += 1
            bloc = []
            while i < len(lignes) and not lignes[i].strip().startswith("```"):
                bloc.append(lignes[i])
                i += 1
            i += 1
            contenu = "<br/>".join(
                html.escape(l.replace(" ", " ")) for l in bloc) or "&nbsp;"
            for src, cible in EMOJI.items():
                contenu = contenu.replace(src, cible)
            cadre = Table([[Paragraph(contenu, ST["code"])]], colWidths=[largeur], hAlign="LEFT")
            cadre.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), GRIS_FOND),
                ("BOX", (0, 0), (-1, -1), 0.4, GRIS_TRAIT),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ]))
            flux += [cadre, Spacer(1, 8)]
            continue

        # Tableau
        if ligne.strip().startswith("|"):
            bloc = []
            while i < len(lignes) and lignes[i].strip().startswith("|"):
                bloc.append(lignes[i])
                i += 1
            flux += [construire_tableau(bloc, largeur), Spacer(1, 10)]
            continue

        nu = ligne.strip()

        if not nu:
            i += 1
            continue

        def suite(depart):
            """Recolle les lignes de continuation d'un même élément.

            Un item de liste ou une citation s'écrivent souvent sur plusieurs lignes dans
            le fichier source. Sans ce recollage, chaque ligne devenait un paragraphe
            distinct : la deuxième ligne d'une puce repartait à la marge gauche, et la
            liste cessait d'en être une visuellement.
            """
            morceaux = []
            k = depart
            while (k < len(lignes) and lignes[k].strip()
                   and not re.match(r"^\s*(\||#|>|-{3,}|[-*]\s|\d+\.\s|```|✅|❌)",
                                    lignes[k])):
                morceaux.append(lignes[k].strip())
                k += 1
            return morceaux, k - 1

        if re.match(r"^-{3,}$", nu):
            flux += [Spacer(1, 4), HRFlowable(width="100%", thickness=0.6, color=GRIS_TRAIT),
                     Spacer(1, 8)]
        elif nu.startswith("#"):
            niveau = len(nu) - len(nu.lstrip("#"))
            contenu = nu.lstrip("#").strip()
            if premier_titre and niveau == 1:
                flux.append(Paragraph(inline(contenu), ST["titre"]))
                premier_titre = False
            else:
                flux.append(Paragraph(inline(contenu), ST[f"h{min(niveau, 3)}"]))
        elif nu.startswith(">"):
            bloc = [nu.lstrip("> ").strip()]
            j = i + 1
            while j < len(lignes) and lignes[j].strip().startswith(">"):
                bloc.append(lignes[j].strip().lstrip("> ").strip())
                j += 1
            i = j - 1
            flux.append(Paragraph(inline(" ".join(bloc)), ST["cite"]))
        elif nu[0] in "✅❌":
            style = "pour" if nu[0] == "✅" else "contre"
            bloc = [nu[1:].strip()]
            reste, i = suite(i + 1)
            flux.append(Paragraph(inline(" ".join(bloc + reste)), ST[style],
                                  bulletText="+" if style == "pour" else "–"))
        elif re.match(r"^[-*]\s+", nu):
            bloc = [re.sub(r"^[-*]\s+", "", nu)]
            reste, i = suite(i + 1)
            flux.append(Paragraph(inline(" ".join(bloc + reste)), ST["liste"], bulletText="•"))
        elif re.match(r"^\d+\.\s+", nu):
            num = re.match(r"^(\d+)\.", nu).group(1)
            bloc = [re.sub(r"^\d+\.\s+", "", nu)]
            reste, i = suite(i + 1)
            flux.append(Paragraph(inline(" ".join(bloc + reste)), ST["liste"],
                                  bulletText=f"{num}."))
        else:
            bloc, i = suite(i)
            flux.append(Paragraph(inline(" ".join(bloc)), ST["corps"]))
        i += 1

    def pied(canvas, document):
        canvas.saveState()
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(GRIS_TEXTE)
        canvas.drawString(1.8 * cm, 1.0 * cm, "Module Recrutement - Zennyt")
        canvas.drawRightString(A4[0] - 1.8 * cm, 1.0 * cm, f"page {document.page}")
        canvas.restoreState()

    doc.build(flux, onFirstPage=pied, onLaterPages=pied)
    return chemin_pdf


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("usage: python docs/md_to_pdf.py DOCUMENT.md [sortie.pdf]")
    source = Path(sys.argv[1])
    cible = Path(sys.argv[2]) if len(sys.argv) > 2 else source.with_suffix(".pdf")
    convertir(source, cible)
    print(f"{cible}  ({cible.stat().st_size // 1024} Ko)")
