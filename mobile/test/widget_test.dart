import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/shared/widgets/zennyt_logo.dart';
import 'package:zennyt/core/theme/theme.dart';

class FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png')) {
      final bytes = Uint8List.fromList([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        13,
        73,
        68,
        65,
        84,
        120,
        156,
        99,
        96,
        0,
        0,
        0,
        2,
        0,
        1,
        244,
        1,
        100,
        4,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]);
      return ByteData.sublistView(bytes);
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('ZennytLogo renders the wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: const Scaffold(body: Center(child: ZennytLogo())),
        ),
      ),
    );

    expect(find.text('ZENNYT'), findsOneWidget);
  });
}
