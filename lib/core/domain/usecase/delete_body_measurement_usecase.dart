import 'package:opennutritracker/core/data/repository/body_measurement_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';

class DeleteBodyMeasurementUsecase {
  final BodyMeasurementRepository _repository;

  DeleteBodyMeasurementUsecase(this._repository);

  Future<void> delete(DateTime date, BodyMetric metric) =>
      _repository.delete(date, metric);
}
