import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/selected_tab.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../settings/presentation/restore_backup.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';
import 'profile_wizard_screen.dart';

/// Az első indítás képernyője. Akkor jelenik meg, ha még nincs elmentett
/// profil: innen indul a vezetett kitöltés, vagy egy mentés visszaállítása.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileWizardScreen(initial: UserProfile.empty),
      ),
    );
  }

  void _restore() {
    // A fájlválasztónak a gombnyomáson belül, azonnal kell megnyílnia.
    restoreBackupFromFile(
      context,
      onBusyChanged: (busy) {
        if (mounted) setState(() => _busy = busy);
      },
    );
  }

  /// Üres profilt ment, így az app legközelebb már nem ezzel a
  /// képernyővel indul. A Profil fülön emlékeztető kártya marad.
  Future<void> _later() async {
    setState(() => _busy = true);
    ref.read(selectedTabProvider.notifier).select(AppTabs.profile);
    try {
      await ref.read(profileProvider.notifier).save(UserProfile.empty);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = Colors.white.withValues(alpha: 0.88);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            // Halvány derengés a bal felső részen
            Positioned(
              left: -160,
              top: -180,
              width: 520,
              height: 520,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandGlow.withValues(alpha: 0.34),
                        AppColors.brandGlow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: CustomPaint(
                                size: Size(88, 64),
                                painter: _TrendLogoPainter(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'FitAgent',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 56,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Adatalapú fitnesz- és étrend-asszisztens',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: soft, fontSize: 17),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Mielőtt elkezdjük, ismerjük meg egymást: a '
                              'célod, az edzéseid, az étkezésed. Ebből '
                              'dolgozik majd az AI.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kb. 5 perc, 8 rövid lépés. Bármelyiket '
                              'kihagyhatod, és később is pótolhatod.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: soft,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 32),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.brandStart,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: _busy ? null : _start,
                              child: const Text('Kezdjük'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  width: 1.5,
                                ),
                              ),
                              onPressed: _busy ? null : _restore,
                              icon: const Icon(Icons.restore),
                              label: const Text('Van mentésem, visszaállítom'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Új telepítés után ezzel töltheted vissza a '
                              'mentett adataidat.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: _busy ? null : _later,
                              child: const Text('Később'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Az app ikonjának trendvonala: egyenes szakaszok, a végén kiemelt pont
/// halvány „glóriával”.
class _TrendLogoPainter extends CustomPainter {
  const _TrendLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 88;
    final sy = size.height / 64;
    Offset at(double x, double y) => Offset(x * sx, y * sy);

    final start = at(4, 56);
    final path = Path()..moveTo(start.dx, start.dy);
    for (final point in [at(26, 40), at(42, 46), at(62, 22), at(76, 14)]) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * sx
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = at(78, 12);
    canvas.drawCircle(
      dot,
      11 * sx,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawCircle(dot, 6 * sx, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
