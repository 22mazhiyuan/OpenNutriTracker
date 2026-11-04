import 'package:opennutritracker/core/data/data_source/body_measurement_data_source.dart';
import 'package:opennutritracker/core/data/dbo/body_measurement_dbo.dart';
import 'package:opennutritracker/core/domain/entity/body_measurement_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';

class BodyMeasurementRepository {
  final BodyMeasurementDataSource _dataSource;

  BodyMeasurementRepository(this._dataSource);

  Future<List<BodyMeasurementEntity>> getAll() async {
    final rows = await _dataSource.all();
    final entities = <BodyMeasurementEntity>[];
    for (final row in rows) {
      final metric = BodyMetric.fromIndex(row.metricIndex);
      if (metric == null || !metric.accepts(row.value)) continue;
      entities.add(
        BodyMeasurementEntity(date: row.date, metric: metric, value: row.value),
      );
    }
    return entities;
  }

  Future<void> add(BodyMeasurementEntity entry) async {
    if (!entry.metric.accepts(entry.value)) return;
    await _dataSource.add(
      BodyMeasurementDBO(
        date: entry.date,
        metricIndex: entry.metric.index,
        value: entry.value,
      ),
    );
  }

  Future<void> delete(DateTime date, BodyMetric metric) {
    return _dataSource.delete(date, metric);
  }
}
