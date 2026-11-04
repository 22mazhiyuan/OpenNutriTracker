import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:opennutritracker/core/data/data_source/body_measurement_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/health_package_service.dart';
import 'package:opennutritracker/core/domain/entity/app_look.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';

void main() {
  test('an unset look opens as glass and classic stays selectable', () {
    expect(AppLook.fromStorage(null), AppLook.glass);
    expect(AppLook.fromStorage(0), AppLook.classic);
    expect(AppLook.fromStorage(1), AppLook.glass);
  });

  test('body measurements keep one slot per metric per day', () {
    final day = DateTime(2026, 11, 3, 18, 4);
    expect(
      BodyMeasurementDataSource.storageKey(day, BodyMetric.waist),
      isNot(BodyMeasurementDataSource.storageKey(day, BodyMetric.hip)),
    );
    expect(
      BodyMeasurementDataSource.storageKey(day, BodyMetric.waist),
      BodyMeasurementDataSource.storageKey(
        DateTime(2026, 11, 3, 1),
        BodyMetric.waist,
      ),
    );
    expect(BodyMetric.bodyFat.accepts(18.5), isTrue);
    expect(BodyMetric.bodyFat.accepts(0), isFalse);
    expect(BodyMetric.bodyFat.accepts(120), isFalse);
    expect(BodyMetric.waist.accepts(72), isTrue);
    expect(BodyMetric.waist.accepts(400), isFalse);
  });

  test('step totals use the larger source instead of adding them', () {
    final start = DateTime(2026, 11, 3, 8);
    HealthDataPoint point(String source, String id, num steps) =>
        HealthDataPoint(
          uuid: id,
          value: NumericHealthValue(numericValue: steps),
          type: HealthDataType.STEPS,
          unit: HealthDataUnit.COUNT,
          dateFrom: start,
          dateTo: start.add(const Duration(hours: 1)),
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'device',
          sourceId: source,
          sourceName: source,
        );

    expect(
      HealthPackageService.sumStepCount([
        point('phone', 'a', 4000),
        point('phone', 'a', 4000),
        point('watch', 'b', 4200),
      ]),
      4200,
    );
  });
}
