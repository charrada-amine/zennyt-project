# -*- coding: utf-8 -*-
"""Etat d'avancement Fit Score — PDF pour le superviseur."""
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle)

SORTIE = r"C:\Users\Ghassen\Documents\zennyt-project\zennyt-project\ETAT_AVANCEMENT_FITSCORE.pdf"

BLEU = colors.HexColor("#1B3B7B")
VERT = colors.HexColor("#1B7B4F")
GRIS = colors.HexColor("#F1F5F9")
GRIS_T = colors.HexColor("#64748B")
ROUGE = colors.HexColor("#B91C1C")
ORANGE = colors.HexColor("#C2620A")

s = getSampleStyleSheet()
titre = ParagraphStyle("t", parent=s["Title"], fontSize=20, textColor=BLEU, spaceAfter=4)
sous = ParagraphStyle("st", parent=s["Normal"], fontSize=10, textColor=GRIS_T, spaceAfter=16)
h1 = ParagraphStyle("h1", parent=s["Heading1"], fontSize=14, textColor=BLEU, spaceBefore=16, spaceAfter=8)
h2 = ParagraphStyle("h2", parent=s["Heading2"], fontSize=11, textColor=colors.black, spaceBefore=12, spaceAfter=6)
corps = ParagraphStyle("c", parent=s["Normal"], fontSize=9.5, leading=14, alignment=TA_LEFT, spaceAfter=6)
petit = ParagraphStyle("p", parent=s["Normal"], fontSize=8.5, leading=12, textColor=GRIS_T)
cell = ParagraphStyle("cell", parent=s["Normal"], fontSize=8.5, leading=11.5)
cellb = ParagraphStyle("cellb", parent=s["Normal"], fontSize=8.5, leading=11.5, fontName="Helvetica-Bold")


def tableau(donnees, largeurs, entete=True):
    t = Table(donnees, colWidths=largeurs, repeatRows=1 if entete else 0)
    style = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#CBD5E1")),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    if entete:
        style += [("BACKGROUND", (0, 0), (-1, 0), BLEU),
                  ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                  ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                  ("FONTSIZE", (0, 0), (-1, 0), 8.5)]
        for i in range(2, len(donnees), 2):
            style.append(("BACKGROUND", (0, i), (-1, i), GRIS))
    t.setStyle(TableStyle(style))
    return t


def P(txt, st=cell):
    return Paragraph(txt, st)


doc = SimpleDocTemplate(SORTIE, pagesize=A4,
                        leftMargin=1.8 * cm, rightMargin=1.8 * cm,
                        topMargin=1.8 * cm, bottomMargin=1.8 * cm,
                        title="Fit Score - Etat d'avancement",
                        author="Equipe Recruitment")
h = []

# ---------------------------------------------------------------- page 1
h.append(Paragraph("Fit Score &mdash; &Eacute;tat d'avancement", titre))
h.append(Paragraph("Audit du cahier des charges v3 et remise en conformit&eacute; &middot; "
                   "&Eacute;quipe Recruitment &middot; 7 ao&ucirc;t 2026", sous))

h.append(Paragraph("R&eacute;sum&eacute;", h1))
h.append(P("L'audit du Fit Score contre son cahier des charges a relev&eacute; "
           "<b>32 &eacute;carts</b>. La moiti&eacute; est corrig&eacute;e et v&eacute;rifi&eacute;e, "
           "l'autre moiti&eacute; reste &agrave; traiter et tient enti&egrave;rement dans un seul lot de travail.", corps))

h.append(Spacer(1, 6))
h.append(tableau([
    [P("Lot", cellb), P("Contenu", cellb), P("Avancement", cellb)],
    [P("<b>Phase 0</b>"), P("Pr&eacute;paration commune"), P("<b>8 / 8</b> termin&eacute;")],
    [P("<b>Track A</b>"), P("Moteur de calcul et cha&icirc;ne de mesure"), P("<b>12 / 12</b> termin&eacute;")],
    [P("<b>Track B</b>"), P("R&eacute;f&eacute;rentiel, alertes, API et mobile"), P("<b>0 / 16</b> &agrave; faire")],
], [2.6 * cm, 9.4 * cm, 5 * cm]))

