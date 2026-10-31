import 'package:flutter/material.dart';

import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';

/// Az app gyökere: itt dől el a cím, a téma és a kezdőképernyő.
class FitAiApp extends StatelessWidget {
  const FitAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Követi a telefon világos/sötét beállítását.
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
