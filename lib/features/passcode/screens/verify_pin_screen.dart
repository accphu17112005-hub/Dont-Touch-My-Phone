import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../data/repositories/protection_repository.dart';
import '../../../models/alarm_event.dart';

class VerifyPinScreen extends ConsumerStatefulWidget {
  final String purpose;
  final Function? onSuccess;

  const VerifyPinScreen({super.key, required this.purpose, this.onSuccess});

  @override
  ConsumerState<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends ConsumerState<VerifyPinScreen>
    with SingleTickerProviderStateMixin {
  List<String> _pin = [];
  bool _isError = false;
  String _errorMsg = '';
  int _attemptCount = 0;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      _pin.add(digit);
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _verify);
    }
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      if (_pin.isNotEmpty) _pin.removeLast();
    });
  }

  Future<void> _verify() async {
    final storage = LocalStorageService.instance;
    final correct = await storage.verifyPin(_pin.join());

    if (correct) {
      await storage.resetWrongPinCount();
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      context.pop();
    } else {
      HapticFeedback.heavyImpact();
      _attemptCount++;
      await storage.incrementWrongPinCount();

      final settings = storage.loadSettings();
      final threshold = settings.wrongPinThreshold;

      // Save break-in event
      await storage.addAlarmEvent(AlarmEvent.create(
        type: AlarmEventType.wrongPin,
        details: 'Incorrect PIN entered (attempt $_attemptCount)',
        failedAttempts: _attemptCount,
      ));

      if (_attemptCount >= threshold) {
        // Trigger intruder alarm
        await ref.read(protectionRepositoryProvider).triggerIntruderAlarm(_attemptCount);
        setState(() {
          _isError = true;
          _errorMsg = '🚨 INTRUDER DETECTED! Alarm triggered.';
          _pin = [];
        });
      } else {
        setState(() {
          _isError = true;
          _errorMsg = 'Incorrect PIN ($_attemptCount/$threshold attempts)';
          _pin = [];
        });
      }
      _shakeCtrl.forward(from: 0);
    }
  }

  String get _title {
    switch (widget.purpose) {
      case 'deactivate':
        return 'Enter PIN to Stop';
      case 'unlock':
        return 'Enter Security PIN';
      case 'settings':
        return 'Enter PIN to Access Settings';
      default:
        return 'Enter PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button bypass on alarm screen
      onWillPop: () async => widget.purpose != 'alarm',
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (widget.purpose != 'alarm')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      const Icon(Icons.lock_rounded, size: 60, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // PIN dots with shake
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (_, child) {
                    final shake = _shakeCtrl.isAnimating
                        ? ((_shakeCtrl.value * 4).round().isEven ? 8.0 : -8.0) *
                            (1 - _shakeCtrl.value)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: i < _pin.length
                              ? (_isError ? Colors.red : Colors.white)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isError ? Colors.red : Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isError)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const Spacer(),
                _Keypad(onDigit: _onDigit, onDelete: _onDelete),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reuse keypad from create_pin_screen style
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 16),
          _row(['4', '5', '6']),
          const SizedBox(height: 16),
          _row(['7', '8', '9']),
          const SizedBox(height: 16),
          _row(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) {
        if (d.isEmpty) return const SizedBox(width: 72, height: 72);
        if (d == '⌫') {
          return _Btn(
            onTap: onDelete,
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 24),
          );
        }
        return _Btn(
          onTap: () => onDigit(d),
          child: Text(
            d,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Btn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _Btn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
