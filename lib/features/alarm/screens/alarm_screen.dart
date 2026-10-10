import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/protection_repository.dart';
import '../../../data/local/local_storage_service.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  List<String> _pin = [];
  bool _isError = false;
  bool _showKeypad = false;
  int _wrongAttempts = 0;
  bool _hasPin = true;

  @override
  void initState() {
    super.initState();
    LocalStorageService.instance.hasPin().then((v) {
      if (mounted) setState(() => _hasPin = v);
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _isError = false;
      _pin.add(d);
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _verify);
    }
  }

  void _onDelete() {
    setState(() {
      _isError = false;
      if (_pin.isNotEmpty) _pin.removeLast();
    });
  }

  Future<void> _verify() async {
    final storage = LocalStorageService.instance;
    final hasPin = await storage.hasPin();

    if (!hasPin) {
      // No PIN set — allow stopping
      await ref.read(protectionRepositoryProvider).deactivateAlarm();
      if (!mounted) return;
      context.go('/home');
      return;
    }

    final correct = await storage.verifyPin(_pin.join());
    if (correct) {
      await storage.resetWrongPinCount();
      await ref.read(protectionRepositoryProvider).deactivateAlarm();
      if (!mounted) return;
      context.go('/home');
    } else {
      _wrongAttempts++;
      await storage.incrementWrongPinCount();
      setState(() {
        _isError = true;
        _pin = [];
      });

      final settings = storage.loadSettings();
      if (_wrongAttempts >= settings.wrongPinThreshold) {
        await ref.read(protectionRepositoryProvider).triggerIntruderAlarm(_wrongAttempts);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Cannot go back without PIN
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7B1FA2), Color(0xFFB71C1C)],
            ),
          ),
          child: SafeArea(
            child: _showKeypad ? _buildKeypad() : _buildAlarmDisplay(),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmDisplay() {
    return Column(
      children: [
        const Spacer(),
        // Pulsing warning icon
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) {
            return Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        const Text(
          'PHONE MOVED!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Someone may be touching your phone.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_hasPin) {
                  setState(() => _showKeypad = true);
                } else {
                  await ref.read(protectionRepositoryProvider).deactivateAlarm();
                  if (mounted) context.go('/home');
                }
              },
              icon: Icon(_hasPin ? Icons.lock_open_rounded : Icons.stop_circle_rounded),
              label: Text(
                _hasPin ? 'ENTER PIN TO STOP' : 'STOP ALARM',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock_rounded, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Enter PIN to stop alarm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
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
        if (_isError) ...[
          const SizedBox(height: 12),
          Text(
            'Incorrect PIN. Attempts: $_wrongAttempts',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
        const Spacer(),
        _buildKeypadButtons(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildKeypadButtons() {
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
            onTap: _onDelete,
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 24),
          );
        }
        return _Btn(
          onTap: () => _onDigit(d),
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
