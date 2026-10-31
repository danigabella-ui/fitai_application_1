import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai_application_1/app.dart';

void main() {
  testWidgets('Az app elindul, és a négy fül megjelenik', (tester) async {
    await tester.pumpWidget(const FitAiApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
