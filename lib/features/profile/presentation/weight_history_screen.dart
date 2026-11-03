import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_measurement_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_metric.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_body_measurement_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_body_measurement_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_body_measurements_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/reload_diary_and_trends.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/metric_trend_chart.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Screen for browsing and adding weight log entries.
///
/// Renders a 30-day trend chart above the date-sorted list of readings.
/// The list remains the source of truth — the chart is a complementary
/// visualisation. When the user has logged fewer than two days the chart
/// area gives way to a gentle nudge to log more data, because a single
/// point doesn't yet describe a trend.
///
/// Dependencies are resolved from the locator by default; the optional
/// constructor parameters exist so widget tests can inject fakes without
/// standing up the whole DI graph.
class WeightHistoryScreen extends StatefulWidget {
  final GetWeightLogUsecase? getUsecase;
  final AddWeightLogUsecase? addUsecase;
  final DeleteWeightLogUsecase? deleteUsecase;
  final ConfigRepository? configRepository;
  final GetUserUsecase? getUserUsecase;
  final GetBodyMeasurementsUsecase? getMeasurementsUsecase;
  final AddBodyMeasurementUsecase? addMeasurementUsecase;
  final DeleteBodyMeasurementUsecase? deleteMeasurementUsecase;

  const WeightHistoryScreen({
    super.key,
    this.getUsecase,
    this.addUsecase,
    this.deleteUsecase,
    this.configRepository,
    this.getUserUsecase,
    this.getMeasurementsUsecase,
    this.addMeasurementUsecase,
    this.deleteMeasurementUsecase,
  });

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  late final GetWeightLogUsecase _getUsecase =
      widget.getUsecase ?? locator<GetWeightLogUsecase>();
  late final AddWeightLogUsecase _addUsecase =
      widget.addUsecase ?? locator<AddWeightLogUsecase>();
  late final DeleteWeightLogUsecase _deleteUsecase =
      widget.deleteUsecase ?? locator<DeleteWeightLogUsecase>();
  late final ConfigRepository _configRepository =
      widget.configRepository ?? locator<ConfigRepository>();
  // Optional in tests so the harness doesn't need to register the
  // user usecase in the locator just to render the chart.
  late final GetUserUsecase? _getUserUsecase =
      widget.getUserUsecase ??
      (locator.isRegistered<GetUserUsecase>()
          ? locator<GetUserUsecase>()
          : null);

