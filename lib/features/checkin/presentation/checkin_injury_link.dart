import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/dialogs.dart';
import '../../profile/application/injuries_controller.dart';
import '../../profile/domain/injury.dart';
import '../../profile/presentation/injury_update_screen.dart';
import '../../profile/presentation/injury_widgets.dart';
import '../domain/check_in.dart';

/// A mai check-in mentése után: ha egy újonnan jelzett fájdalom helyén
/// nyitott (aktív vagy rehabilitációs) sérülés van a naplóban, felajánlja,
/// hogy most frissítsd az állapotát.
///
/// Csak az új fájdalomhelyekre kérdez: ha a mai check-int módosítod, a
/// [previous]-ban már szereplő helyekre nem kérdez újra. Egy sérülésre
/// legfeljebb egyszer kérdez.
Future<void> offerInjuryUpdates(
  BuildContext context, {
  required CheckIn checkIn,
  CheckIn? previous,
}) async {
  final previousKeys = {
    for (final pain in previous?.pains ?? const <PainSpot>[]) pain.key,
  };
  final newSpots = [
    for (final pain in checkIn.pains)
      if (!previousKeys.contains(pain.key)) pain,
  ];
  if (newSpots.isEmpty) return;

  final container = ProviderScope.containerOf(context, listen: false);
  List<Injury> injuries;
  try {
    injuries = await container.read(injuriesProvider.future);
  } catch (_) {
    // Ha a napló nem olvasható, egyszerűen nem kérdezünk.
    return;
  }

  final asked = <String>{};
  for (final spot in newSpots) {
    for (final injury in injuries) {
      final id = injury.id;
      if (id == null || asked.contains(id) || !injury.isOpen) continue;
      if (injury.area != spot.area) continue;
      if (!sidesOverlap(injury.side, spot.side)) continue;
      asked.add(id);

      if (!context.mounted) return;
      final confirmed = await showConfirmDialog(
        context,
        title: 'Frissíted a sérülést?',
        message: 'Ma fájdalmat jeleztél: ${spot.label}.\n\n'
            'Ezen a helyen nyitott sérülés van a naplódban: '
            '${injuryTitle(injury)} (${injury.status.label.toLowerCase()}). '
            'Frissíted most az állapotát?',
        confirmLabel: 'Frissítés',
        cancelLabel: 'Most nem',
      );
      if (!confirmed) continue;

      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InjuryUpdateScreen(injury: injury),
        ),
      );
    }
  }
}
