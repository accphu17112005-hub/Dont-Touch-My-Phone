import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utils.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../models/alarm_event.dart';

class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({super.key});

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  List<AlarmEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _events = LocalStorageService.instance.getAlarmHistory();
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all alarm history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LocalStorageService.instance.clearAlarmHistory();
      _load();
    }
  }

  Color _eventColor(AlarmEventType type) {
    switch (type) {
      case AlarmEventType.motionDetected:
        return AppTheme.iconBgPurple;
      case AlarmEventType.wrongPin:
        return Colors.orange;
      case AlarmEventType.intruderDetected:
        return AppTheme.danger;
      case AlarmEventType.chargerConnected:
      case AlarmEventType.chargerDisconnected:
        return AppTheme.iconBgGreen;
      case AlarmEventType.batteryThresholdReached:
        return Colors.amber;
      case AlarmEventType.airplaneModeChanged:
        return AppTheme.iconBgBlue;
      case AlarmEventType.protectionActivated:
        return Colors.green;
      case AlarmEventType.protectionDeactivated:
        return Colors.grey;
      case AlarmEventType.breakInAttempt:
        return AppTheme.iconBgRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alarm History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Security event log',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_events.isNotEmpty)
                    IconButton(
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      tooltip: 'Clear history',
                    ),
                ],
              ),
            ),
            Expanded(
              child: _events.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _EventCard(
                        event: _events[i],
                        color: _eventColor(_events[i].eventType),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No events yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alarm events will appear here\nonce protection is activated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final AlarmEvent event;
  final Color color;

  const _EventCard({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  event.eventType.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventType.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.details,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.failedAttempts != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${event.failedAttempts} failed attempts',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateTimeUtils.formatTime(event.timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateTimeUtils.formatDate(event.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
