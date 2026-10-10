import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/protection_repository.dart';
import '../../../models/app_models.dart';

class MotionAlarmScreen extends ConsumerStatefulWidget {
  const MotionAlarmScreen({super.key});

  @override
  ConsumerState<MotionAlarmScreen> createState() => _MotionAlarmScreenState();
}

class _MotionAlarmScreenState extends ConsumerState<MotionAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownCtrl;
  int _countdown = 3;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _countdownCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCountdownAndActivate() async {
    final settings = ref.read(settingsNotifierProvider);
    setState(() {
      _showCountdown = true;
      _countdown = settings.alarmDelay > 0 ? settings.alarmDelay : 3;
    });

    for (int i = _countdown; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() => _showCountdown = false);
    await ref.read(protectionRepositoryProvider).activateProtection(skipDelay: true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final stateAsync = ref.watch(protectionStateProvider);

    // Auto-navigate to alarm screen when motion triggers alarm
    ref.listen<AsyncValue<ProtectionState>>(protectionStateProvider, (prev, next) {
      final nextState = next.valueOrNull;
      if (nextState == ProtectionState.alarmActive ||
          nextState == ProtectionState.pinRequired) {
        if (!mounted) return;
        context.go('/alarm');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: _showCountdown
              ? _CountdownView(
                  countdown: _countdown,
                  onCancel: () => setState(() => _showCountdown = false),
                )
              : _MotionContent(
                  settings: settings,
                  stateAsync: stateAsync,
                  ref: ref,
                  onActivate: _startCountdownAndActivate,
                ),
        ),
      ),
    );
  }
}

class _CountdownView extends StatefulWidget {
  final int countdown;
  final VoidCallback onCancel;
  const _CountdownView({required this.countdown, required this.onCancel});

  @override
  State<_CountdownView> createState() => _CountdownViewState();
}

class _CountdownViewState extends State<_CountdownView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_CountdownView old) {
    super.didUpdateWidget(old);
    if (old.countdown != widget.countdown) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Place your phone down...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, __) => Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                ),
                child: Center(
                  child: Text(
                    '${widget.countdown}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Protection activating...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: const Text(
              'HỦY KÍCH HOẠT',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white38),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotionContent extends StatelessWidget {
  final AppSettings settings;
  final AsyncValue<ProtectionState> stateAsync;
  final WidgetRef ref;
  final VoidCallback onActivate;

  const _MotionContent({
    required this.settings,
    required this.stateAsync,
    required this.ref,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final isProtected = stateAsync.maybeWhen(
      data: (s) => s == ProtectionState.protected || s == ProtectionState.arming,
      orElse: () => false,
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: const Text(
            'Motion Alert',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Don't Touch\nMy Phone!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detect movement when someone picks up or moves your phone.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Main card
                _Card(
                  child: Column(
                    children: [
                      _SettingRow(
                        title: 'Motion Protection',
                        subtitle: 'Enable motion detection alarm',
                        trailing: Switch(
                          value: settings.motionProtectionEnabled,
                          onChanged: (v) => ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleMotionProtection(v),
                          activeColor: AppTheme.gradientTop,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sensitivity card
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Sensitivity'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['low', 'medium', 'high'].map((s) {
                          final selected =
                              s == _sensitivityLabel(settings.motionSensitivity);
                          return _SensitivityChip(
                            label: s.toUpperCase(),
                            selected: selected,
                            onTap: () {
                              final val = s == 'low'
                                  ? 3.5
                                  : s == 'medium'
                                      ? 2.0
                                      : 1.0;
                              ref
                                  .read(settingsNotifierProvider.notifier)
                                  .setSensitivity(val);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: settings.motionSensitivity,
                        min: 0.5,
                        max: 5.0,
                        divisions: 9,
                        onChanged: (v) => ref
                            .read(settingsNotifierProvider.notifier)
                            .setSensitivity(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alarm delay
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Alarm Delay'),
                      const SizedBox(height: 4),
                      Text(
                        'Time to cancel before alarm triggers',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [0, 1, 2, 3, 5].map((delay) {
                          final selected = settings.alarmDelay == delay;
                          return ChoiceChip(
                            label: Text('${delay}s'),
                            selected: selected,
                            selectedColor: AppTheme.gradientTop.withOpacity(0.2),
                            onSelected: (_) => ref
                                .read(settingsNotifierProvider.notifier)
                                .setAlarmDelay(delay),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppTheme.gradientTop
                                  : Colors.grey[700],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Place your phone down and activate protection. '
                          'You will have ${settings.alarmDelay} seconds to put it down.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Activate button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isProtected
                        ? () async {
                            final settings = ref.read(settingsNotifierProvider);
                            if (settings.pinEnabled) {
                              context.push('/verify-pin', extra: {
                                'purpose': 'deactivate',
                                'onSuccess': () async {
                                  await ref.read(protectionRepositoryProvider).deactivateAlarm();
                                },
                              });
                            } else {
                              await ref.read(protectionRepositoryProvider).cancelProtection();
                            }
                          }
                        : () {
                            if (!settings.motionProtectionEnabled) {
                              ref.read(settingsNotifierProvider.notifier).toggleMotionProtection(true);
                            }
                            onActivate();
                          },
                    icon: Icon(isProtected
                        ? Icons.stop_circle_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(
                      isProtected ? 'DEACTIVATE PROTECTION' : 'ACTIVATE NOW',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isProtected
                          ? Colors.red[700]
                          : AppTheme.gradientTop,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _sensitivityLabel(double v) {
    if (v >= 3.0) return 'low';
    if (v >= 1.5) return 'medium';
    return 'high';
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF212121),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF212121))),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _SensitivityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SensitivityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gradientTop : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
