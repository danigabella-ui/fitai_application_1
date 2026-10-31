import 'package:flutter/material.dart';

/// Az app színei és alapstílusa egy helyen.
/// Ha a kinézeten változtatunk, elég ezt az egy fájlt módosítani.
abstract final class AppTheme {
  /// Ebből az alapszínből generálja a Flutter a teljes színpalettát.
  static const Color _seedColor = Color(0xFF3D5A80);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
