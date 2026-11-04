import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Share of the gap from [startKg] to [targetKg] that [currentKg] has closed.
///
/// Returns null when there is no target, or the start and the target are the
/// same weight. Nothing is filled in for a missing log.
double? weightPlanProgress({
  required double? startKg,
  required double currentKg,
  required double? targetKg,
}) {
  if (startKg == null || targetKg == null) return null;
  final span = startKg - targetKg;
  if (span.abs() < 0.05) return null;
  return ((startKg - currentKg) / span).clamp(0.0, 1.0);
}

/// Home and weight-center summary: current weight, target, amount lost.
///
/// [startKg] is the earliest logged weight. Without it the lost figure and
/// the bar stay empty rather than showing a made-up zero.
class WeightPlanCard extends StatelessWidget {
  final double currentKg;
  final double? targetKg;
  final double? startKg;
  final BodyWeightUnit unit;
  final VoidCallback? onTap;

  const WeightPlanCard({
    super.key,
    required this.currentKg,
    required this.targetKg,
    required this.startKg,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final lost = startKg == null ? null : startKg! - currentKg;
    final progress = weightPlanProgress(
      startKg: startKg,
      currentKg: currentKg,
      targetKg: targetKg,
    );

    String weightText(double kg) => formatBodyWeight(
      kg,
      unit,
      kgLabel: s.kgLabel,
      lbLabel: s.lbsLabel,
      stLabel: s.stLabel,
    );

    return Semantics(
      identifier: 'home-weight-plan',
      container: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.planTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Dimens.spacing12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: s.planCurrentLabel,
                    value: weightText(currentKg),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: s.goalLabel,
                    value: targetKg == null
                        ? s.profileTargetWeightNotSetLabel
                        : weightText(targetKg!),
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: s.planLostLabel,
                    value: lost == null ? '—' : weightText(lost),
                    palette: palette,
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: Dimens.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: palette.surfaceMuted,
                  color: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final AppPalette palette;

  const _Stat({
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
