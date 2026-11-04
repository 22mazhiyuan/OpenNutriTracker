import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Empty tab for a section that has no backend yet.
///
/// The copy says the page is not available. It does not fill the screen
/// with sample posts, products, or counts.
class ComingSoonPage extends StatelessWidget {
  final String semanticsId;

  const ComingSoonPage({super.key, required this.semanticsId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing24),
        child: Semantics(
          identifier: semanticsId,
          container: true,
          child: AppCard(
            padding: const EdgeInsets.all(Dimens.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: Dimens.spacing12),
                Text(
                  s.comingSoonLabel,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                Text(
                  s.comingSoonBody,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
