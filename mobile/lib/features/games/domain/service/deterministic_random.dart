import 'dart:convert';

/// Générateur déterministe partagé par les jeux dont le contenu est dérivé de
/// l'UUID de session (« Je place », BART, IST).
///
/// PARITÉ MOCK ⇄ BACKEND : FNV-1a 32 bits sur les octets UTF-8, puis xorshift32
/// avec modulo non signé — reproduit `ObjectLocationLayoutGenerator.fnv1a32` et
/// `ObjectLocationLayoutGenerator.XorShift32` côté Java. Une seule copie côté
/// Dart : les générateurs de chaque jeu l'importent au lieu de la recopier.
class DeterministicRandom {
  DeterministicRandom(int seed) : _state = seed == 0 ? zeroSeedFallback : seed;

  /// Graine de repli pour une graine nulle (xorshift ne quitte jamais 0).
  static const zeroSeedFallback = 0x6D2B79F5;

  /// Graine d'une session pour un protocole : `fnv1a32("<uuid>|<protocole>")`.
  factory DeterministicRandom.forSession(String sessionId, String protocolVersion) =>
      DeterministicRandom(seedFor(sessionId, protocolVersion));

  static int seedFor(String sessionId, String protocolVersion) =>
      fnv1a32(utf8.encode('${sessionId.toLowerCase()}|$protocolVersion'));

  int _state;

  int nextUint32() {
    var value = _state;
    value ^= (value << 13) & 0xFFFFFFFF;
    value ^= value >>> 17;
    value ^= (value << 5) & 0xFFFFFFFF;
    _state = value & 0xFFFFFFFF;
    return _state;
  }

  int nextInt(int upperBound) {
    if (upperBound <= 0) throw ArgumentError.value(upperBound, 'upperBound');
    return nextUint32() % upperBound;
  }

  /// Fisher-Yates, même ordre de tirages que le Java.
  void shuffle<T>(List<T> values) {
    for (var index = values.length - 1; index > 0; index--) {
      final swapIndex = nextInt(index + 1);
      final value = values[index];
      values[index] = values[swapIndex];
      values[swapIndex] = value;
    }
  }

  /// FNV-1a 32 bits, débordement modulo 2^32 intentionnel.
  static int fnv1a32(List<int> bytes) {
    var hash = 0x811C9DC5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
