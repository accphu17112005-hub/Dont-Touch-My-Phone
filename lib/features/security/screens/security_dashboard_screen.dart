import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';

class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    final features = [
      _SecurityFeature(
        icon: Icons.airplanemode_active_rounded,
        title: 'Airplane Alarm',
        description: 'Alert when network connectivity changes or airplane mode is detected.',
        color: AppTheme.iconBgBlue,
        enabled: settings.airplaneAlarmEnabled,
        onToggle: (v) => ref.read(settingsNotifierProvider.notifier).toggleAirplaneAlarm(v),
        onTap: () => context.push('/airplane-alarm'),
      ),
      _SecurityFeature(
        icon: Icons.battery_charging_full_rounded,
        title: 'Battery Alarm',
        description: 'Alert when battery reaches the set threshold level.',
        color: AppTheme.iconBgGreen,
        enabled: settings.chargingAlarmEnabled,
        onToggle: (v) => ref.read(settingsNotifierProvider.notifier).toggleChargingAlarm(v),
        onTap: () => context.push('/charging-alarm'),
      ),
      _SecurityFeature(
        icon: Icons.vibration_rounded,
        title: 'Motion Alert',
        description: 'Detect movement and trigger alarm when phone is touched.',
        color: AppTheme.iconBgPurple,
        enabled: settings.motionProtectionEnabled,
        onToggle: (v) => ref.read(settingsNotifierProvider.notifier).toggleMotionProtection(v),
        onTap: () => context.push('/motion-alarm'),
      ),
      _SecurityFeature(
        icon: Icons.bolt_rounded,
        title: 'Charging Alarm',
        description: 'Alert when charger is connected or disconnected.',
        color: AppTheme.iconBgOrange,
        enabled: settings.chargingAlarmEnabled,
        onToggle: (v) => ref.read(settingsNotifierProvider.notifier).toggleChargingAlarm(v),
        onTap: () => context.push('/charging-alarm'),
      ),
      _SecurityFeature(
        icon: Icons.lock_person_rounded,
        title: 'Break-In Alert',
        description: 'Track wrong PIN entries and trigger intruder alert.',
        color: AppTheme.iconBgRed,
        enabled: settings.breakInAlertEnabled,
        onToggle: (v) => ref.read(settingsNotifierProvider.notifier).toggleBreakInAlert(v),
        onTap: () => context.push('/break-in'),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'My Phone!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure your security features',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _SecurityCard(feature: features[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _SecurityFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.enabled,
    required this.onToggle,
    required this.onTap,
  });
}

class _SecurityCard extends StatelessWidget {
  final _SecurityFeature feature;

  const _SecurityCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(feature.icon, color: feature.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Switch(
                    value: feature.enabled,
                    onChanged: feature.onToggle,
                    activeColor: feature.color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
