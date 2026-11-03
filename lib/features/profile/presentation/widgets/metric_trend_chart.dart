import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A single-series trend line for one body measurement.
///
/// The window is the same calendar-day span the weight chart uses, so a
/// reading on the first day of the range is not dropped across a DST change.
class MetricTrendChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> values;
  final int windowDays;
  final String unitLabel;
  final double chartHeight;

  const MetricTrendChart({
    super.key,
    required this.dates,
    required this.values,
    required this.windowDays,
    required this.unitLabel,
    this.chartHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.primary;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = DateTime(
      today.year,
      today.month,
      today.day - (windowDays - 1),
    );
    int dayIndex(DateTime date) =>
        CalendarDayCalc.daysBetween(windowStart, date);
    DateTime dayAt(int x) => DateUtils.addDaysToDate(windowStart, x);

    final spots = <FlSpot>[];
    for (var i = 0; i < dates.length && i < values.length; i++) {
      final date = dates[i];
      if (date.isBefore(windowStart) || date.isAfter(today)) continue;
      spots.add(FlSpot(dayIndex(date).toDouble(), values[i]));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.length < 2) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SizedBox(
          height: chartHeight,
          child: Center(
            child: Text(
              S.of(context).weightHistoryChartEmptyState,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPadding = ((maxY - minY) * 0.15).clamp(0.4, 8.0);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMd(localeTag);
    final labelInterval = (windowDays / 5).ceilToDouble().clamp(
      1.0,
      double.infinity,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: SizedBox(
        height: chartHeight,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (windowDays - 1).toDouble(),
            minY: minY - yPadding,
            maxY: maxY + yPadding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(value >= 10 ? 0 : 1),
                    semanticsLabel: '${value.toStringAsFixed(1)} $unitLabel',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: labelInterval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateFormat.format(dayAt(value.toInt())),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: lineColor,
                        strokeWidth: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
