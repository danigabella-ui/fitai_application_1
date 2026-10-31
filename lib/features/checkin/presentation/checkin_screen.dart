import 'package:flutter/material.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_header.dart';

/// Check-In fül: a reggeli gyors állapotfelmérés.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(
            title: 'Check-In',
            subtitle: huLongDate(DateTime.now()),
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'Itt lesz a reggeli check-in',
              message:
                  'Négy gyors csúszka: alvás, energia, izomláz és stressz.',
            ),
          ),
        ],
      ),
    );
  }
}
