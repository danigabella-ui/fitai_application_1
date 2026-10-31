import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

/// Hány nap után figyelmeztessen az app, hogy ideje menteni.
const int backupReminderDays = 7;

/// A biztonsági mentés állapota.
class BackupStatus {
  const BackupStatus({required this.lastBackupAt, required this.firstUsedAt});

  /// Az utolsó mentés ideje; null, ha még nem volt mentés.
  final DateTime? lastBackupAt;

  /// Mikor indult először az app ezen a készüléken.
  final DateTime firstUsedAt;

  /// Hány napja volt az utolsó mentés (null, ha még nem volt).
  int? get daysSinceBackup => lastBackupAt == null
      ? null
      : DateTime.now().difference(lastBackupAt!).inDays;

  /// Igaz, ha ideje menteni: az utolsó mentés (vagy ha még nem volt,
  /// az első használat) óta legalább [backupReminderDays] nap telt el.
  bool get isOverdue {
    final since = lastBackupAt ?? firstUsedAt;
    return DateTime.now().difference(since).inDays >= backupReminderDays;
  }
}

final backupStatusProvider =
    AsyncNotifierProvider<BackupStatusController, BackupStatus>(
  BackupStatusController.new,
);

class BackupStatusController extends AsyncNotifier<BackupStatus> {
  @override
  Future<BackupStatus> build() => _load();

  /// Rögzíti, hogy most készült mentés.
  Future<void> markBackedUp() async {
    await ref.read(settingsRepositoryProvider).setString(
          SettingsRepository.lastBackupAtKey,
          DateTime.now().toIso8601String(),
        );
    state = AsyncData(await _load());
  }

  Future<BackupStatus> _load() async {
    final repository = ref.read(settingsRepositoryProvider);

    final last = DateTime.tryParse(
      await repository.getString(SettingsRepository.lastBackupAtKey) ?? '',
    );

    var firstUsed = DateTime.tryParse(
      await repository.getString(SettingsRepository.firstUsedAtKey) ?? '',
    );
    if (firstUsed == null) {
      firstUsed = DateTime.now();
      await repository.setString(
        SettingsRepository.firstUsedAtKey,
        firstUsed.toIso8601String(),
      );
    }

    return BackupStatus(lastBackupAt: last, firstUsedAt: firstUsed);
  }
}
