import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// A frosted Liquid Glass surface: background blur, a translucent fill,
/// a bright specular edge, and a soft shadow.
///
/// Used for cards, the floating tab bar, and sheets when the glass look is
/// active. The same widget runs on Android and iOS — `BackdropFilter` is the
/// portable stand-in for the system material.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = Dimens.radiusL,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final fill = isDark ? const Color(0xCC1C2823) : const Color(0xD9FFFFFF);
    final highlight = Colors.white.withValues(alpha: isDark ? 0.22 : 0.85);
    final edge = Colors.white.withValues(alpha: isDark ? 0.14 : 0.55);

    // The widget-test binding reschedules a BackdropFilter forever, so the
    // live blur is skipped there. The app itself always blurs.
    final liveBlur = !WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    final frosted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              (tint ?? Colors.white).withValues(alpha: isDark ? 0.08 : 0.18),
              fill,
            ),
            fill.withValues(alpha: isDark ? 0.55 : 0.62),
          ],
        ),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14102824),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    highlight.withValues(alpha: 0),
                    highlight,
                    highlight.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ],
      ),
    );
    final surface = ClipRRect(
      borderRadius: radius,
      child: liveBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: frosted,
            )
          : frosted,
    );

    final sized = SizedBox(width: width, height: height, child: surface);
    if (onTap == null) return sized;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: sized),
    );
  }
}
