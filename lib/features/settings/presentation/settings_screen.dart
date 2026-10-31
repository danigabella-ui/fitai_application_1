import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/api_key_controller.dart';

/// Beállítások: egyelőre a Gemini API-kulcs megadása.
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

  Future<void> _save() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _busy = true);
    await ref.read(apiKeyProvider.notifier).save(key);
    if (!mounted) return;

    _keyController.clear();
    setState(() => _busy = false);
    _showMessage('API-kulcs elmentve.');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Törlöd az API-kulcsot?'),
        content: const Text(
          'Az AI-funkciók addig nem működnek, amíg új kulcsot nem adsz meg.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await ref.read(apiKeyProvider.notifier).delete();
    if (!mounted) return;

    setState(() => _busy = false);
    _showMessage('API-kulcs törölve.');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiKey = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beállítások')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Gemini API-kulcs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Az AI ezzel a kulccsal éri el a Geminit. '
            'Csak ezen a készüléken tárolódik.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
        ],
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
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _save,
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
          onPressed: _busy ? null : _delete,
          child: const Text('Törlés'),
        ),
      ),
    );
  }
}
