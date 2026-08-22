import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/call/domain/services/speech_segmenter.dart';

/// Le découpage par silences, éprouvé sans micro.
///
/// C'est tout l'intérêt d'avoir sorti cette classe de l'appel : on lui pousse des octets
/// fabriqués, elle rend des segments. Aucun Agora, aucun réseau, aucune permission.
void main() {
  const sampleRate = 16000;

  /// Fabrique [ms] millisecondes de PCM 16 bits mono.
  ///
  /// [amplitude] à 0 donne un silence parfait ; 0.3 donne un signal franchement au-dessus
  /// du seuil. On génère du bruit plutôt qu'une sinusoïde : une sinusoïde pure passe par
  /// zéro régulièrement et donnerait une énergie trompeuse sur une fenêtre courte.
  Uint8List signal(int ms, double amplitude, {int graine = 7}) {
    final echantillons = sampleRate * ms ~/ 1000;
    final data = Int16List(echantillons);
    final alea = math.Random(graine);
    for (var i = 0; i < echantillons; i++) {
      data[i] = ((alea.nextDouble() * 2 - 1) * amplitude * 32767).round();
    }
    return data.buffer.asUint8List();
  }

  Uint8List silence(int ms) => signal(ms, 0.0);
  Uint8List parole(int ms) => signal(ms, 0.3);

  test('une phrase suivie d’un silence produit exactement un segment', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(
      onSegment: (_, info) => segments.add(info),
    );

    segmenteur.push(parole(1000));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));

    expect(segments, hasLength(1));
    expect(segments.first.speechMs, greaterThanOrEqualTo(SpeechSegmenter.minSpeechMs));
  });

  test('deux phrases séparées par un silence produisent deux segments', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));

    segmenteur.push(parole(800));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));
    segmenteur.push(parole(800));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));

    expect(segments, hasLength(2));
  });

  /// Le cas qui justifie le découpage par silences plutôt qu'à intervalle fixe : une pause
  /// courte, au milieu d'une phrase, ne doit pas la scinder en deux.
  test('une pause courte ne scinde pas la phrase', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));

    segmenteur.push(parole(600));
    segmenteur.push(silence(300)); // en dessous de silenceMs
    segmenteur.push(parole(600));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));

    expect(segments, hasLength(1));
  });

  test('un bruit trop bref est écarté : rien n’est envoyé', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));

    // 200 ms : au-dessus de l'amorce (120 ms), en dessous du minimum retenu (400 ms).
    segmenteur.push(parole(200));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));

    expect(segments, isEmpty);
  });

  test('un silence prolongé n’envoie rien du tout', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));

    segmenteur.push(silence(SpeechSegmenter.idleResetMs + 1000));

    expect(segments, isEmpty);
  });

  /// Sans ce filet, un monologue continu ne serait jamais analysé.
  test('un monologue continu est découpé au bout du délai maximal', () {
    final segments = <SegmentInfo>[];
    final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));

    segmenteur.push(parole(SpeechSegmenter.maxSegmentMs + 2000));

    expect(segments, isNotEmpty);
    expect(segments.first.durationMs,
        greaterThanOrEqualTo(SpeechSegmenter.maxSegmentMs));
  });

  /// Agora ne livre pas des tampons alignés sur la fenêtre d'analyse. Le découpage doit
  /// donner le même résultat quelle que soit la taille des tampons reçus.
  test('le résultat ne dépend pas de la taille des tampons reçus', () {
    List<int> compter(int tailleMs) {
      final segments = <SegmentInfo>[];
      final segmenteur = SpeechSegmenter(onSegment: (_, info) => segments.add(info));
      final flux = <Uint8List>[
        parole(1000),
        silence(SpeechSegmenter.silenceMs + 200),
      ];
      // Reconcatène puis redécoupe en tampons de taille arbitraire.
      final tout = BytesBuilder(copy: false);
      for (final morceau in flux) {
        tout.add(morceau);
      }
      final octets = tout.takeBytes();
      final pas = math.max(2, (sampleRate * tailleMs ~/ 1000) * 2);
      for (var i = 0; i < octets.length; i += pas) {
        final fin = math.min(i + pas, octets.length);
        segmenteur.push(Uint8List.sublistView(octets, i, fin));
      }
      return [segments.length, segments.isEmpty ? 0 : segments.first.speechMs];
    }

    // 10 ms (plus petit que la fenêtre), 50 ms (pile), 64 ms (non aligné).
    expect(compter(10), equals(compter(50)));
    expect(compter(64), equals(compter(50)));
  });

  test('le PCM rendu correspond à la durée annoncée', () {
    Uint8List? recu;
    SegmentInfo? info;
    final segmenteur = SpeechSegmenter(onSegment: (pcm, i) {
      recu = pcm;
      info = i;
    });

    segmenteur.push(parole(1000));
    segmenteur.push(silence(SpeechSegmenter.silenceMs + 200));

    expect(recu, isNotNull);
    // 16 000 échantillons/s × 2 octets : la durée se relit dans la taille.
    final dureeMs = recu!.length / 2 / sampleRate * 1000;
    expect(dureeMs, closeTo(info!.durationMs.toDouble(), SpeechSegmenter.frameMs.toDouble()));
  });
}
