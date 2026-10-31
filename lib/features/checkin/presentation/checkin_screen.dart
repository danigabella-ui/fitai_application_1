import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

/// Check-In fül: a reggeli gyors állapotfelmérés.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-In')),
      body: const EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'Itt lesz a reggeli check-in',
        message: 'Négy gyors csúszka: alvás, energia, izomláz és stressz.',
      ),
    );
  }
}
