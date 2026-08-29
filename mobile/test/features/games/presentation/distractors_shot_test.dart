import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/entities/memory_distraction.dart';
import 'package:zennyt/features/games/domain/service/memory_distraction_factory.dart';
import 'package:zennyt/features/games/presentation/view/investigate_screen.dart';

/// Rendu réel des deux tâches parasites, pour relecture visuelle.
void main() {
  testWidgets('capture — distracteurs images', (tester) async {
    tester.view.physicalSize = const Size(1170, 2200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const factory = MemoryDistractionFactory();
    final odd = factory.createOfKind(
        MemoryDistractionKind.oddOneOut, 5, math.Random(3));
    final puzzle = factory.createOfKind(
        MemoryDistractionKind.puzzlePiece, 5, math.Random(9));

    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: const Color(0xFF4E46E8),
          child: Column(
            children: [
              Expanded(
                child: debugObjectDistractionView(
                    challenge: odd, objectCount: 5, secondsLeft: 11),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: debugObjectDistractionView(
                    challenge: puzzle, objectCount: 5, secondsLeft: 11),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/memory-images-distractors.png'),
    );
  });
}
