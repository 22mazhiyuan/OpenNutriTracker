import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Today's step count from HealthKit or Health Connect.
///
/// Shows a dash and an enable action when the platform cannot be read.
/// Nothing is invented: a missing permission is not drawn as zero steps.
class StepsHomeCard extends StatefulWidget {
  const StepsHomeCard({super.key});

  @override
  State<StepsHomeCard> createState() => _StepsHomeCardState();
}

class _StepsHomeCardState extends State<StepsHomeCard>
    with WidgetsBindingObserver {
  StepReadResult _reading = StepReadResult.unavailable;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  HealthService? get _health {
    if (!locator.isRegistered<HealthService>()) return null;
    return locator<HealthService>();
  }

  Future<void> _load() async {
    final health = _health;
    if (health == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _reading = StepReadResult.unavailable;
      });
      return;
    }
    final reading = await health.readTodaySteps();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _reading = reading;
    });
  }

  Future<void> _connect() async {
    final health = _health;
    if (health == null) return;
    final s = S.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.stepsDisclosureTitle),
        content: Text(s.stepsDisclosureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          Semantics(
            identifier: 'home-steps-connect',
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.stepsDisclosureContinue),
            ),
          ),
        ],
      ),
    );
    if (agreed != true) return;
    final granted = await health.requestStepPermission();
    if (!granted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final showCount = _reading.permitted;
    final label = _loading
        ? '…'
        : showCount
        ? '${_reading.steps}'
        : '—';

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing12,
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk_outlined, color: accent, size: 22),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.stepsHomeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: palette.textMuted),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.durationShort,
                  child: Text(
                    label,
                    key: ValueKey(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!showCount && !_loading)
            Semantics(
              identifier: 'home-steps-enable',
              container: true,
              child: TextButton(
                onPressed: _connect,
                child: Text(s.stepsHomeConnect),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      identifier: 'home-steps-card',
      child: AppPalette.glassActive
          ? GlassSurface(borderRadius: Dimens.radiusL, child: content)
          : Material(
              color: palette.surface,
              borderRadius: Dimens.borderRadiusL,
              child: content,
            ),
    );
  }
}
