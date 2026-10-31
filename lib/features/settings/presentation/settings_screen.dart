import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/files/file_service.dart';
import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/app_background.dart';
import '../application/api_key_controller.dart';
import '../application/backup_status_controller.dart';
import '../data/backup_repository.dart';

/// Beállítások: Gemini API-kulcs, valamint mentés és visszaállítás.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // API-kulcs
  // ---------------------------------------------------------------------------

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _busy = true);
    await ref.read(apiKeyProvider.notifier).save(key);
    if (!mounted) return;

    _keyController.clear();
    setState(() => _busy = false);
    _showMessage('API-kulcs elmentve.');
  }

  Future<void> _deleteKey() async {
    final confirmed = await _confirm(
      title: 'Törlöd az API-kulcsot?',
      message:
          'Az AI-funkciók addig nem működnek, amíg új kulcsot nem adsz meg.',
      confirmLabel: 'Törlés',
    );
    if (!confirmed) return;

    setState(() => _busy = true);
    await ref.read(apiKeyProvider.notifier).delete();
    if (!mounted) return;

    setState(() => _busy = false);
    _showMessage('API-kulcs törölve.');
  }

  // ---------------------------------------------------------------------------
  // Mentés és visszaállítás
  // ---------------------------------------------------------------------------

  Future<void> _prepareBackup() async {
    setState(() => _busy = true);

    String json;
    try {
      json = await ref.read(backupRepositoryProvider).exportJson();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Nem sikerült elkészíteni a mentést: $error');
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final fileName = 'fitai_mentes_${_fileDate(DateTime.now())}.json';

    // Kétlépéses mentés: az iPhone csak közvetlenül egy gombnyomás után
    // engedi megnyitni a megosztás menüt, ezért a fájlt előre elkészítjük,
    // és a párbeszédablak gombja indítja a tényleges mentést.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('A mentés elkészült'),
        content: const Text(
          'Mentsd el biztonságos helyre, például iCloudba vagy a Fájlok '
          'appba. Az API-kulcs nem kerül bele a mentésbe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _saveFile(fileName, json);
            },
            child: const Text('Fájl mentése'),
          ),
        ],
      ),
    );
  }

  void _saveFile(String fileName, String content) {
    // A mentést azonnal, a gombnyomáson belül kell elindítani.
    final saving = shareOrDownloadTextFile(
      fileName: fileName,
      content: content,
    );
    _finishSave(saving);
  }

  Future<void> _finishSave(Future<bool> saving) async {
    bool saved;
    try {
      saved = await saving;
    } catch (error) {
      if (mounted) _showMessage('Nem sikerült menteni a fájlt: $error');
      return;
    }
    if (!saved || !mounted) return;

    await ref.read(backupStatusProvider.notifier).markBackedUp();
    if (mounted) _showMessage('A mentés elkészült.');
  }

  Future<void> _restoreBackup() async {
    // A fájlválasztót azonnal, a gombnyomáson belül kell megnyitni.
    final picking = pickTextFile();

    String? text;
    try {
      text = await picking;
    } catch (error) {
      if (mounted) _showMessage('Nem sikerült megnyitni a fájlt: $error');
      return;
    }
    if (text == null || !mounted) return;

    final repository = ref.read(backupRepositoryProvider);

    BackupData backup;
    try {
      backup = repository.parse(text);
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    }

    final date = backup.exportedAt == null
        ? 'ismeretlen'
        : huDateTime(backup.exportedAt!);
    final hasProfile = backup.countOf('profile') > 0;

    final confirmed = await _confirm(
      title: 'Visszaállítod a mentést?',
      message: 'Mentés dátuma: $date\n'
          'Tartalma: ${hasProfile ? 'profil, ' : ''}'
          '${backup.countOf('measurements')} mérés, '
          '${backup.countOf('check_ins')} check-in, '
          '${backup.countOf('chat_messages')} chat-üzenet.\n\n'
          'A visszaállítás felülírja az appban jelenleg lévő összes adatot. '
          'Az API-kulcs nem változik.',
      confirmLabel: 'Visszaállítás',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await repository.restore(backup);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Nem sikerült a visszaállítás: $error');
      return;
    }
    if (!mounted) return;

    setState(() => _busy = false);
    _showMessage('A mentés visszaállítva.');
  }

  // ---------------------------------------------------------------------------
  // Segédfüggvények
  // ---------------------------------------------------------------------------

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static String _fileDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Felület
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiKey = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beállítások')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _SectionHeader(
            title: 'Gemini API-kulcs',
            description: 'Az AI ezzel a kulccsal éri el a Geminit. '
                'Csak ezen a készüléken tárolódik.',
          ),
          const SizedBox(height: 16),
          apiKey.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              'Nem sikerült beolvasni a kulcsot: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            data: (key) =>
                key == null ? _buildKeyInput() : _buildSavedKey(key),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Biztonsági mentés',
            description: 'Az összes adatodat egy fájlba mentheted, és '
                'onnan bármikor visszaállíthatod. Érdemes rendszeresen '
                'menteni, például hetente.',
          ),
          const SizedBox(height: 16),
          ref.watch(backupStatusProvider).maybeWhen(
                data: (status) => _BackupStatusView(
                  status: status,
                  formatDate: huDateTime,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _prepareBackup,
            icon: const Icon(Icons.save_alt),
            label: const Text('Mentés fájlba'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('Visszaállítás fájlból'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _keyController,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'API-kulcs',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Kulcs megjelenítése' : 'Kulcs elrejtése',
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _saveKey(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _saveKey,
          child: const Text('Kulcs mentése'),
        ),
      ],
    );
  }

  Widget _buildSavedKey(String key) {
    final theme = Theme.of(context);
    final masked =
        key.length > 4 ? '••••••••${key.substring(key.length - 4)}' : '••••';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
        title: const Text('Kulcs elmentve'),
        subtitle: Text(masked),
        trailing: TextButton(
          onPressed: _busy ? null : _deleteKey,
          child: const Text('Törlés'),
        ),
      ),
    );
  }
}

/// Az utolsó mentés ideje, és figyelmeztetés, ha régen volt.
class _BackupStatusView extends StatelessWidget {
  const _BackupStatusView({required this.status, required this.formatDate});

  final BackupStatus status;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = status.lastBackupAt;
    final days = status.daysSinceBackup;

    final String text;
    if (last == null) {
      text = 'Még nem készült mentés.';
    } else {
      final ago = days == 0 ? 'ma' : '$days napja';
      text = 'Utolsó mentés: ${formatDate(last)} ($ago)';
    }

    if (!status.isOverdue) {
      return Text(text, style: theme.textTheme.bodyMedium);
    }

    final warning = last == null
        ? 'Még nem mentetted az adataidat. Készíts egy mentést.'
        : 'Több mint $backupReminderDays napja nem mentettél. '
            'Készíts egy friss mentést.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy beállítás-szakasz címe és rövid leírása.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
