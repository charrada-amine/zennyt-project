# -*- coding: utf-8 -*-
"""Rejoue exactement ce que fait le client Dart, contre le vrai module.

Verifier le protocole ici coute quelques secondes ; le verifier en construisant
l'application Android en coute vingt minutes. Les trois etapes reproduites sont celles de
`FraudAudioDataSource.connecter()` :

  1. POST /api/join      ouvrir la salle, recuperer l'identifiant de session
  2. POST /api/consent   enregistrer l'accord (sans lui, chaque segment est refuse)
  3. WS /ws/audio/...    trame texte d'annonce, puis trame binaire du segment WAV

Le WAV envoye est fabrique ici avec le meme en-tete que `enveloppeWav()` en Dart.
"""
import asyncio
import json
import math
import struct
import sys
import urllib.request

BASE = "http://localhost:8800"
SAMPLE_RATE = 16000


def enveloppe_wav(pcm: bytes, sample_rate: int = SAMPLE_RATE, canaux: int = 1) -> bytes:
    """Le meme en-tete que la version Dart — 44 octets, PCM 16 bits."""
    bits = 16
    octets_par_seconde = sample_rate * canaux * bits // 8
    alignement = canaux * bits // 8
    return (
        b"RIFF"
        + struct.pack("<I", 36 + len(pcm))
        + b"WAVEfmt "
        + struct.pack("<IHHIIHH", 16, 1, canaux, sample_rate, octets_par_seconde,
                      alignement, bits)
        + b"data"
        + struct.pack("<I", len(pcm))
        + pcm
    )


def parole(ms: int, frequence: float = 220.0, amplitude: float = 0.3) -> bytes:
    """Un signal audible, pour que le pipeline ait quelque chose a transcrire."""
    n = SAMPLE_RATE * ms // 1000
    return b"".join(
        struct.pack("<h", int(math.sin(2 * math.pi * frequence * i / SAMPLE_RATE)
                              * amplitude * 32767))
        for i in range(n)
    )


def poster(chemin: str, corps: dict) -> dict:
    requete = urllib.request.Request(
        BASE + chemin, data=json.dumps(corps).encode(),
        headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(requete, timeout=10) as reponse:
        return json.loads(reponse.read() or b"{}")


async def principal() -> int:
    try:
        import websockets
    except ImportError:
        print("ECHEC : le paquet `websockets` manque dans le venv du module")
        return 1

    salle = "zennyt-verif-mobile"
    resultats: list[tuple[bool, str]] = []

    def verifier(libelle: str, condition: bool, detail: str = "") -> None:
        resultats.append((condition, libelle))
        print(f"  [{'OK ' if condition else 'ECHEC'}] {libelle}")
        if detail:
            print(f"         {detail}")

    print("1. Ouverture de la salle et consentement des deux cotes")
    session_id = None
    for role in ("candidate", "recruiter"):
        entree = poster("/api/join", {"room": salle, "role": role, "display_name": role})
        session_id = entree.get("session_id")
        etat = poster("/api/consent", {
            "session_id": session_id, "role": role,
            "decision": "accepted", "form": "full", "locale": "fr"})
    verifier("le module rend un identifiant de session", session_id is not None, session_id or "")
    verifier("l'enregistrement est autorise apres les deux accords",
             bool(etat.get("recording_enabled")),
             f"recording_enabled={etat.get('recording_enabled')}")

    print("\n2. Envoi d'un segment, au protocole du client Dart")
    uri = f"ws://localhost:8800/ws/audio/{session_id}?role=candidate"
    async with websockets.connect(uri, max_size=None) as ws:
        wav = enveloppe_wav(parole(1200))
        await ws.send(json.dumps({"seq": 0, "started_at": "2026-08-22T10:00:00+00:00",
                                  "speech_ms": 1200, "duration_ms": 1200}))
        await ws.send(wav)

        accuse = None
        for _ in range(5):
            brut = await asyncio.wait_for(ws.recv(), timeout=25)
            message = json.loads(brut)
            if message.get("type") == "ack":
                accuse = message
                break
            if message.get("type") == "rejected":
                verifier("segment accepte", False, message.get("reason", ""))
                break

        verifier("le module accuse reception du segment", accuse is not None,
                 f"{accuse.get('bytes')} octets recus" if accuse else "aucun accuse")
        if accuse:
            verifier("la taille recue correspond au WAV envoye",
                     accuse.get("bytes") == len(wav),
                     f"envoye {len(wav)}, recu {accuse.get('bytes')}")
            verifier("une date de purge est fixee des la reception",
                     bool(accuse.get("purge_after")), str(accuse.get("purge_after")))

    print()
    print("=" * 62)
    echecs = [libelle for ok, libelle in resultats if not ok]
    if echecs:
        print("RESULTAT : echec sur", len(echecs), "point(s)")
        return 1
    print("RESULTAT : le protocole du client Dart est accepte par le module")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(principal()))
