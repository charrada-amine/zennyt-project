# -*- coding: utf-8 -*-
"""Proposition de banque « Choix Stratégiques » — 20 situations.

Construite sur les échelles de coping de Carver (COPE 1989, Brief COPE 1997) et
sur le cadre de Lazarus & Folkman (1984) : l'efficacité d'une stratégie dépend
du contexte, il n'existe pas de « meilleure » stratégie dans l'absolu.

Deux défauts de la banque actuelle corrigés par construction :

1. MEILLEURE STRATÉGIE DISTRIBUÉE. Dans la banque livrée, « Assertive
   communication » est la mieux cotée de 24 fiches sur 60 : la cocher partout
   rapporte 67 % du plafond sans lire les scènes. Ici, les six stratégies
   adaptatives se partagent les meilleures places.

2. « RUMINATE » N'EST PLUS UN LEURRE CONSTANT. Cotée 0 dans les soixante fiches
   livrées, elle ne départageait personne au-delà du premier essai. Elle reste
   la moins adaptative, mais varie de 0 à 1 selon que ressasser coupe ou non
   l'action.
"""

AVOID, RUMINATE, BREATHE = "AVOID_FLEE", "RUMINATE", "BREATHE_PAUSE"
REAPPRAISAL, ASSERTIVE = "COGNITIVE_REAPPRAISAL", "ASSERTIVE_COMMUNICATION"
HUMOR, SUPPORT, ACTION = "HUMOR", "SEEK_SUPPORT", "DIRECT_ACTION"

FAMILLE = {
    ASSERTIVE: "PROBLEM_FOCUSED", ACTION: "PROBLEM_FOCUSED",
    REAPPRAISAL: "EMOTION_FOCUSED", HUMOR: "EMOTION_FOCUSED",
    AVOID: "DYSFUNCTIONAL", RUMINATE: "DYSFUNCTIONAL",
    SUPPORT: "UNRESOLVED", BREATHE: "UNRESOLVED",
}

def s(avoid, rum, breathe, reap, assertive, humor, support, action):
    return {AVOID: avoid, RUMINATE: rum, BREATHE: breathe, REAPPRAISAL: reap,
            ASSERTIVE: assertive, HUMOR: humor, SUPPORT: support, ACTION: action}

