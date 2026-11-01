import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/files/file_service.dart';
import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../checkin/application/checkin_controller.dart';
import '../../profile/application/injuries_controller.dart';
import '../../profile/application/measurements_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../data/backup_repository.dart';

/// Mentés visszaállítása fájlból: fájlválasztás, ellenőrzés, megerősítés,
/// majd az adatok cseréje. A Beállítások és az üdvözlőképernyő is ezt
/// használja.
///
/// FONTOS: közvetlenül a gombnyomásból kell meghívni. Az iPhone csak akkor
/// engedi megnyitni a fájlválasztót, ha az a gombnyomás után azonnal,
/// minden várakozás (await) előtt indul. Ez a függvény az első sorában
/// nyitja meg.
///
/// Az [onBusyChanged] jelzi, amíg a visszaállítás fut (a gombok
/// letiltásához). Igazat ad vissza, ha a visszaállítás megtörtént.
Future<bool> restoreBackupFromFile(
  BuildContext context, {
  ValueChanged<bool>? onBusyChanged,
}) async {
  // A fájlválasztó azonnal, a gombnyomáson belül nyílik meg.
  final picking = pickTextFile();

  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final repository = container.read(backupRepositoryProvider);

  String? text;
  try {
    text = await picking;
  } catch (error) {
    showMessageWith(messenger, 'Nem sikerült megnyitni a fájlt: $error');
    return false;
  }
  if (text == null || !context.mounted) return false;

  BackupData backup;
  try {
    backup = repository.parse(text);
  } on FormatException catch (error) {
    showMessageWith(messenger, error.message);
    return false;
  }

  final date =
      backup.exportedAt == null ? 'ismeretlen' : huDateTime(backup.exportedAt!);
  final hasProfile = backup.countOf('profile') > 0;

  final confirmed = await showConfirmDialog(
    context,
    title: 'Visszaállítod a mentést?',
    message: 'Mentés dátuma: $date\n'
        'Tartalma: ${hasProfile ? 'profil, ' : ''}'
        '${backup.countOf('measurements')} mérés, '
        '${backup.countOf('injuries')} sérülés, '
        '${backup.countOf('check_ins')} check-in, '
        '${backup.countOf('chat_messages')} chat-üzenet.\n\n'
        'A visszaállítás felülírja az appban jelenleg lévő összes adatot. '
        'Az API-kulcs nem változik.',
    confirmLabel: 'Visszaállítás',
  );
  if (!confirmed) return false;

  onBusyChanged?.call(true);
  try {
    await repository.restore(backup);
  } catch (error) {
    onBusyChanged?.call(false);
    showMessageWith(messenger, 'Nem sikerült a visszaállítás: $error');
    return false;
  }
  onBusyChanged?.call(false);

  // A képernyők újraolvassák a visszaállított adatokat.
  container.invalidate(profileProvider);
  container.invalidate(measurementsProvider);
  container.invalidate(injuriesProvider);
  container.invalidate(checkInsProvider);

  showMessageWith(messenger, 'A mentés visszaállítva.');
  return true;
}
