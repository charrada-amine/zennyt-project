import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';

/// Retour haptique des jeux.
///
/// La vibration est déclenchée depuis `SoundService` avec les sons d'erreur, et
/// non par un appel direct à `HapticFeedback` dans les écrans : c'est la seule
/// façon que le réglage « Vibration » du menu pause puisse tout couper. Ces tests
/// verrouillent les deux propriétés qui en découlent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final haptics = <String>[];

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String? ?? 'default');
          }
          return null;
        });
    SoundService.instance
      ..setHapticsEnabled(true)
      ..setSfxEnabled(true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
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
  });
}
