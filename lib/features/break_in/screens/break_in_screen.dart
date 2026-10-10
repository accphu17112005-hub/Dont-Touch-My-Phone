import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utils.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../models/alarm_event.dart';

class BreakInScreen extends ConsumerStatefulWidget {
  const BreakInScreen({super.key});

  @override
  ConsumerState<BreakInScreen> createState() => _BreakInScreenState();
}

class _BreakInScreenState extends ConsumerState<BreakInScreen> {
  List<AlarmEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final all = LocalStorageService.instance.getAlarmHistory();
    setState(() {
      _events = all.where((e) =>
          e.eventType == AlarmEventType.wrongPin ||
          e.eventType == AlarmEventType.intruderDetected ||
          e.eventType == AlarmEventType.breakInAttempt).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Break-In Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Illustration area
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_rounded,
                      size: 52, color: Colors.white),
                ),
              ),
              Center(
                child: Text(
                  'Previous Intrusion Events',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: _events.isEmpty
                      ? const _EmptyBreakIn()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _BreakInCard(event: _events[i]),
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

class _EmptyBreakIn extends StatelessWidget {
  const _EmptyBreakIn();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No break-in attempts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your phone is secure.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BreakInCard extends StatelessWidget {
  final AlarmEvent event;

  const _BreakInCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isIntruder = event.eventType == AlarmEventType.intruderDetected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isIntruder
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isIntruder ? Colors.red : Colors.orange).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isIntruder ? Icons.person_off_rounded : Icons.key_off_rounded,
                color: isIntruder ? Colors.red : Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.eventType.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isIntruder ? Colors.red : const Color(0xFF212121),
                        ),
                      ),
                      if (isIntruder) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ALERT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateTimeUtils.formatDateTime(event.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (event.failedAttempts != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${event.failedAttempts} failed PIN attempt${event.failedAttempts! > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