  bool _loading = true;
  BodyWeightUnit _bodyWeightUnit = BodyWeightUnit.kg;
  List<WeightLogEntity> _entries = const [];
  // Loaded once at mount time so the chart can draw a dashed reference
  // line for the user's #119 target weight. Null when unset.
  double? _targetWeightKg;
  // The profile's current weight, which Add entry starts from (#1367).
  double? _profileWeightKg;
  _ChartRange _selectedRange = _ChartRange.days30;
  BodyMetric? _bodyMetric;
  List<BodyMeasurementEntity> _measurements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _configRepository.getConfig();
    final unit = config.bodyWeightUnit;
    final entries = await _getUsecase.getAllEntries();
    // Newest first so the most recent reading sits at the top.
    entries.sort((a, b) => b.date.compareTo(a.date));
    final user = await _getUserUsecase?.getUserData();
    if (!mounted) return;
    setState(() {
      _bodyWeightUnit = unit;
      _entries = entries;
      _targetWeightKg = user?.targetWeightKg;
      _profileWeightKg = user?.weightKG;
      _loading = false;
    });
  }

  int _calculateWindowDays() {
    switch (_selectedRange) {
      case _ChartRange.days30:
        return 30;
      case _ChartRange.days60:
        return 60;
      case _ChartRange.days180:
        return 180;
      case _ChartRange.days365:
        return 365;
      case _ChartRange.all:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final sourceDates = _bodyMetric == null
            ? _entries.map((e) => e.date)
            : _measurements.map((e) => e.date);
        final nonFutureEntries = sourceDates
            .where((date) => !date.isAfter(today))
            .toList();
        if (nonFutureEntries.isEmpty) {
          return 30;
        }
        final oldestDate = nonFutureEntries.reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
        // Calendar days, not elapsed 24-hour spans: across a spring-forward
        // `difference().inDays` comes out one short and the chart window
        // would start the day after the oldest entry (#1207).
        final diffDays = CalendarDayCalc.daysBetween(oldestDate, today) + 1;
        return diffDays < 30 ? 30 : diffDays;
    }
  }

  Widget _buildRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Semantics(
            identifier: 'weight-history-range-selector',
            child: SegmentedButton<_ChartRange>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment(
                  value: _ChartRange.days30,
                  label: Text(S.of(context).chartRangeDaysLabel(30)),
                ),
                ButtonSegment(
                  value: _ChartRange.days60,
                  label: Text(S.of(context).chartRangeDaysLabel(60)),
                ),
                ButtonSegment(
                  value: _ChartRange.days180,
                  label: Text(S.of(context).chartRangeDaysLabel(180)),
                ),
                ButtonSegment(
                  value: _ChartRange.days365,
                  label: Text(S.of(context).chartRangeDaysLabel(365)),
                ),
                ButtonSegment(
                  value: _ChartRange.all,
                  label: Text(S.of(context).allItemsLabel),
                ),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedRange = set.first;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.glassActive ? Colors.transparent : null,
        flexibleSpace: AppPalette.glassActive
            ? const GlassBarBackground()
            : null,
        title: Text(S.of(context).profileWeightHistoryTitle),
      ),
      floatingActionButton: Semantics(
        identifier: 'weight-history-add',
        child: FloatingActionButton.extended(
          onPressed: _bodyMetric == null ? _onAddEntry : _onAddMeasurement,
          icon: const Icon(Icons.add),
          label: Text(S.of(context).weightHistoryAddEntry),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMetricSelector(),
                Expanded(
                  child: _bodyMetric == null
                      ? _weightBody()
                      : _measurementBody(),
                ),
              ],
            ),
    );
  }

  Widget _weightBody() {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            S.of(context).weightHistoryNoEntries,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _entries.length + 1,
      separatorBuilder: (context, index) {
        // No divider between the chart card and the first list tile.
        if (index == 0) return const SizedBox.shrink();
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRangeSelector(),
              WeightTrendChart(
                entries: _entries,
                bodyWeightUnit: _bodyWeightUnit,
                targetWeightKg: _targetWeightKg,
                windowDays: _calculateWindowDays(),
              ),
            ],
          );
        }
        return _buildEntryTile(_entries[index - 1]);
      },
    );
  }

  Widget _buildMetricSelector() {
    final s = S.of(context);
    final metrics = <BodyMetric?>[null, ...BodyMetric.values];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: metrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          final selected = metric == _bodyMetric;
          final id = metric == null ? 'weight' : metric.name;
          return Semantics(
            identifier: 'body-metric-$id',
            child: ChoiceChip(
              label: Text(_metricLabel(s, metric)),
              selected: selected,
              onSelected: (_) => _selectMetric(metric),
            ),
          );
        },
      ),
    );
  }

  String _metricLabel(S s, BodyMetric? metric) {
    return switch (metric) {
      null => s.bodyMetricWeight,
      BodyMetric.bodyFat => s.bodyMetricBodyFat,
      BodyMetric.waist => s.bodyMetricWaist,
      BodyMetric.hip => s.bodyMetricHip,
      BodyMetric.chest => s.bodyMetricChest,
      BodyMetric.thigh => s.bodyMetricThigh,
      BodyMetric.arm => s.bodyMetricArm,
      BodyMetric.calf => s.bodyMetricCalf,
    };
  }

  String _metricUnit(S s, BodyMetric metric) =>
      metric.isPercent ? s.bodyMetricPercentUnit : s.bodyMetricCmUnit;

  Future<void> _selectMetric(BodyMetric? metric) async {
    setState(() => _bodyMetric = metric);
    if (metric != null) await _loadMeasurements();
  }

  GetBodyMeasurementsUsecase? get _getMeasurements {
    if (widget.getMeasurementsUsecase != null) {
      return widget.getMeasurementsUsecase;
    }
    if (locator.isRegistered<GetBodyMeasurementsUsecase>()) {
      return locator<GetBodyMeasurementsUsecase>();
    }
    return null;
  }

  Future<void> _loadMeasurements() async {
    final metric = _bodyMetric;
    final usecase = _getMeasurements;
    if (metric == null || usecase == null) {
      if (mounted) setState(() => _measurements = const []);
      return;
    }
    final all = await usecase.getAll();
    if (!mounted || _bodyMetric != metric) return;
    final rows = all.where((e) => e.metric == metric).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    setState(() => _measurements = rows);
  }

  Widget _measurementBody() {
    final metric = _bodyMetric;
    if (metric == null) return const SizedBox.shrink();
    final s = S.of(context);
    final unit = _metricUnit(s, metric);
    if (_measurements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.bodyMetricEmpty(_metricLabel(s, metric)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _measurements.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildRangeSelector(),
              MetricTrendChart(
                dates: _measurements.map((e) => e.date).toList(),
                values: _measurements.map((e) => e.value).toList(),
                windowDays: _calculateWindowDays(),
                unitLabel: unit,
              ),
            ],
          );
        }
        final entry = _measurements[index - 1];
        final dateLabel = DateFormat.yMMMd(
          Localizations.localeOf(context).toLanguageTag(),
        ).format(entry.date);
        final number = entry.value.toStringAsFixed(
          entry.value == entry.value.roundToDouble() ? 0 : 1,
        );
        return ListTile(
          title: Text('$number $unit'),
          subtitle: Text(dateLabel),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _onDeleteMeasurement(entry),
          ),
        );
      },
    );
  }

  Future<void> _onAddMeasurement() async {
    final metric = _bodyMetric;
    if (metric == null) return;
    final result = await showDialog<_NewMeasurement>(
      context: context,
      builder: (context) => _AddMeasurementDialog(metric: metric),
    );
    if (result == null) return;
    final usecase =
        widget.addMeasurementUsecase ??
        (locator.isRegistered<AddBodyMeasurementUsecase>()
            ? locator<AddBodyMeasurementUsecase>()
            : null);
    if (usecase == null) return;
    await usecase.add(
      BodyMeasurementEntity(
        date: DateTime(result.date.year, result.date.month, result.date.day),
        metric: metric,
        value: result.value,
      ),
    );
    await _loadMeasurements();
  }

  Future<void> _onDeleteMeasurement(BodyMeasurementEntity entry) async {
    final usecase =
        widget.deleteMeasurementUsecase ??
        (locator.isRegistered<DeleteBodyMeasurementUsecase>()
            ? locator<DeleteBodyMeasurementUsecase>()
            : null);
    if (usecase == null) return;
    await usecase.delete(entry.date, entry.metric);
    await _loadMeasurements();
  }

  Widget _buildEntryTile(WeightLogEntity entry) {
    final displayStr = formatBodyWeight(
      entry.weightKg,
      _bodyWeightUnit,
      kgLabel: S.of(context).kgLabel,
      lbLabel: S.of(context).lbsLabel,
      stLabel: S.of(context).stLabel,
    );
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(entry.date);

    return ListTile(
      title: Text(displayStr),
      subtitle: Text(
        entry.note?.isNotEmpty == true
            ? '$dateLabel  •  ${entry.note}'
            : dateLabel,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _onDelete(entry),
      ),
    );
  }

  Future<void> _onAddEntry() async {
    // The profile weight is the current one: a reading for today updates
    // it, and so does editing it on the profile. A fixed 70 kg here
    // contradicted the profile on every log that had no entries (#1367).
    final initialWeightKg =
        _profileWeightKg ??
        (_entries.isNotEmpty ? _entries.first.weightKg : 70.0);
    final result = await showDialog<_NewWeightEntry>(
      context: context,
      builder: (context) => _AddWeightEntryDialog(
        initialDate: DateTime.now(),
        initialWeightKg: initialWeightKg,
        bodyWeightUnit: _bodyWeightUnit,
      ),
    );
    if (result == null) return;

    await _addUsecase.addEntry(
      WeightLogEntity(
        date: DateTime(result.date.year, result.date.month, result.date.day),
        weightKg: result.weightKg,
        note: result.note,
      ),
    );
    await _load();
    reloadDiaryAndTrends();
  }

  Future<void> _onDelete(WeightLogEntity entry) async {
    await _deleteUsecase.deleteEntry(entry);
    await _load();
    reloadDiaryAndTrends();
  }
}