h.append(Spacer(1, 10))
h.append(P("<b>409 tests automatis&eacute;s au vert.</b> Chaque correction a &eacute;t&eacute; v&eacute;rifi&eacute;e "
           "sur une base de donn&eacute;es recr&eacute;&eacute;e &agrave; z&eacute;ro, application d&eacute;marr&eacute;e "
           "et API interrog&eacute;e &mdash; pas seulement en test unitaire.", corps))

h.append(Paragraph("Trois r&eacute;sultats marquants", h1))
h.append(tableau([
    [P("V&eacute;rification", cellb), P("Avant", cellb), P("Maintenant", cellb)],
    [P("Deux infirmi&egrave;res oppos&eacute;es sur la r&eacute;gulation &eacute;motionnelle "
       "(95 et 20 sur 100), sur un m&eacute;tier o&ugrave; cette qualit&eacute; compte pour 45 %"),
     P("<b>61 et 61</b><br/>indistinguables"), P("<b>80 et 38</b>")],
    [P("Sauter un mini-jeu qu'on aurait rat&eacute;"),
     P("<b>+11 points</b><br/>gagn&eacute;s"), P("<b>&minus;6 points</b>")],
    [P("Branche principale du projet"),
     P("<b>ne d&eacute;marrait pas</b>"), P("d&eacute;marre, API &agrave; 200")],
], [7.4 * cm, 4.8 * cm, 4.8 * cm]))

h.append(Paragraph("Phase 0 &mdash; termin&eacute;e", h1))
h.append(tableau([
    [P("T&acirc;che", cellb), P("Objet", cellb)],
    [P("P0.1"), P("Plages de num&eacute;ros de migration r&eacute;serv&eacute;es par lot")],
    [P("P0.2"), P("Horodatage du r&eacute;f&eacute;rentiel de pond&eacute;ration")],
    [P("P0.3"), P("Seuil de fiabilit&eacute; corrig&eacute; (il regardait la mauvaise information)")],
    [P("P0.4"), P("Fichier mort supprim&eacute; des sources")],
    [P("P0.5"), P("Filet de test partag&eacute; entre les deux lots")],
    [P("P0.6"), P("&Eacute;chelle des niveaux d'exp&eacute;rience remise conforme au cahier des charges")],
    [P("P0.7"), P("Report du niveau 3 d'h&eacute;ritage consign&eacute; par &eacute;crit")],
    [P("P0.8"), P("Branches de travail cr&eacute;&eacute;es")],
], [2.6 * cm, 14.4 * cm]))

h.append(PageBreak())

# ---------------------------------------------------------------- page 2
h.append(Paragraph("Track A &mdash; termin&eacute;", h1))
h.append(P("Le moteur de calcul et la cha&icirc;ne de mesure des jeux. "
           "<b>5 corrections livr&eacute;es</b>, branche pouss&eacute;e, pr&ecirc;te &agrave; fusionner.", corps))
h.append(Spacer(1, 4))
h.append(tableau([
    [P("T&acirc;ches", cellb), P("Ce qui &eacute;tait cass&eacute;", cellb)],
    [P("F01 F02<br/>F21 F22"),
     P("Un module de jeu inconnu du syst&egrave;me devenait <b>tout le score</b>. "
       "L'absence totale de donn&eacute;e &eacute;tait enregistr&eacute;e comme un <b>z&eacute;ro mesur&eacute;</b>, "
       "servi au recruteur comme si le candidat avait &eacute;chou&eacute;.")],
    [P("F03"),
     P("Module R&eacute;gulation &eacute;motionnelle &mdash; <i>livr&eacute; par l'&eacute;quipe Jeux</i>, "
       "r&eacute;cup&eacute;r&eacute; lors de la fusion.")],
    [P("F13 F15"),
     P("La <b>couverture r&eacute;elle</b> de chaque jeu : combien en a &eacute;t&eacute; jou&eacute;. "
       "Le cahier des charges la pr&eacute;voit ; elle n'existait nulle part et valait 100 % en dur.")],
    [P("F14"),
     P("Une partie interrompue ne produisait <b>rien du tout</b>. Les jeux envoient "
       "d&eacute;sormais un r&eacute;sultat &agrave; chaque mini-jeu.")],
    [P("F07 F08"),
     P("Un module = un poids, compt&eacute; une seule fois. Et un jeu qui n'existe pour "
       "personne ne p&eacute;nalise personne.")],
    [P("F12"),
     P("Aucun score n'&eacute;tait recalcul&eacute; quand la pond&eacute;ration changeait &mdash; "
       "or c'est exactement ce que produira l'atelier RH.")],
    [P("F27"),
     P("Annul&eacute; apr&egrave;s v&eacute;rification : ce n'&eacute;tait pas un bug.")],
], [2.6 * cm, 14.4 * cm]))

