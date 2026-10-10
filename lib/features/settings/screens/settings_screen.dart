import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/local/local_storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    // SECURITY section
                    _SectionHeader('SECURITY'),
                    _SettingsTile(
                      icon: Icons.pin_rounded,
                      iconColor: AppTheme.iconBgPurple,
                      title: 'Security PIN',
                      subtitle: settings.pinEnabled ? 'PIN is enabled' : 'No PIN set',
                      onTap: () => context.push('/change-pin'),
                    ),
                    _SettingsTile(
                      icon: Icons.tune_rounded,
                      iconColor: AppTheme.iconBgBlue,
                      title: 'Motion Sensitivity',
                      subtitle: _sensitivityLabel(settings.motionSensitivity),
                      onTap: () => context.push('/motion-alarm'),
                    ),
                    _SettingsTile(
                      icon: Icons.timer_outlined,
                      iconColor: AppTheme.iconBgOrange,
                      title: 'Alarm Delay',
                      subtitle: '${settings.alarmDelay} seconds',
                      onTap: () => context.push('/motion-alarm'),
                    ),
                    _SettingsTile(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppTheme.iconBgRed,
                      title: 'Wrong PIN Protection',
                      subtitle: 'Trigger after ${settings.wrongPinThreshold} attempts',
                      onTap: () => _showWrongPinDialog(context, ref, settings.wrongPinThreshold),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_person_rounded,
                      iconColor: AppTheme.iconBgRed,
                      title: 'Break-In Alert',
                      subtitle: settings.breakInAlertEnabled ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: settings.breakInAlertEnabled,
                        onChanged: notifier.toggleBreakInAlert,
                        activeColor: AppTheme.gradientTop,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onTap: () => context.push('/break-in'),
                    ),

                    const SizedBox(height: 20),
                    _SectionHeader('ALARM'),
                    _SettingsTile(
                      icon: Icons.music_note_rounded,
                      iconColor: AppTheme.iconBgPurple,
                      title: 'Alarm Sound',
                      subtitle: _soundName(settings.selectedSound),
                      onTap: () => context.push('/alarm-sound'),
                    ),
                    _SettingsTile(
                      icon: Icons.volume_up_rounded,
                      iconColor: AppTheme.iconBgBlue,
                      title: 'Volume',
                      subtitle: '${(settings.soundVolume * 100).round()}%',
                      onTap: () => context.push('/alarm-sound'),
                    ),
                    _SettingsTile(
                      icon: Icons.flashlight_on_rounded,
                      iconColor: AppTheme.iconBgOrange,
                      title: 'Flash Alarm',
                      subtitle: settings.flashEnabled ? 'Mode: ${settings.flashMode}' : 'Disabled',
                      trailing: Switch(
                        value: settings.flashEnabled,
                        onChanged: notifier.toggleFlash,
                        activeColor: AppTheme.gradientTop,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onTap: () => context.push('/flash-vibration'),
                    ),
                    _SettingsTile(
                      icon: Icons.vibration_rounded,
                      iconColor: AppTheme.iconBgGreen,
                      title: 'Vibration Alarm',
                      subtitle: settings.vibrationEnabled
                          ? 'Strength: ${settings.vibrationStrength}'
                          : 'Disabled',
                      trailing: Switch(
                        value: settings.vibrationEnabled,
                        onChanged: notifier.toggleVibration,
                        activeColor: AppTheme.gradientTop,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onTap: () => context.push('/flash-vibration'),
                    ),

                    const SizedBox(height: 20),
                    _SectionHeader('BATTERY'),
                    _SettingsTile(
                      icon: Icons.bolt_rounded,
                      iconColor: AppTheme.iconBgOrange,
                      title: 'Charging Alarm',
                      subtitle: settings.chargingAlarmEnabled ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: settings.chargingAlarmEnabled,
                        onChanged: notifier.toggleChargingAlarm,
                        activeColor: AppTheme.gradientTop,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onTap: () => context.push('/charging-alarm'),
                    ),
                    _SettingsTile(
                      icon: Icons.battery_4_bar_rounded,
                      iconColor: AppTheme.iconBgGreen,
                      title: 'Battery Threshold',
                      subtitle: '${settings.batteryThreshold}%',
                      onTap: () => _showBatteryDialog(context, ref, settings.batteryThreshold),
                    ),

                    const SizedBox(height: 20),
                    _SectionHeader('GENERAL'),
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Dark Mode',
                      subtitle: settings.darkMode ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: settings.darkMode,
                        onChanged: notifier.toggleDarkMode,
                        activeColor: AppTheme.gradientTop,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.blue,
                      title: 'About',
                      subtitle: "Don't Touch My Phone v1.0.0",
                      onTap: () => _showAboutDialog(context),
                    ),

                    // Developer test mode (debug only)
                    if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                      const SizedBox(height: 20),
                      _SectionHeader('DEVELOPER'),
                      _SettingsTile(
                        icon: Icons.bug_report_rounded,
                        iconColor: Colors.teal,
                        title: 'Test Mode',
                        subtitle: 'Simulate alarm events',
                        onTap: () => _showTestMode(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sensitivityLabel(double v) {
    if (v >= 3.0) return 'Low';
    if (v >= 1.5) return 'Medium';
    return 'High';
  }

  String _soundName(String id) {
    const map = {
      'police_siren': 'Police Siren',
      'emergency_siren': 'Emergency Siren',
      'car_alarm': 'Car Alarm',
      'loud_beep': 'Loud Beep',
      'warning': 'Warning',
      'funny_alarm': 'Funny Alarm',
      'scary_alarm': 'Scary Alarm',
      'screaming_alarm': 'Screaming Alarm',
    };
    return map[id] ?? id;
  }

  void _showWrongPinDialog(BuildContext ctx, WidgetRef ref, int current) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Wrong PIN Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [3, 5, 10].map((v) {
            return RadioListTile<int>(
              value: v,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsNotifierProvider.notifier).setWrongPinThreshold(val);
                  Navigator.pop(ctx);
                }
              },
              title: Text('After $v attempts'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBatteryDialog(BuildContext ctx, WidgetRef ref, int current) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Battery Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [60, 70, 80, 90, 100].map((v) {
            return RadioListTile<int>(
              value: v,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsNotifierProvider.notifier).setBatteryThreshold(val);
                  Navigator.pop(ctx);
                }
              },
              title: Text('$v%'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext ctx) {
    showAboutDialog(
      context: ctx,
      applicationName: "Don't Touch My Phone",
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.security_rounded, size: 48, color: Color(0xFF6A1B9A)),
      children: [
        const Text(
          'A production-quality mobile security application that protects your phone from unauthorized access.',
        ),
      ],
    );
  }

  void _showTestMode(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TestModeSheet(ref: ref),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _TestModeSheet extends StatelessWidget {
  final WidgetRef ref;
  const _TestModeSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final tests = [
      ('TEST MOTION', Icons.vibration_rounded, Colors.purple),
      ('TEST ALARM', Icons.alarm_rounded, Colors.red),
      ('TEST FLASH', Icons.flashlight_on_rounded, Colors.orange),
      ('TEST VIBRATION', Icons.phone_android_rounded, Colors.blue),
      ('TEST WRONG PIN', Icons.lock_rounded, Colors.pink),
      ('TEST CHARGING', Icons.bolt_rounded, Colors.green),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧪 Developer Test Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Simulate events without real hardware',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tests.map((t) {
              return ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t.$1} triggered (test)')),
                  );
                },
                icon: Icon(t.$2, size: 16),
                label: Text(t.$1, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.$3,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
