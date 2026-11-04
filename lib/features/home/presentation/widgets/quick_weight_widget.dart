import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #281: Quick weight update chip on the home screen.
///
/// Reads `weightKg` from `HomeLoadedState` (single source of truth) instead
/// of doing its own DB read; that read used to race with onboarding's user
/// write and silently displayed the dummy 80 kg fallback.
class QuickWeightWidget extends StatelessWidget {
  final double weightKg;
  final BodyWeightUnit bodyWeightUnit;

  const QuickWeightWidget({
    super.key,
    required this.weightKg,
    required this.bodyWeightUnit,
  });

  @override
  Widget build(BuildContext context) {
    final displayStr = formatBodyWeight(
      weightKg,
      bodyWeightUnit,
      kgLabel: S.of(context).kgLabel,
      lbLabel: S.of(context).lbsLabel,
      stLabel: S.of(context).stLabel,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;

    final accent = Theme.of(context).colorScheme.primary;
    // Parent on the home row is Expanded, so the node needs its own bounds.
    return Semantics(
      identifier: 'home-weight-chip',
      container: true,
      child: AppCard(
        onTap: () => _showWeightDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.spacing16,
            vertical: Dimens.spacing12,
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: accent, size: 22),
              const SizedBox(width: Dimens.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).weightLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    AutoSizeText(
                      displayStr,
                      maxLines: 1,
                      minFontSize: 13,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: palette.textStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 18, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWeightDialog(BuildContext context) async {
    final newKg = await showDialog<double>(
      context: context,
      builder: (context) =>
          SetWeightDialog(initialKg: weightKg, unit: bodyWeightUnit),
    );

    if (newKg == null || !context.mounted) return;

    final now = DateTime.now();
    await locator<AddWeightLogUsecase>().addEntry(
      WeightLogEntity(
        date: DateTime(now.year, now.month, now.day),
        weightKg: newKg,
      ),
    );

    // addEntry already persisted today's weight onto the user record, so
    // re-load it and route through ProfileBloc.updateUser purely so the
    // profile screen, diary, and home all refresh in one go. Going through
    // AddUserUsecase directly would update Hive but leave the profile
    // screen showing the pre-edit weight until the next manual reload.
    final user = await locator<GetUserUsecase>().getUserData();
    await locator<ProfileBloc>().updateUser(user);
  }
}
