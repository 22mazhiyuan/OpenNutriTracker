import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';

class BodyMeasurementEntity extends Equatable {
  final DateTime date;
  final BodyMetric metric;
  final double value;

  const BodyMeasurementEntity({
    required this.date,
    required this.metric,
    required this.value,
  });

  @override
  List<Object?> get props => [date, metric, value];
}
