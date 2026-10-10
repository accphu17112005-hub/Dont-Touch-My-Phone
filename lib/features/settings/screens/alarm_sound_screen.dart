import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/services/alarm_engine.dart';
import '../../../data/repositories/protection_repository.dart';

class AlarmSoundScreen extends ConsumerStatefulWidget {
  const AlarmSoundScreen({super.key});

  @override
  ConsumerState<AlarmSoundScreen> createState() => _AlarmSoundScreenState();
}

class _AlarmSoundScreenState extends ConsumerState<AlarmSoundScreen> {
  String? _previewingId;

  Future<void> _previewSound(String soundId, double volume) async {
    final engine = ref.read(alarmEngineProvider);
    if (_previewingId == soundId) {
      await engine.stopPreview();
      setState(() => _previewingId = null);
    } else {
      setState(() => _previewingId = soundId);
      await engine.previewSound(soundId, volume);
      // Auto-stop after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _previewingId == soundId) {
          setState(() => _previewingId = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Text(
                      'Alarm Sound',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Volume slider
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded,
                                    color: Color(0xFF6A1B9A)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Volume',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(settings.soundVolume * 100).round()}%',
                                  style: const TextStyle(
                                    color: Color(0xFF6A1B9A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: settings.soundVolume,
                              onChanged: notifier.setVolume,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'CHOOSE SOUND',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // Sound list
                      ...AlarmSounds.sounds.map((sound) {
                        final isSelected = settings.selectedSound == sound['id'];
                        final isPreviewing = _previewingId == sound['id'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF6A1B9A), width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6A1B9A).withOpacity(0.12)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  sound['icon']!,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            title: Text(
                              sound['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF6A1B9A)
                                    : const Color(0xFF212121),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _previewSound(
                                      sound['id']!, settings.soundVolume),
                                  icon: Icon(
                                    isPreviewing
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                    color: const Color(0xFF6A1B9A),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF6A1B9A)),
                              ],
                            ),
                            onTap: () => notifier.setSelectedSound(sound['id']!),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Note about assets
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Place royalty-free .mp3 files in assets/sounds/ folder. '
                                'Filenames must match the sound IDs (e.g. police_siren.mp3).',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange[900]),
                              ),
                            ),
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
