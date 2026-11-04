import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// Live blur deadlocks the widget-test renderer, so tests keep the frosted
/// fill and the running app blurs.
bool get glassBlurEnabled =>
    !WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// A frosted Liquid Glass surface: background blur, a translucent fill,
/// a bright specular edge, and a soft shadow.
///
/// Used for the floating tab bar. Content cards stay solid.
/// The same widget runs on Android and iOS — `BackdropFilter` is the
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

    final liveBlur = glassBlurEnabled;
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

/// Blurred bar behind an [AppBar]. Content cards do not use this.
class GlassBarBackground extends StatelessWidget {
  const GlassBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1A201D) : Colors.white).withValues(
          alpha: 0.78,
        ),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
          ),
        ),
      ),
    );
    final bar = glassBlurEnabled
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: fill,
            ),
          )
        : fill;
    return SizedBox.expand(child: bar);
  }
}

/// Frosted frame for a modal sheet. The sheet route itself stays transparent.
class GlassSheet extends StatelessWidget {
  final Widget child;

  const GlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1A201D) : Colors.white).withValues(
          alpha: 0.88,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
          ),
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: glassBlurEnabled
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: fill,
            )
          : fill,
    );
  }
}
