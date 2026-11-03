import 'package:hive_ce_flutter/hive_flutter.dart';

part 'body_measurement_dbo.g.dart';

@HiveType(typeId: 24)
class BodyMeasurementDBO extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int metricIndex;

  @HiveField(2)
  double value;

  BodyMeasurementDBO({
    required this.date,
    required this.metricIndex,
    required this.value,
  });
}
