import 'package:flutter/material.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dialogs.dart';
import '../domain/check_in.dart';
import 'checkin_form.dart';

/// Egy nap check-injének kitöltése, pótlása vagy javítása.
///
/// Mentés után bezárul, és visszaadja az elmentett check-int; a megnyitó
/// képernyő írja ki a visszajelzést.
class CheckInEditScreen extends StatefulWidget {
  const CheckInEditScreen({super.key, required this.day, this.existing});

  final DateTime day;

  /// A nap meglévő check-inje; null, ha most pótoljuk.
  final CheckIn? existing;

  @override
  State<CheckInEditScreen> createState() => _CheckInEditScreenState();
}

class _CheckInEditScreenState extends State<CheckInEditScreen> {
  bool _dirty = false;

  bool get _isToday => CheckIn.isSameDay(widget.day, DateTime.now());

  Future<void> _handleBack() async {
    if (!_dirty) {
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
    final existing = widget.existing;

    final String helper;
    if (existing == null) {
      helper = _isToday
          ? 'Állítsd be mind a négy csúszkát, a többi nem kötelező.'
          : 'Ennek a napnak még nincs check-inje, most pótolhatod.';
    } else {
      helper = 'Csak azt módosítsd, ami nem stimmel.';
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isToday ? 'Mai check-in' : huLongDate(widget.day)),
        ),
        body: AppBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                helper,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              CheckInForm(
                day: widget.day,
                existing: existing,
                onDirtyChanged: (dirty) => setState(() => _dirty = dirty),
                onSaved: (saved) => Navigator.of(context).pop(saved),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
