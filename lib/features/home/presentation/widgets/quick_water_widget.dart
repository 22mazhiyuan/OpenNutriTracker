import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/home/presentation/widgets/log_water_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Home hydration card: today's progress and one-tap amounts.
///
/// The amounts match the cups people actually drink (a small glass, a mug,
/// a bottle). The custom control still opens the existing slider dialog,
/// including undo.
class QuickWaterWidget extends StatelessWidget {
  final int waterMlToday;
  final int waterGoalMl;

  const QuickWaterWidget({
    super.key,
    required this.waterMlToday,
    required this.waterGoalMl,
  });

  static const quickAmounts = [200, 300, 500];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final goal = waterGoalMl <= 0 ? 1 : waterGoalMl;
    final fraction = (waterMlToday / goal).clamp(0.0, 1.0);

    final body = Padding(
      padding: const EdgeInsets.all(Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: accent, size: 22),
              const SizedBox(width: Dimens.spacing8),
              Expanded(
                child: Text(
                  s.waterHomeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textStrong),
                ),
              ),
              Text(
                s.waterChipLabel(waterMlToday, waterGoalMl),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.surfaceMuted),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: AnimatedContainer(
                      duration: AppMotion.durationMedium,
                      curve: AppMotion.emphasized,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Row(
            children: [
              for (final amount in quickAmounts) ...[
                Expanded(
                  child: Semantics(
                    identifier: 'home-water-add-$amount',
                    container: true,
                    child: OutlinedButton(
                      onPressed: () =>
                          locator<HomeBloc>().addWaterIntake(amount),
                      child: Text(
                        s.waterQuickAdd(amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (amount != quickAmounts.last)
                  const SizedBox(width: Dimens.spacing8),
              ],
              const SizedBox(width: Dimens.spacing8),
              Semantics(
                identifier: 'home-water-edit',
                container: true,
                child: IconButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const LogWaterDialog(),
                  ),
                  icon: const Icon(Icons.tune_outlined),
                  tooltip: s.logWaterDialogTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      identifier: 'home-water-chip',
      child: AppPalette.glassActive
          ? GlassSurface(child: body)
          : Material(color: palette.surface, shape: Dimens.shapeL, child: body),
    );
  }
}
