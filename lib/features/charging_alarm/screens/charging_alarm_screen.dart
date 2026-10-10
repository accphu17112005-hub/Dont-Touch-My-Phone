import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/protection_repository.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../models/alarm_event.dart';

class ChargingAlarmScreen extends ConsumerStatefulWidget {
  const ChargingAlarmScreen({super.key});

  @override
  ConsumerState<ChargingAlarmScreen> createState() => _ChargingAlarmScreenState();
}

class _ChargingAlarmScreenState extends ConsumerState<ChargingAlarmScreen> {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;
  BatteryState _batteryState = BatteryState.unknown;
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  Future<void> _initBattery() async {
    _batteryLevel = await _battery.batteryLevel;
    _batteryState = await _battery.batteryState;
    if (mounted) setState(() {});

    _batterySub = _battery.onBatteryStateChanged.listen(_onBatteryStateChanged);
  }

  void _onBatteryStateChanged(BatteryState state) async {
    final settings = ref.read(settingsNotifierProvider);

    if (state == BatteryState.charging && settings.chargingAlarmEnabled) {
      await LocalStorageService.instance.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.chargerConnected,
        details: 'Charger connected — battery level: $_batteryLevel%',
      ));
      if (settings.motionProtectionEnabled) {
        _triggerAlarm('Charger connected!');
      }
    } else if (state == BatteryState.discharging &&
        _batteryState == BatteryState.charging &&
        settings.chargingDisconnectAlarmEnabled) {
      await LocalStorageService.instance.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.chargerDisconnected,
        details: 'Charger disconnected — battery level: $_batteryLevel%',
      ));
      _triggerAlarm('Charger disconnected!');
    }

    // Battery threshold check
    if (settings.chargingAlarmEnabled && _batteryLevel >= settings.batteryThreshold) {
      await LocalStorageService.instance.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.batteryThresholdReached,
        details: 'Battery reached ${settings.batteryThreshold}% threshold',
      ));
    }

    setState(() {
      _batteryState = state;
    });
    _batteryLevel = await _battery.batteryLevel;
    if (mounted) setState(() {});
  }

  void _triggerAlarm(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ $msg'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    final isCharging = _batteryState == BatteryState.charging;
    final isFull = _batteryState == BatteryState.full;

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
                      'Charging Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Battery illustration
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCharging || isFull
                                ? Icons.battery_charging_full_rounded
                                : Icons.battery_4_bar_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        if (isCharging)
                          const Positioned(
                            right: 12,
                            top: 12,
                            child: Icon(Icons.bolt_rounded,
                                color: Colors.yellowAccent, size: 24),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_batteryLevel%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isCharging
                          ? '⚡ Charging'
                          : isFull
                              ? '✅ Full'
                              : '🔋 Discharging',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Charging protection toggle
                      _Card(
                        child: Column(
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
                                  child: const Icon(Icons.bolt_rounded, color: Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Charging Protection',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF212121))),
                                      Text('Alert when charger is connected',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.chargingAlarmEnabled,
                                  onChanged: notifier.toggleChargingAlarm,
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.power_off_rounded,
                                      color: Colors.red),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Disconnect Alarm',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF212121))),
                                      Text('Alert when charger is removed',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.chargingDisconnectAlarmEnabled,
                                  onChanged: (v) => notifier.update(
                                    settings.copyWith(chargingDisconnectAlarmEnabled: v),
                                  ),
                                  activeColor: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Battery threshold
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Battery Target',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF212121))),
                            const SizedBox(height: 4),
                            Text('Alert when battery reaches this level',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [60, 70, 80, 90, 100].map((v) {
                                final sel = settings.batteryThreshold == v;
                                return GestureDetector(
                                  onTap: () => notifier.setBatteryThreshold(v),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: sel ? Colors.green : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$v%',
                                        style: TextStyle(
                                          color: sel ? Colors.white : Colors.grey[700],
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
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