SITUATIONS = [
    dict(id="CS-101", title="La réunion qui déborde", best=BREATHE, controllability="UNCONTROLLABLE",
         context="Une réunion s'éternise ; la tension monte et votre concentration décroche.",
         scene="Le débat tourne en rond depuis vingt minutes. Vous sentez l'agacement gagner et vos réponses devenir plus sèches.",
         scores=s(1, 0, 3, 2, 2, 1, 0, 1),
         note="Aucun enjeu externe : c'est l'état interne qui dégrade la conduite. La régulation physiologique passe avant toute action."),
    dict(id="CS-102", title="Le dossier bloqué chez un tiers", best=SUPPORT, controllability="MIXED",
         context="Votre avancement dépend d'un service qui ne répond plus depuis une semaine.",
         scene="Deux relances sont restées sans réponse. L'échéance approche et vous n'avez aucun levier direct sur ce service.",
         medium="WRITTEN",
         message="« Votre demande a bien été enregistrée. » — seule réponse reçue, il y a huit jours. Vos deux relances depuis sont restées sans réponse.",
         scores=s(1, 0, 1, 1, 2, 0, 3, 2),
         note="Sans levier direct, mobiliser un tiers ayant autorité est la seule voie efficace (soutien instrumental)."),
    dict(id="CS-103", title="L'erreur signalée publiquement", best=ASSERTIVE, controllability="CONTROLLABLE",
         context="Un collègue signale votre erreur devant l'équipe, sur un ton neutre mais devant tous.",
         scene="L'erreur est réelle. Le groupe attend votre réaction.",
         scores=s(0, 1, 2, 2, 3, 1, 1, 2),
         note="L'erreur étant réelle et publique, la reconnaître et dire la correction rétablit la situation immédiatement."),
    dict(id="CS-104", title="Le refus définitif", best=REAPPRAISAL, controllability="UNCONTROLLABLE",
         context="Une candidature interne que vous portiez depuis des mois est refusée sans appel.",
         scene="La décision est prise et ne sera pas réexaminée. Vous restez dans la même équipe.",
         medium="WRITTEN",
         message="« Après examen, votre candidature n'a pas été retenue pour ce poste. La décision est définitive. »",
         scores=s(1, 1, 2, 3, 1, 1, 2, 0),
         note="La situation n'est plus modifiable : le travail porte sur la lecture qu'on en fait, pas sur l'action."),
    dict(id="CS-105", title="La panne pendant le service", best=ACTION, controllability="CONTROLLABLE",
         context="Un équipement tombe en panne au moment le plus chargé de la journée.",
         scene="Les clients attendent. Une solution de contournement existe mais demande d'agir tout de suite.",
         scores=s(0, 0, 1, 1, 2, 0, 2, 3),
         note="Problème solvable, échéance immédiate : l'action directe domine toute régulation émotionnelle."),
    dict(id="CS-106", title="La remarque sur la tenue", best=ASSERTIVE, controllability="CONTROLLABLE",
         context="Un collègue fait une remarque déplacée sur votre apparence, en petit comité.",
         scene="Deux personnes sourient. La remarque n'est pas la première du genre.",
         scores=s(1, 1, 2, 1, 3, 1, 2, 1),
         note="Comportement répété : poser la limite est ce qui l'arrête. Le recadrage cognitif laisserait le comportement intact."),
    dict(id="CS-107", title="L'attente du verdict", best=BREATHE, controllability="UNCONTROLLABLE",
         context="Vous attendez une décision qui vous concerne et qui tombera dans trois jours.",
         scene="Rien de ce que vous ferez d'ici là n'influencera l'issue. Vous y repensez sans arrêt.",
         scores=s(2, 0, 3, 2, 0, 2, 2, 0),
         note="Rien n'est actionnable : la régulation de l'état et la mise à distance sont les seules conduites utiles."),
    dict(id="CS-108", title="La consigne contradictoire", best=ASSERTIVE, controllability="CONTROLLABLE",
         context="Deux responsables vous donnent des instructions incompatibles sur le même dossier.",
         scene="Chacun considère la sienne comme prioritaire. Vous ne pouvez pas satisfaire les deux.",
         medium="WRITTEN",
         message="« Priorité absolue sur le dossier Legrand aujourd'hui. » — et, dix minutes plus tôt : « Rien avant l'audit, on gèle Legrand. »",
         scores=s(0, 0, 1, 1, 3, 0, 2, 1),
         note="Le conflit appartient aux deux demandeurs : le rendre explicite est l'action adaptée."),
    dict(id="CS-109", title="Le trajet interminable", best=REAPPRAISAL, controllability="UNCONTROLLABLE",
         context="Un incident immobilise votre train ; vous manquerez le début d'une réunion importante.",
         scene="Vous avez prévenu. Le retard est acquis et hors de votre contrôle.",
         scores=s(1, 0, 2, 3, 1, 2, 1, 1),
         note="Contrainte externe non modifiable et déjà signalée : reste à en réduire la charge pour arriver disponible."),
    dict(id="CS-110", title="La blague qui tombe à plat", best=HUMOR, controllability="MIXED",
         context="Une maladresse de votre part crée un blanc gênant dans un échange informel.",
         scene="Personne n'est blessé, mais le silence s'installe et tout le monde attend.",
         scores=s(1, 0, 1, 2, 1, 3, 1, 1),
         note="Enjeu social mineur et réparable sur-le-champ : l'humour dissout la gêne mieux qu'une explication."),
    dict(id="CS-111", title="La charge qui s'accumule", best=SUPPORT, controllability="MIXED",
         context="Le volume de travail dépasse depuis trois semaines ce qu'une personne peut absorber.",
         scene="Vous tenez le rythme au prix de vos soirées. Rien n'indique que cela va redescendre.",
         scores=s(0, 1, 1, 1, 2, 0, 3, 2),
         note="Surcharge durable et structurelle : elle se traite par la mobilisation d'un appui, pas par l'effort individuel."),
    dict(id="CS-112", title="La critique du client", best=ACTION, controllability="CONTROLLABLE",
         context="Un client signale un défaut réel sur une livraison, par écrit.",
         scene="Le défaut est avéré et corrigeable dans la journée.",
         medium="WRITTEN",
         message="« Bonjour, nous venons de réceptionner la livraison : la référence ne correspond pas à la commande. Que prévoyez-vous ? »",
         scores=s(0, 0, 1, 1, 2, 0, 1, 3),
         note="Défaut réel et corrigeable : corriger prime sur toute explication."),
    dict(id="CS-113", title="Le silence après l'entretien", best=BREATHE, controllability="UNCONTROLLABLE",
         context="Une semaine après un entretien décisif, aucune nouvelle n'arrive.",
         scene="Le délai annoncé n'est pas encore dépassé. Vous y pensez plusieurs fois par jour.",
         scores=s(2, 0, 3, 2, 1, 1, 2, 1),
         note="Relancer avant le délai annoncé dessert ; la conduite utile est de tenir l'attente."),
    dict(id="CS-114", title="Le collègue qui s'attribue le travail", best=ASSERTIVE, controllability="CONTROLLABLE",
         context="En réunion, un collègue présente comme sien un travail que vous avez réalisé.",
         scene="Plusieurs personnes présentes l'ignorent. Le sujet sera tranché à la fin de la réunion.",
         scores=s(0, 1, 2, 1, 3, 0, 2, 2),
         note="Fenêtre courte et enjeu de reconnaissance : rétablir le fait avant la décision est le seul moment utile."),
    dict(id="CS-115", title="Le projet abandonné", best=REAPPRAISAL, controllability="UNCONTROLLABLE",
         context="Un projet porté pendant un an est arrêté par la direction.",
         scene="La décision est budgétaire et irrévocable. Vous êtes réaffecté dès la semaine prochaine.",
         medium="WRITTEN",
         message="« Le comité a décidé l'arrêt du projet. Votre réaffectation prend effet lundi prochain. »",
         scores=s(1, 1, 2, 3, 1, 1, 2, 0),
         note="Perte non réversible : le travail est celui du sens, pas celui de l'action."),
    dict(id="CS-116", title="L'échéance intenable", best=ACTION, controllability="CONTROLLABLE",
         context="Un délai a été accepté par quelqu'un d'autre à votre place, et il est intenable en l'état.",
         scene="Il reste deux jours. Réduire le périmètre est possible si la décision est prise maintenant.",
         medium="WRITTEN",
         message="« J'ai confirmé au client pour jeudi. Tu gères ? »",
         scores=s(0, 0, 1, 1, 3, 0, 2, 3),
         note="Solvable par une décision immédiate de périmètre : agir et le dire valent également, d'où deux stratégies à 3."),
    dict(id="CS-117", title="La tension qui traîne", best=SUPPORT, controllability="MIXED",
         context="Un désaccord ancien avec un collègue empoisonne les échanges depuis des mois.",
         scene="Les tentatives directes ont échoué deux fois. Le travail commun en souffre.",
         scores=s(1, 0, 1, 2, 1, 1, 3, 2),
         note="Les tentatives directes ayant échoué, un tiers médiateur devient la voie la plus réaliste."),
    dict(id="CS-118", title="Le reproche fondé", best=REAPPRAISAL, controllability="MIXED",
         context="Votre responsable formule une critique désagréable, mais exacte, sur votre méthode.",
         scene="Le fond est juste ; c'est la forme qui pique.",
         scores=s(0, 1, 2, 3, 1, 1, 1, 2),
         note="Séparer le fond utile de la forme désagréable est ce qui permet d'en tirer quelque chose."),
    dict(id="CS-119", title="L'ambiance pesante", best=HUMOR, controllability="UNCONTROLLABLE",
         context="Après une mauvaise nouvelle, l'équipe travaille dans un silence tendu.",
         scene="Rien de grave n'est en jeu dans l'immédiat, mais l'atmosphère bloque les échanges.",
         scores=s(1, 0, 2, 2, 1, 3, 2, 1),
         note="Enjeu de climat collectif sans urgence : l'humour relance les échanges là où une analyse les alourdirait."),
    dict(id="CS-120", title="L'interruption de trop", best=BREATHE, controllability="MIXED",
         context="Pour la cinquième fois de la matinée, on vous coupe dans une tâche qui demande de la concentration.",
         scene="Vous sentez l'irritation monter et vos réponses devenir sèches.",
         scores=s(1, 1, 3, 2, 2, 1, 0, 2),
         note="L'irritation dégrade déjà la conduite : la réguler précède toute mise au point sur les interruptions."),
]
