import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/widgets/weight_plan_card.dart';

void main() {
  test('progress is the share of the gap that has been closed', () {
    final progress = weightPlanProgress(
      startKg: 64.2,
      currentKg: 62.4,
      targetKg: 58,
    );
    expect(progress, closeTo(1.8 / 6.2, 0.0001));
  });

  test('a missing start or target does not invent a progress value', () {
    expect(
      weightPlanProgress(startKg: null, currentKg: 62.4, targetKg: 58),
      isNull,
    );
    expect(
      weightPlanProgress(startKg: 64.2, currentKg: 62.4, targetKg: null),
      isNull,
    );
  });

  test('a target equal to the start has no bar', () {
    expect(
      weightPlanProgress(startKg: 60, currentKg: 60, targetKg: 60),
      isNull,
    );
  });
}
