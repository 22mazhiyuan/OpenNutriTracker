import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// One y-axis label, skipping a tick that would print the same text as the
/// tick below it.
///
/// fl_chart draws the raw minimum and maximum as well as the interval. On a
/// tight range (a few kilograms) those edges round onto the neighbouring
/// integer, and the two texts sit a few pixels apart.
Widget distinctAxisTitle(
  double value,
  TitleMeta meta, {
  required int fractionDigits,
  required TextStyle? style,
  String? semanticsLabel,
}) {
  String format(double v) => v.toStringAsFixed(fractionDigits);
  final label = format(value);
  final step = meta.appliedInterval;
  if (step > 0) {
    final previous = value - step;
    if (previous >= meta.min - step * 1e-4 && format(previous) == label) {
      return const SizedBox.shrink();
    }
    final onEdge =
        (value - meta.min).abs() <= step * 1e-4 ||
        (value - meta.max).abs() <= step * 1e-4;
    if (onEdge) {
      final nearest = (value / step).roundToDouble() * step;
      final apart = (nearest - value).abs();
      if (apart > step * 1e-4 &&
          apart < step * 0.75 &&
          nearest >= meta.min &&
          nearest <= meta.max &&
          format(nearest) == label) {
        return const SizedBox.shrink();
      }
    }
  }
  return Text(label, style: style, semanticsLabel: semanticsLabel);
}
