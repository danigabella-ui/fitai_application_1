import 'package:flutter/material.dart';

/// Az app színpalettája: orchidea főszín, mély lila átmenettel,
/// grafit kísérőszínekkel.
abstract final class AppColors {
  // Márkaszínek
  static const Color primaryLight = Color(0xFF7D1E8C);
  static const Color primaryDark = Color(0xFFD27BEA);

  /// A színátmenet két vége (fejléc, ikon, betöltőképernyő).
  static const Color brandStart = Color(0xFF7D1E8C);
  static const Color brandEnd = Color(0xFF3E1F8A);

  /// A halvány derengés színe.
  static const Color brandGlow = Color(0xFFE9A6F5);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandStart, brandEnd],
  );

  // Világos mód
  static const Color lightSurface = Color(0xFFF7F7F9);
  static const Color lightOnSurface = Color(0xFF18181C);
  static const Color lightOnSurfaceVariant = Color(0xFF5A5A66);
  static const Color lightContainerLowest = Color(0xFFFFFFFF);
  static const Color lightContainerLow = Color(0xFFF1F1F4);
  static const Color lightContainer = Color(0xFFECECF0);
  static const Color lightContainerHigh = Color(0xFFE6E6EB);
  static const Color lightContainerHighest = Color(0xFFE0E0E6);
  static const Color lightOutline = Color(0xFF8A8A96);
  static const Color lightOutlineVariant = Color(0xFFD4D4DC);
  static const Color lightPrimaryContainer = Color(0xFFF6D9FB);
  static const Color lightOnPrimaryContainer = Color(0xFF33053D);

  // Sötét mód (grafit)
  static const Color darkSurface = Color(0xFF141417);
  static const Color darkOnSurface = Color(0xFFECECF1);
  static const Color darkOnSurfaceVariant = Color(0xFFA9A9B5);
  static const Color darkContainerLowest = Color(0xFF0F0F12);
  static const Color darkContainerLow = Color(0xFF1A1A1E);
  static const Color darkContainer = Color(0xFF1F1F24);
  static const Color darkContainerHigh = Color(0xFF26262C);
  static const Color darkContainerHighest = Color(0xFF2E2E35);
  static const Color darkOutline = Color(0xFF6E6E7A);
  static const Color darkOutlineVariant = Color(0xFF3A3A43);
  static const Color darkOnPrimary = Color(0xFF1E0626);
  static const Color darkPrimaryContainer = Color(0xFF5A1468);
  static const Color darkOnPrimaryContainer = Color(0xFFF6D9FB);
}
