import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/protection_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../models/app_models.dart';
import '../widgets/protection_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/shield_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _countdown = 3;
  bool _showCountdown = false;
  bool _isActivating = false;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(protectionStateProvider);
    final settings = ref.watch(settingsNotifierProvider);

    ref.listen<AsyncValue<ProtectionState>>(protectionStateProvider, (prev, next) {
      final nextState = next.valueOrNull;
      if (nextState == ProtectionState.alarmActive ||
          nextState == ProtectionState.pinRequired) {
        context.go('/alarm');
      }
    });

    final currentState = stateAsync.valueOrNull ?? ProtectionState.inactive;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        child: _showCountdown
            ? _CountdownView(
                countdown: _countdown,
                onCancel: _cancelCountdown,
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _Header(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ShieldSection(
                      state: currentState,
                      onTap: () {
                        if (currentState == ProtectionState.inactive) {
                          _startCountdownAndActivate();
                        } else if (currentState == ProtectionState.protected) {
                          _deactivateProtection(ref, context, settings);
                        } else if (currentState == ProtectionState.arming) {
                          _cancelCountdown();
                        }
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProtectionCard(
                      state: currentState,
                      onActivate: _startCountdownAndActivate,
                      onDeactivate: () =>
                          _deactivateProtection(ref, context, settings),
                      onCancel: _cancelCountdown,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildListDelegate([
                        FeatureCard(
                          icon: Icons.vibration_rounded,
                          title: 'Motion Alert',
                          description: 'Detect phone movement',
                          enabled: settings.motionProtectionEnabled,
                          color: AppTheme.iconBgPurple,
                          onToggle: (v) => ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleMotionProtection(v),
                          onTap: () => context.push('/motion-alarm'),
                        ),
                        FeatureCard(
                          icon: Icons.lock_person_rounded,
                          title: 'Break-In Alert',
                          description: 'Wrong PIN detection',
                          enabled: settings.breakInAlertEnabled,
                          color: AppTheme.iconBgRed,
                          onToggle: (v) => ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleBreakInAlert(v),
                          onTap: () => context.push('/break-in'),
                        ),
                        FeatureCard(
                          icon: Icons.airplanemode_active_rounded,
                          title: 'Airplane Alarm',
                          description: 'Detect network changes',
                          enabled: settings.airplaneAlarmEnabled,
                          color: AppTheme.iconBgBlue,
                          onToggle: (v) => ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleAirplaneAlarm(v),
                          onTap: () => context.push('/airplane-alarm'),
                        ),
                        FeatureCard(
                          icon: Icons.bolt_rounded,
                          title: 'Charging Alarm',
                          description: 'Detect charger events',
                          enabled: settings.chargingAlarmEnabled,
                          color: AppTheme.iconBgOrange,
                          onToggle: (v) => ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleChargingAlarm(v),
                          onTap: () => context.push('/charging-alarm'),
                        ),
                      ]),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
    );
  }

  Future<void> _startCountdownAndActivate() async {
    final settings = ref.read(settingsNotifierProvider);
    if (!settings.motionProtectionEnabled) {
      await ref.read(settingsNotifierProvider.notifier).toggleMotionProtection(true);
    }

    final delay = settings.alarmDelay > 0 ? settings.alarmDelay : 3;
    setState(() {
      _showCountdown = true;
      _countdown = delay;
      _isActivating = true;
    });

    for (int i = delay; i > 0; i--) {
      if (!mounted || !_isActivating) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted || !_isActivating) return;
    setState(() {
      _showCountdown = false;
      _isActivating = false;
    });

    try {
      await ref.read(protectionRepositoryProvider).activateProtection(skipDelay: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛡 BẢO VỆ ĐÃ BẬT! Đặt máy yên vị trí.'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kích hoạt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelCountdown() {
    setState(() {
      _showCountdown = false;
      _isActivating = false;
    });
    ref.read(protectionRepositoryProvider).cancelProtection();
  }

  Future<void> _deactivateProtection(
      WidgetRef ref, BuildContext context, AppSettings settings) async {
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
}

class _CountdownView extends StatefulWidget {
  final int countdown;
  final VoidCallback onCancel;

  const _CountdownView({
    required this.countdown,
    required this.onCancel,
  });

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
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android_rounded,
              size: 56,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đặt điện thoại xuống...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Không chạm vào máy trong quá trình kích hoạt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${widget.countdown}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Đang chuẩn bị cảm biến...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                Text(
                  'My Phone!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Keep your device safe',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ShieldSection extends StatelessWidget {
  final ProtectionState state;
  final VoidCallback? onTap;

  const _ShieldSection({required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: ShieldWidget(state: state),
        ),
      ),
    );
  }
}
