import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'grain_overlay.dart';

/// Az app háttere. Sötét módban halvány lilás derengés és szemcsés
/// textúra, világos módban sima, tiszta háttér.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: theme.colorScheme.surface),
        ),
        if (isDark) ...[
          Positioned(
            top: 40,
            left: -160,
            right: -160,
            height: 520,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.6,
                    colors: [
                      AppColors.brandGlow.withValues(alpha: 0.14),
                      AppColors.brandGlow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: GrainOverlay()),
          ),
        ],
        Positioned.fill(child: child),
      ],
    );
  }
}
