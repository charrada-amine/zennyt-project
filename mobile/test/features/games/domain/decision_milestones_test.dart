import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/presentation/decision_milestones.dart';

/// Table des jalons de « Je Décide ».
void main() {
  test('chaque dimension a son jalon, sigles et noms distincts', () {
    for (final dimension in DecisionDimension.values) {
      final milestone = milestoneOf(dimension);
      expect(milestone.code, isNotEmpty, reason: dimension.wire);
      expect(milestone.name, isNotEmpty, reason: dimension.wire);
    }

    // Un sigle partagé rendrait deux dimensions indistinguables sur la rangée
    // de pastilles ; un nom partagé rendrait deux jalons identiques à l'écran.
    final codes = {
      for (final d in DecisionDimension.values) milestoneOf(d).code,
    };
    final names = {
      for (final d in DecisionDimension.values) milestoneOf(d).name,
    };
    expect(codes.length, DecisionDimension.values.length);
    expect(names.length, DecisionDimension.values.length);
  });

  /// Les deux seuls noms que l'application affichait déjà. Les trois autres
  /// sont à valider (voir l'avertissement dans `decision_milestones.dart`) ;
  /// ces deux-là ne doivent pas dériver au passage.
  test('les deux jalons déjà connus gardent leur nom', () {
    expect(milestoneOf(DecisionDimension.er).name, 'Risk Navigator');
    expect(milestoneOf(DecisionDimension.cs).name, 'Steady Explorer');
  });
}