class _NewWeightEntry {
  final DateTime date;
  final double weightKg;
  final String? note;

  _NewWeightEntry({required this.date, required this.weightKg, this.note});
}

class _AddWeightEntryDialog extends StatefulWidget {
  final DateTime initialDate;
  final double initialWeightKg;
  final BodyWeightUnit bodyWeightUnit;

  const _AddWeightEntryDialog({
    required this.initialDate,
    required this.initialWeightKg,
    required this.bodyWeightUnit,
  });

  @override
  State<_AddWeightEntryDialog> createState() => _AddWeightEntryDialogState();
}

class _AddWeightEntryDialogState extends State<_AddWeightEntryDialog> {
  late DateTime _date;
  late TextEditingController _noteController;

  // The kg value from BodyWeightInput; null means invalid / empty.
  double? _weightKg;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _weightKg = widget.initialWeightKg;
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    final kg = _weightKg;
    if (kg == null || kg <= 0) {
      Navigator.of(context).pop();
      return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      _NewWeightEntry(
        date: _date,
        weightKg: kg,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(_date);

    return AlertDialog(
      title: Text(S.of(context).weightHistoryAddEntry),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(S.of(context).weightHistoryDateLabel),
              subtitle: Text(dateLabel),
              onTap: _pickDate,
            ),
            BodyWeightInput(
              initialKg: widget.initialWeightKg,
              unit: widget.bodyWeightUnit,
              identifierPrefix: 'weight-history',
              autofocus: true,
              onChangedKg: (kg) => setState(() => _weightKg = kg),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: S.of(context).weightHistoryNoteLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}

enum _ChartRange { days30, days60, days180, days365, all }

class _NewMeasurement {
  final DateTime date;
  final double value;

  _NewMeasurement({required this.date, required this.value});
}

class _AddMeasurementDialog extends StatefulWidget {
  final BodyMetric metric;

  const _AddMeasurementDialog({required this.metric});

  @override
  State<_AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<_AddMeasurementDialog> {
  late DateTime _date;
  late final TextEditingController _valueController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final parsed = double.tryParse(
      _valueController.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !widget.metric.accepts(parsed)) {
      setState(() => _error = S.of(context).bodyMetricInvalid);
      return;
    }
    Navigator.of(context).pop(_NewMeasurement(date: _date, value: parsed));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = switch (widget.metric) {
      BodyMetric.bodyFat => s.bodyMetricBodyFat,
      BodyMetric.waist => s.bodyMetricWaist,
      BodyMetric.hip => s.bodyMetricHip,
      BodyMetric.chest => s.bodyMetricChest,
      BodyMetric.thigh => s.bodyMetricThigh,
      BodyMetric.arm => s.bodyMetricArm,
      BodyMetric.calf => s.bodyMetricCalf,
    };
    final unit = widget.metric.isPercent
        ? s.bodyMetricPercentUnit
        : s.bodyMetricCmUnit;
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(_date);
    return AlertDialog(
      title: Text(s.bodyMetricAddTitle(label)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(s.weightHistoryDateLabel),
            subtitle: Text(dateLabel),
            onTap: _pickDate,
          ),
          Semantics(
            identifier: 'body-metric-value',
            child: TextField(
              controller: _valueController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: s.bodyMetricValueLabel,
                suffixText: unit,
                errorText: _error,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        TextButton(onPressed: _submit, child: Text(s.dialogOKLabel)),
      ],
    );
  }
}
