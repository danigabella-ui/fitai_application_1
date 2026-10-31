import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';
import 'profile_draft.dart';
import 'profile_sections.dart';
import 'section_fields.dart';

/// Egy profilszakasz szerkesztése külön oldalon, alul Mentés gombbal.
/// Ha mentés nélkül lépnél vissza, rákérdez, hogy elveted-e a módosításokat.
class ProfileSectionEditScreen extends ConsumerStatefulWidget {
  const ProfileSectionEditScreen({
    super.key,
    required this.section,
    required this.profile,
  });

  final ProfileSection section;

  /// A profil a szerkesztés megkezdésekor.
  final UserProfile profile;

  @override
  ConsumerState<ProfileSectionEditScreen> createState() =>
      _ProfileSectionEditScreenState();
}

class _ProfileSectionEditScreenState
    extends ConsumerState<ProfileSectionEditScreen> {
  late final ProfileDraft _draft = ProfileDraft(widget.profile);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final updated = _draft.applyTo(widget.profile, widget.section);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
      return;
    }

    navigator.pop();
    showMessageWith(messenger, 'Elmentve.');
  }

  Future<void> _handleBack() async {
    if (!_draft.hasChanges(widget.profile, widget.section)) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showConfirmDialog(
      context,
      title: 'Elveted a módosításokat?',
      message: 'Ha most kilépsz, a változtatásaid nem mentődnek el.',
      confirmLabel: 'Elvetem',
    );
    if (!discard || !mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<Object?>(
      // A visszalépést mi kezeljük, hogy rá tudjunk kérdezni.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.section.title)),
        body: AppBackground(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  widget.section.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SectionFields(
                  section: widget.section,
                  draft: _draft,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Mentés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
