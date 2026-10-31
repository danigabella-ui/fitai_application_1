import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

/// Naptár fül: heti terv edzésekkel, étkezésekkel és bevásárlólistával.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Naptár')),
      body: const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Itt lesz a heti terved',
        message: 'Edzések, étkezések és bevásárlólista egy helyen. '
            'Ha közbejön valami, az AI átrendezést javasol.',
      ),
    );
  }
}
