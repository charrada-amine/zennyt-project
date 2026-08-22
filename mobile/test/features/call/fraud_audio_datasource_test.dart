import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/call/data/datasources/fraud_audio_datasource.dart';

/// L'emballage WAV, qui est le seul endroit où le téléphone et le serveur doivent
/// s'accorder sur un format binaire.
///
/// Le test qui compte n'est pas ici mais dans `docs/fraude/verif_wav.py` : il fait décoder
/// le fichier produit ici par le décodeur réel du module. Un en-tête correct selon Dart ne
/// prouve rien tant que PyAV ne l'a pas relu.
void main() {
  Uint8List pcm(int echantillons) {
    final data = Int16List(echantillons);
    for (var i = 0; i < echantillons; i++) {
      data[i] = (i % 1000) - 500;
    }
    return data.buffer.asUint8List();
  }

  test('l’en-tête WAV fait 44 octets et annonce la bonne taille', () {
    final brut = pcm(16000); // 1 seconde
    final wav = FraudAudioDataSource.enveloppeWav(brut);

    expect(wav.length, equals(44 + brut.length));

    final vue = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
    expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));
    expect(String.fromCharCodes(wav.sublist(36, 40)), equals('data'));
    expect(vue.getUint32(4, Endian.little), equals(36 + brut.length));
    expect(vue.getUint32(40, Endian.little), equals(brut.length));
  });

  test('les paramètres annoncés sont ceux qu’attend le pipeline', () {
    final wav = FraudAudioDataSource.enveloppeWav(pcm(800));
    final vue = ByteData.sublistView(wav);

    expect(vue.getUint16(20, Endian.little), equals(1), reason: 'PCM non compressé');
    expect(vue.getUint16(22, Endian.little), equals(1), reason: 'mono');
    expect(vue.getUint32(24, Endian.little), equals(16000), reason: '16 kHz');
    expect(vue.getUint16(34, Endian.little), equals(16), reason: '16 bits');
    // Débit et alignement doivent découler des trois précédents, sinon certains
    // décodeurs lisent de travers sans jamais se plaindre.
    expect(vue.getUint32(28, Endian.little), equals(16000 * 2));
    expect(vue.getUint16(32, Endian.little), equals(2));
  });

  test('le PCM est recopié tel quel après l’en-tête', () {
    final brut = pcm(400);
    final wav = FraudAudioDataSource.enveloppeWav(brut);
    expect(wav.sublist(44), equals(brut));
  });

  /// Produit un fichier que le décodeur du module relira — voir docs/fraude/verif_wav.py.
  test('écrit un échantillon relisible par le module', () async {
    final wav = FraudAudioDataSource.enveloppeWav(pcm(16000));
    final fichier = File('build/echantillon_segment.wav');
    await fichier.parent.create(recursive: true);
    await fichier.writeAsBytes(wav);
    expect(await fichier.length(), equals(44 + 32000));
  });
}
