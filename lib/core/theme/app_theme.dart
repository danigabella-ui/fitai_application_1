import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Az app teljes kinézete egy helyen: színek, betűk, gombok, navigáció.
/// Ha a kinézeten változtatunk, elég ezt és az app_colors.dart fájlt módosítani.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _colorScheme(brightness, isDark);

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            letterSpacing: 0.3,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.barlow(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness, bool isDark) {
    final generated = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final primaryContainer = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final onPrimaryContainer = isDark
        ? AppColors.darkOnPrimaryContainer
        : AppColors.lightOnPrimaryContainer;

    return generated.copyWith(
      primary: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onPrimary: isDark ? AppColors.darkOnPrimary : Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: onPrimaryContainer,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      onSurfaceVariant: isDark
          ? AppColors.darkOnSurfaceVariant
          : AppColors.lightOnSurfaceVariant,
      surfaceContainerLowest: isDark
          ? AppColors.darkContainerLowest
          : AppColors.lightContainerLowest,
      surfaceContainerLow:
          isDark ? AppColors.darkContainerLow : AppColors.lightContainerLow,
      surfaceContainer:
          isDark ? AppColors.darkContainer : AppColors.lightContainer,
      surfaceContainerHigh:
          isDark ? AppColors.darkContainerHigh : AppColors.lightContainerHigh,
      surfaceContainerHighest: isDark
          ? AppColors.darkContainerHighest
          : AppColors.lightContainerHighest,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      outlineVariant:
          isDark ? AppColors.darkOutlineVariant : AppColors.lightOutlineVariant,
      surfaceTint: Colors.transparent,
    );
  }

  /// Szövegekhez Barlow, címekhez a keskenyített, sportos Barlow Condensed.
  ///
  /// Stílusonként állítjuk be (nem a GoogleFonts.barlowTextTheme-mel),
  /// mert a google_fonts újabb verziói más TextTheme-típust használnak,
  /// mint az app többi része.
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? regular(TextStyle? style) =>
        style == null ? null : GoogleFonts.barlow(textStyle: style);

    TextStyle? condensed(TextStyle? style, FontWeight weight) => style == null
        ? null
        : GoogleFonts.barlowCondensed(textStyle: style, fontWeight: weight);

    return base.copyWith(
      displayLarge: condensed(base.displayLarge, FontWeight.w700),
      displayMedium: condensed(base.displayMedium, FontWeight.w700),
      displaySmall: condensed(base.displaySmall, FontWeight.w700),
      headlineLarge: condensed(base.headlineLarge, FontWeight.w700),
      headlineMedium: condensed(base.headlineMedium, FontWeight.w700),
      headlineSmall: condensed(base.headlineSmall, FontWeight.w700),
      titleLarge: condensed(base.titleLarge, FontWeight.w700),
      titleMedium: condensed(base.titleMedium, FontWeight.w600),
      titleSmall: regular(base.titleSmall),
      bodyLarge: regular(base.bodyLarge),
      bodyMedium: regular(base.bodyMedium),
      bodySmall: regular(base.bodySmall),
      labelLarge: regular(base.labelLarge),
      labelMedium: regular(base.labelMedium),
      labelSmall: regular(base.labelSmall),
    );
  }
}
