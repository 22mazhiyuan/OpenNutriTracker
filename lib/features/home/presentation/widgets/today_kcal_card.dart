import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Compact "still allowed" figure for today, above the meal rows.
class TodayKcalCard extends StatelessWidget {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;

  const TodayKcalCard({
    super.key,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
  });

  @override
  Widget build(BuildContext context) {
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    final s = S.of(context);
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final over = totalKcalLeft < 0;
    final shownLeft = usesKilojoules
        ? UnitCalc.kcalToKj(totalKcalLeft.abs())
        : totalKcalLeft.abs();
    final shownIn = usesKilojoules
        ? UnitCalc.kcalToKj(totalKcalSupplied)
        : totalKcalSupplied;
    final shownBurned = usesKilojoules
        ? UnitCalc.kcalToKj(totalKcalBurned)
        : totalKcalBurned;
    final leftLabel = over
        ? (usesKilojoules
              ? '${s.kjLabel} ${s.energyTooMuchLabel}'
              : s.kcalTooMuchLabel)
        : (usesKilojoules
              ? '${s.kjLabel} ${s.energyLeftLabel}'
              : s.kcalLeftLabel);
    final accent = over
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing16,
        Dimens.spacing16,
        Dimens.spacing12,
      ),
      child: Column(
        children: [
          Text(
            '${shownLeft.round()}',
            style: textTheme.displaySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            leftLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: Dimens.spacing12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.suppliedLabel}  ${shownIn.round()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: Text(
                  '${s.burnedLabel}  ${shownBurned.round()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
