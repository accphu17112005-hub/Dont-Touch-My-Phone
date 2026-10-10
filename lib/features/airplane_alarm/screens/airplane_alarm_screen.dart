import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../models/alarm_event.dart';

class AirplaneAlarmScreen extends ConsumerStatefulWidget {
  const AirplaneAlarmScreen({super.key});

  @override
  ConsumerState<AirplaneAlarmScreen> createState() => _AirplaneAlarmScreenState();
}

class _AirplaneAlarmScreenState extends ConsumerState<AirplaneAlarmScreen> {
  StreamSubscription<ConnectivityResult>? _connectSub;
  String _connectStatus = 'Unknown';
  bool _wasConnected = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
    _connectSub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final settings = ref.read(settingsNotifierProvider);
    if (!settings.airplaneAlarmEnabled) return;

    final wasConnected = _wasConnected;
    final isNowConnected = result != ConnectivityResult.none;

    if (wasConnected && !isNowConnected) {
      // Connectivity lost — possibly airplane mode
      LocalStorageService.instance.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.airplaneModeChanged,
        details: 'Network connectivity lost — possible airplane mode activation',
      ));
      _showAlert('Network connectivity lost!');
    } else if (!wasConnected && isNowConnected) {
      LocalStorageService.instance.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.airplaneModeChanged,
        details: 'Network connectivity restored',
      ));
    }

    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    if (!mounted) return;
    final isConnected = result != ConnectivityResult.none;
    setState(() {
      _wasConnected = isConnected;
      if (result == ConnectivityResult.wifi) {
        _connectStatus = 'WiFi';
      } else if (result == ConnectivityResult.mobile) {
        _connectStatus = 'Mobile Data';
      } else if (result == ConnectivityResult.ethernet) {
        _connectStatus = 'Ethernet';
      } else {
        _connectStatus = 'No Connection';
      }
    });
  }

  void _showAlert(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $msg'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    super.dispose();
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
                      'Airplane Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Airplane illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.airplanemode_active_rounded,
                    size: 60,
                    color: Colors.white,
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Main toggle card
                      _Card(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.airplanemode_active_rounded,
                                      color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Airplane Alarm',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                      Text(
                                        'Alert when connectivity changes',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.airplaneAlarmEnabled,
                                  onChanged: notifier.toggleAirplaneAlarm,
                                  activeColor: Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status card
                      _Card(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (_connectStatus == 'No Connection'
                                    ? Colors.red
                                    : Colors.green).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _connectStatus == 'No Connection'
                                    ? Icons.wifi_off_rounded
                                    : Icons.wifi_rounded,
                                color: _connectStatus == 'No Connection'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Current Status',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF212121))),
                                Text(
                                  _connectStatus,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _connectStatus == 'No Connection'
                                        ? Colors.red
                                        : Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Platform limitation notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Platform Limitation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Android/iOS do not provide a public API that allows apps '
                              'to directly read or prevent airplane mode changes at OS level.\n\n'
                              'This feature detects network connectivity loss as an indicator '
                              'of possible airplane mode activation. The alarm triggers when '
                              'connectivity is lost while protection is active.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                                height: 1.5,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
