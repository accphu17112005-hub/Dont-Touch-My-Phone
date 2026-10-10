import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/protection_repository.dart';

class FlashVibrationScreen extends ConsumerWidget {
  const FlashVibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final engine = ref.read(alarmEngineProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Text(
                      'Flash & Vibration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 8),

                      // Flash section
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.flashlight_on_rounded,
                                      color: Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Flash Alarm',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF212121))),
                                      Text('Camera LED flashlight',
                                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.flashEnabled,
                                  onChanged: notifier.toggleFlash,
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                            if (!engine.hasFlash) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Flash not available on this device.',
                                        style: TextStyle(fontSize: 12, color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (settings.flashEnabled && engine.hasFlash) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Flash Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: ['slow', 'fast', 'continuous'].map((m) {
                                  final sel = settings.flashMode == m;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => notifier.setFlashMode(m),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: sel ? Colors.orange : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          m.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: sel ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Vibration section
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gradientTop.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.vibration_rounded,
                                      color: AppTheme.gradientTop),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Vibration Alarm',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF212121))),
                                      Text(
                                        engine.hasVibrator
                                            ? 'Haptic feedback'
                                            : 'Not available on this device',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.vibrationEnabled && engine.hasVibrator,
                                  onChanged: engine.hasVibrator ? notifier.toggleVibration : null,
                                  activeColor: AppTheme.gradientTop,
                                ),
                              ],
                            ),
                            if (settings.vibrationEnabled && engine.hasVibrator) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Vibration Strength',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: ['light', 'medium', 'strong'].map((s) {
                                  final sel = settings.vibrationStrength == s;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => notifier.setVibrationStrength(s),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: sel ? AppTheme.gradientTop : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          s.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: sel ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