h.append(Paragraph("Track B &mdash; &agrave; faire (16 t&acirc;ches)", h1))
h.append(P("Le r&eacute;f&eacute;rentiel des m&eacute;tiers, les alertes recruteur, l'API et l'application mobile. "
           "C'est tout ce qui reste c&ocirc;t&eacute; code.", corps))
h.append(Spacer(1, 4))
h.append(tableau([
    [P("Gravit&eacute;", cellb), P("T&acirc;che", cellb), P("Quoi", cellb)],
    [P("<font color='#B91C1C'><b>Critique</b></font>"), P("<b>F06</b>"),
     P("Le mobile n'envoie pas le m&eacute;tier : <b>la cr&eacute;ation d'offre &eacute;choue</b>")],
    [P("<font color='#B91C1C'><b>Critique</b></font>"), P("<b>F05</b>"),
     P("Niveaux d'alerte faux sur <b>12 lignes sur 24</b>")],
    [P("<font color='#C2620A'>&Eacute;lev&eacute;</font>"), P("F10"),
     P("La fiche candidat affiche <b>3 lignes identiques</b>, invent&eacute;es &agrave; partir d'une seule valeur")],
    [P("<font color='#C2620A'>&Eacute;lev&eacute;</font>"), P("F16"),
     P("Les 3 avertissements de fiabilit&eacute; ne sont affich&eacute;s nulle part")],
    [P("<font color='#C2620A'>&Eacute;lev&eacute;</font>"), P("F18"),
     P("Phrase &laquo; m&eacute;tier cr&eacute;atif, consultez le portfolio &raquo; absente du r&eacute;sum&eacute;")],
    [P("<font color='#C2620A'>&Eacute;lev&eacute;</font>"), P("F09"),
     P("Les descriptions du classifieur contredisent la matrice des 142 m&eacute;tiers")],
    [P("<font color='#C2620A'>&Eacute;lev&eacute;</font>"), P("F32"),
     P("Mode d'&eacute;valuation (quiz ou portfolio) &agrave; d&eacute;placer par m&eacute;tier")],
    [P("Moyen"), P("F17 F19<br/>F20 F30"),
     P("Contextes d'affichage manquants, texte d'alerte absent, requ&ecirc;tes en trop, "
       "pr&eacute;remplissage jamais consomm&eacute;")],
    [P("Faible"), P("F23 F24<br/>F25 F28 F29"),
     P("Quiz non attachable &agrave; la cr&eacute;ation, contrainte d'unicit&eacute; inop&eacute;rante, "
       "courbe non verrouill&eacute;e par un test, mode &laquo; soft seul &raquo; non document&eacute;")],
], [2.4 * cm, 2.2 * cm, 12.4 * cm]))

h.append(PageBreak())

# ---------------------------------------------------------------- page 3
h.append(Paragraph("Ce qui ne d&eacute;pend pas du code", h1))
h.append(tableau([
    [P("Sujet", cellb), P("D&eacute;pend de", cellb), P("&Eacute;tat", cellb)],
    [P("<b>Les 30 sc&eacute;narios de &laquo; Je D&eacute;cide &raquo;</b><br/>"
       "<font size=8 color='#64748B'>Le jeu est enti&egrave;rement d&eacute;velopp&eacute;, &eacute;crans mobiles compris. "
       "Seul le contenu manque.</font>"),
     P("Psychologue"), P("<font color='#B91C1C'><b>Bloqu&eacute;</b></font>")],
    [P("<b>Num&eacute;ros de migration de l'&eacute;quipe Jeux</b><br/>"
       "<font size=8 color='#64748B'>Leurs 3 nouveaux jeux reprennent des num&eacute;ros d&eacute;j&agrave; pris. "
       "M&ecirc;me panne que celle r&eacute;par&eacute;e le 4 ao&ucirc;t. Les num&eacute;ros jusqu&#39;&agrave; V58 inclus sont d&eacute;j&agrave; utilis&eacute;s.</font>"),
     P("&Eacute;quipe Jeux"), P("<font color='#B91C1C'><b>&Agrave; leur dire :<br/>partir de V59</b></font>")],
    [P("<b>Calibrage des pond&eacute;rations</b><br/>"
       "<font size=8 color='#64748B'>Les valeurs actuelles sont marqu&eacute;es &laquo; non calibr&eacute;es &raquo; en base.</font>"),
     P("Atelier RH"), P("Pr&eacute;vu")],
    [P("<b>Grille d'&eacute;valuation des portfolios</b>"), P("RH"), P("Report&eacute;")],
    [P("<b>R&eacute;glages par entreprise et par offre</b>"), P("Produit"), P("Report&eacute;s")],
], [8.4 * cm, 3.6 * cm, 5 * cm]))

