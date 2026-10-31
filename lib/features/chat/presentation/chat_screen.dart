import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_header.dart';

/// Chat fül: beszélgetés az AI-val.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(title: 'Chat', subtitle: 'Az AI-asszisztensed'),
          Expanded(
            child: EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Itt beszélgetsz majd az AI-val',
              message: 'Bemásolhatod a napi makróidat és az edzésnaplódat, '
                  'és étkezési javaslatot kérhetsz a fennmaradó makróid '
                  'alapján.',
            ),
          ),
        ],
      ),
    );
  }
}
