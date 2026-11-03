import 'package:flutter/material.dart';

/// Soft mint wash behind every screen when the glass look is on.
///
/// Scaffolds are transparent in that look, so this gradient — and the two
/// blurred colour blooms — show through frosted cards and the floating tab
/// bar. Classic look leaves [child] untouched.
class GlassBackdrop extends StatelessWidget {
  final bool enabled;
  final bool dark;
  final Widget child;

  const GlassBackdrop({
    super.key,
    required this.enabled,
    required this.dark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final bloom = dark ? const Color(0xFF1F6B56) : const Color(0xFF8FE3C8);
    final wash = dark ? const Color(0xFF14352C) : const Color(0xFFD7F3E8);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? const [
                      Color(0xFF12211C),
                      Color(0xFF0C1411),
                      Color(0xFF163028),
                    ]
                  : const [
                      Color(0xFFE7F8F2),
                      Color(0xFFF7FBFA),
                      Color(0xFFD4F0E6),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -50,
          child: _Bloom(
            color: bloom.withValues(alpha: dark ? 0.45 : 0.55),
            size: 260,
          ),
        ),
        Positioned(
          bottom: 80,
          left: -70,
          child: _Bloom(
            color: wash.withValues(alpha: dark ? 0.35 : 0.9),
            size: 280,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Bloom extends StatelessWidget {
  final Color color;
  final double size;

  const _Bloom({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
