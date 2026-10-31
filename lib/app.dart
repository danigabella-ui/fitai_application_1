import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';

/// Az app gyökere: itt dől el a cím, a nyelv, a téma és a kezdőképernyő.
class FitAgentApp extends StatelessWidget {
  const FitAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitAgent',
      debugShowCheckedModeBanner: false,
      // Magyar nyelvű rendszerelemek (dátumválasztó, menük, gombfeliratok)
      locale: const Locale('hu'),
      supportedLocales: const [Locale('hu')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Követi a telefon világos/sötét beállítását.
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
