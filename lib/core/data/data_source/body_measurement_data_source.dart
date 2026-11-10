import 'package:opennutritracker/core/data/dbo/body_measurement_dbo.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class BodyMeasurementDataSource {
  final HiveDBProvider _db;

  BodyMeasurementDataSource(this._db);

  /// One reading per metric per calendar day. A second save for the same
  /// day and metric replaces the first, matching the weight log.
  static String storageKey(DateTime date, BodyMetric metric) =>
      '${date.toParsedDay()}|${metric.index}';

  Future<void> add(BodyMeasurementDBO entry) async {
    final metric = BodyMetric.fromIndex(entry.metricIndex);
    if (metric == null) return;
    await _db.bodyMeasurementBox.put(storageKey(entry.date, metric), entry);
  }

  Future<List<BodyMeasurementDBO>> all() async {
    return _db.bodyMeasurementBox.values.toList();
  }

  Future<void> delete(DateTime date, BodyMetric metric) async {
    await _db.bodyMeasurementBox.delete(storageKey(date, metric));
  }
}
