import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/auth/presentation/login/view/login_screen.dart';
import 'package:zennyt/features/auth/presentation/signup/view/create_account_screen.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/shared/widgets/app_motion.dart';
import 'package:zennyt/shared/widgets/primary_button.dart';
import 'package:zennyt/shared/widgets/zennyt_loader.dart';

Future<void> _screen(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double width = 390,
  double textScale = 1,
  bool reduced = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: RepaintBoundary(key: const Key('screen'), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (Platform.environment['WRITE_REDESIGN_PREVIEWS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('screen')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../output/redesign/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Login layout and validation in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _screen(tester, const LoginScreen(), dark: dark);
        expect(tester.takeException(), isNull);
        await _preview(tester, 'login-${dark ? 'dark' : 'light'}');
        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          find.text(AppLocalizations.of(tester.element(button)).emailRequired),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Sign-up remains scrollable with large text on a narrow screen', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _screen(
      tester,
      const CreateAccountScreen(),
      width: 320,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    final continueButton = find.byType(PrimaryButton);
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(continueButton.hitTestable(), findsOneWidget);
  });

  testWidgets('Loading and disabled buttons cannot activate callbacks', (
    tester,
  ) async {
    var activations = 0;
    await _screen(
      tester,
      Scaffold(
        body: Column(
          children: [
            PrimaryButton(label: 'Disabled', onPressed: null),
            PrimaryButton(
              label: 'Loading',
              loading: true,
              onPressed: () => activations++,
              haptics: false,
            ),
          ],
        ),
      ),
      reduced: true,
    );
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.tap(find.byType(ElevatedButton).last);
    expect(activations, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Reduced motion suppresses entrance and loader tickers', (
    tester,
  ) async {
    await _screen(
      tester,
      const Scaffold(body: AppReveal(child: ZennytLoader())),
      reduced: true,
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Cancelled press returns to rest without activating child', (
    tester,
  ) async {
    var activations = 0;
    await _screen(
      tester,
      Scaffold(
        body: PrimaryButton(
          label: 'Continue',
          onPressed: () => activations++,
          haptics: false,
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ElevatedButton)),
    );
    await tester.pump(AppMotion.press);
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      lessThan(1),
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(activations, 0);
  });
}
