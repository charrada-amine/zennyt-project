import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/native_haptics.dart';
import 'package:zennyt/core/audio/sound_service.dart';

/// Retour haptique des jeux.
///
/// La vibration est déclenchée depuis `SoundService` avec les sons d'erreur, et
/// non par un appel direct à `HapticFeedback` dans les écrans : c'est la seule
/// façon que le réglage « Vibration » du menu pause puisse tout couper. Ces tests
/// verrouillent les deux propriétés qui en découlent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Effets partis par le chemin standard `HapticFeedback`.
  final haptics = <String>[];

  /// Appels reçus par le canal natif `zennyt/haptics`.
  final native = <Map<Object?, Object?>>[];

  /// Ce que le moteur natif répond : `true` = il a vibré.
  var nativePlays = false;

  /// `SoundService` instancie ses `AudioPlayer` dès sa construction : sans plugin
  /// audio, l'initialisation lève une `MissingPluginException` asynchrone qui
  /// ferait échouer le test courant. On neutralise les canaux d'audioplayers, puis
  /// on force la création du singleton hors de tout test.
  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    SoundService.instance.setHapticsEnabled(true);
    await Future<void>.delayed(Duration.zero);
  });

  setUp(() {
    haptics.clear();
    native.clear();
    nativePlays = false;
    // Le drapeau « canal indisponible » est mémorisé pour ne pas retenter à
    // chaque vibration : il faut le remettre à zéro entre deux tests.
    NativeHaptics.resetForTest();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String? ?? 'default');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(NativeHaptics.channel, (call) async {
      if (call.method != 'vibrate') return null;
      native.add(call.arguments as Map<Object?, Object?>);
      return nativePlays;
    });
    SoundService.instance
      ..setHapticsEnabled(true)
      ..setSfxEnabled(true);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(NativeHaptics.channel, null);
    SoundService.instance
      ..setHapticsEnabled(true)
      ..setSfxEnabled(true);
  });

  /// `playSfx` déclenche la vibration sans l'attendre : on laisse tourner la
  /// micro-tâche avant de vérifier.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('un son d\'erreur déclenche la vibration', () async {
    await SoundService.instance.playSfx(GameSfx.wrongChoice);
    await settle();
    expect(haptics, isNotEmpty);
  });

  test('couper le SON ne coupe pas la vibration', () async {
    SoundService.instance.setSfxEnabled(false);

    await SoundService.instance.playSfx(GameSfx.wrongChoice);
    await settle();

    expect(
      haptics,
      isNotEmpty,
      reason:
          'son et vibration sont deux canaux distincts, avec deux interrupteurs '
          'distincts — le test de _sfxEnabled doit venir APRÈS la vibration',
    );
  });

  test('couper la VIBRATION la coupe vraiment', () async {
    SoundService.instance.setHapticsEnabled(false);

    await SoundService.instance.playSfx(GameSfx.wrongChoice);
    await SoundService.instance.vibrateError();
    await SoundService.instance.vibrateSuccess();
    await SoundService.instance.vibrateSelection();
    await settle();

    expect(haptics, isEmpty);
  });

  test('un son neutre ne vibre pas', () async {
    await SoundService.instance.playSfx(GameSfx.buttonClick);
    await settle();
    expect(haptics, isEmpty);
    expect(native, isEmpty);
  });

  /// Le client signalait la vibration d'erreur d'Optimal Path comme non
  /// fonctionnelle alors que le câblage était correct. La cause n'était pas dans
  /// le code mais dans le chemin emprunté : `HapticFeedback` demande un retour
  /// TACTILE, qu'Android ignore silencieusement quand « Vibration au toucher »
  /// est désactivé — le défaut sur beaucoup de Xiaomi/Redmi. Le moteur natif, lui,
  /// ne dépend que de la permission `VIBRATE`.
  group('moteur de vibration natif', () {
    test('la vibration passe par le moteur natif, pas par le retour tactile', () async {
      nativePlays = true;

      await SoundService.instance.vibrateError();
      await settle();

      expect(native, hasLength(1));
      expect(native.single['milliseconds'], 60);
      expect(native.single['amplitude'], 255);
      expect(
        haptics,
        isEmpty,
        reason:
            'le chemin standard ne doit PAS être doublé : deux vibrations '
            'coup sur coup se sentiraient',
      );
    });

    test('chaque moment a son intensité', () async {
      nativePlays = true;

      await SoundService.instance.vibrateError();
      await SoundService.instance.vibrateSuccess();
      await SoundService.instance.vibrateSelection();
      await settle();

      expect(
        native.map((call) => call['milliseconds']),
        [60, 35, 15],
        reason: 'une erreur doit se sentir franchement, une sélection à peine',
      );
    });

    test('si le moteur natif ne joue rien, le chemin standard prend le relais', () async {
      nativePlays = false;

      await SoundService.instance.vibrateError();
      await settle();

      expect(native, hasLength(1), reason: 'le natif est tenté en premier');
      expect(
        haptics,
        isNotEmpty,
        reason:
            'repli indispensable : iOS n\'implémente pas ce canal et n\'a pas '
            'besoin de le faire',
      );
    });

    test('couper la VIBRATION coupe aussi le chemin natif', () async {
      nativePlays = true;
      SoundService.instance.setHapticsEnabled(false);

      await SoundService.instance.vibrateError();
      await SoundService.instance.playSfx(GameSfx.wrongChoice);
      await settle();

      expect(
        native,
        isEmpty,
        reason:
            'le réglage du menu pause doit tout couper — un nouveau chemin qui '
            'lui échapperait rouvrirait le trou qu\'il ferme',
      );
      expect(haptics, isEmpty);
    });

    test('un son d\'erreur emprunte lui aussi le moteur natif', () async {
      nativePlays = true;

      await SoundService.instance.playSfx(GameSfx.wrongChoice);
      await settle();

      expect(native, hasLength(1));
      expect(native.single['milliseconds'], 60);
    });
  });
}
