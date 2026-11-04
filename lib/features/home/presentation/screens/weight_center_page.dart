import 'package:flutter/material.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';

/// Weight trend, body fat, circumferences and the plan.
///
/// The chart screen already holds those readings. Embedding it keeps one
/// editor for the log instead of a second copy.
class WeightCenterPage extends StatelessWidget {
  const WeightCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WeightHistoryScreen(embedded: true);
  }
}
