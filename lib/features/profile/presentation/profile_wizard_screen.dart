import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/selected_tab.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';
import 'profile_draft.dart';
import 'profile_sections.dart';
import 'section_fields.dart';

/// Vezetett kitöltés: a profil szakaszai egymás után, lépésenként.
/// Minden lépés kihagyható. A végén a válaszstílus választása után
/// egyszerre mentődik minden, és az app a Profil fülre visz.
class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key, required this.initial});

  /// A profil a kitöltés kezdetekor (első indításkor üres).
  final UserProfile initial;

  @override
  ConsumerState<ProfileWizardScreen> createState() =>
      _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  static const List<ProfileSection> _sections = ProfileSection.values;

  late UserProfile _profile = widget.initial;
  late final ProfileDraft _draft = ProfileDraft(widget.initial);
  late ResponseStyle _style = widget.initial.responseStyle;
  final _formKey = GlobalKey<FormState>();

  /// 0-tól a szakaszok száma mínusz egyig: a szakaszok lépései.
  /// Ha egyenlő a szakaszok számával: a záró képernyő.
  int _step = 0;
  bool _saving = false;

  bool get _isFinish => _step >= _sections.length;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _next() {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;
    setState(() {
      _profile = _draft.applyTo(_profile, _sections[_step]);
      _step++;
    });
  }

  void _skip() => setState(() => _step++);

  Future<void> _back() async {
    if (_step > 0) {
      setState(() => _step--);
      return;
    }

    final changed = !_profile.sameAs(widget.initial) ||
        _draft.hasChanges(_profile, _sections.first);
    if (!changed) {
      Navigator.of(context).pop();
      return;
    }

    final leave = await showConfirmDialog(
      context,
      title: 'Kilépsz a kitöltésből?',
      message: 'Az eddig megadott adatok nem mentődnek el.',
      confirmLabel: 'Kilépés',
    );
    if (!leave || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    // A kitöltés után a Profil fül jelenjen meg.
    ref.read(selectedTabProvider.notifier).select(AppTabs.profile);

    try {
      await ref
          .read(profileProvider.notifier)
          .save(_profile.copyWith(responseStyle: _style));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _sections.length;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Vissza',
                        onPressed: _saving ? null : _back,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _isFinish ? '' : '${_step + 1} / $total',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      if (_isFinish)
                        const SizedBox(width: 48)
                      else
                        TextButton(
                          onPressed: _skip,
                          child: const Text('Kihagyom'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProgressBar(step: _step, total: total),
                ),
                Expanded(
                  child: _isFinish ? _buildFinish(context) : _buildStep(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    final theme = Theme.of(context);
    final section = _sections[_step];
    final isLast = _step == _sections.length - 1;

    return Form(
      key: _formKey,
      child: ListView(
        // Új lépésnél a lista a tetejéről indul.
        key: ValueKey(_step),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Text(
            section.title,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 38),
          ),
          const SizedBox(height: 8),
          Text(
            section.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          SectionFields(
            section: section,
            draft: _draft,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _next,
            child: Text(isLast ? 'Befejezés' : 'Tovább'),
          ),
          const SizedBox(height: 10),
          Text(
            'Bármikor módosíthatod a Profil fülön.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinish(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _sections.length;
    final missing =
        _sections.where((section) => !section.isFilledIn(_profile)).toList();
    final filledCount = total - missing.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kész is!',
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 38),
        ),
        const SizedBox(height: 8),
        Text(
          missing.isEmpty
              ? 'Minden szakaszt kitöltöttél. Bármikor módosíthatod '
                  'őket a Profil fülön.'
              : 'Kitöltött szakaszok: $filledCount / $total. '
                  'A kihagyottakat a Profil fülön bármikor pótolhatod:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final section in missing) Chip(label: Text(section.title)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Ha van sérülésed vagy korlátozásod, a Profil fül Sérülések '
          'nézetében rögzítheted, és ott követheted, hogyan javul.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hogyan válaszoljon az AI?',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SegmentedButton<ResponseStyle>(
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    for (final style in ResponseStyle.values)
                      ButtonSegment(value: style, label: Text(style.label)),
                  ],
                  selected: {_style},
                  onSelectionChanged: (selection) =>
                      setState(() => _style = selection.first),
                ),
                const SizedBox(height: 10),
                Text(
                  _style.help,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saving ? null : _finish,
          child: const Text('Tovább a profilhoz'),
        ),
      ],
    );
  }
}

/// A lépések állását mutató csík: minden szakasznak egy szelet.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