h.append(Paragraph("Point ferm&eacute; : le changement des niveaux d'exp&eacute;rience", h1))
h.append(P("Ce point &eacute;tait signal&eacute; comme &laquo; &agrave; faire : pr&eacute;venir l'&eacute;quipe web &raquo;. "
           "V&eacute;rification faite : <b>il n'y a pas d'&eacute;quipe web s&eacute;par&eacute;e</b> &mdash; les contextes "
           "du projet sont Identity, Recruitment et Engagement.", corps))
h.append(Spacer(1, 4))
h.append(tableau([
    [P("V&eacute;rification", cellb), P("R&eacute;sultat", cellb)],
    [P("Identity, Engagement et Analytics utilisent-ils le niveau d'exp&eacute;rience&nbsp;?"),
     P("<b>Non</b>, aucune r&eacute;f&eacute;rence")],
    [P("Un &eacute;v&eacute;nement sortant de Recruitment le transporte-t-il&nbsp;?"),
     P("<b>Non</b>, aucun")],
    [P("Reste-t-il une ancienne valeur quelque part dans le code&nbsp;?"),
     P("<b>Non</b>, balayage complet du d&eacute;p&ocirc;t")],
], [11.4 * cm, 5.6 * cm]))
h.append(Spacer(1, 8))
h.append(P("<b>Conclusion : aucune casse, personne &agrave; pr&eacute;venir.</b> Le seul consommateur &eacute;tait "
           "l'application mobile, d&eacute;j&agrave; mise &agrave; jour.", corps))
h.append(P("Pour qu'un tel &eacute;cart ne puisse plus se reproduire, un test automatique compare d&eacute;sormais "
           "le contrat de l'API et le code &agrave; chaque compilation, et v&eacute;rifie aussi <b>l'ordre</b> des "
           "niveaux &mdash; c'est le d&eacute;placement de cet ordre, pass&eacute; inaper&ccedil;u, qui avait cr&eacute;&eacute; "
           "le probl&egrave;me &agrave; l'origine. Le garde-fou a &eacute;t&eacute; test&eacute; en r&eacute;introduisant "
           "volontairement l'ancienne liste : il &eacute;choue bien.", corps))

h.append(Paragraph("Prochaines &eacute;tapes", h1))
h.append(tableau([
    [P("Qui", cellb), P("Quoi", cellb), P("Quand", cellb)],
    [P("<b>Recruitment</b>"), P("Dire &agrave; l'&eacute;quipe Jeux de partir de <b>V59</b>"),
     P("<font color='#B91C1C'>avant leur fusion</font>")],
    [P("<b>Recruitment</b>"), P("Relancer sur les 30 sc&eacute;narios de &laquo; Je D&eacute;cide &raquo;"),
     P("<font color='#C2620A'>cette semaine</font>")],
    [P("<b>D&eacute;v.</b>"), P("Track B &mdash; 16 t&acirc;ches, en commen&ccedil;ant par F06"), P("en attente")],
    [P("<b>Produit</b>"),
     P("Combien de jeux faut-il jouer pour couvrir un module&nbsp;?"), P("avant lancement")],
], [3 * cm, 9 * cm, 5 * cm]))

h.append(Spacer(1, 14))
h.append(Paragraph("Documents de r&eacute;f&eacute;rence dans le d&eacute;p&ocirc;t : "
                   "<b>FITSCORE_REMEDIATION.md</b> (les 32 &eacute;carts en d&eacute;tail) &middot; "
                   "<b>SITUATION.md</b> (o&ugrave; on en est) &middot; "
                   "<b>COMPTE_RENDU_03-05_AOUT_2026.md</b> (le r&eacute;cit des trois jours)", petit))

doc.build(h)
print("PDF cree :", SORTIE)
