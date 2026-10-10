import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../data/repositories/settings_repository.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const CreatePinScreen({super.key, required this.isInitialSetup});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen>
    with SingleTickerProviderStateMixin {
  final int _pinLength = 4;
  List<String> _pin = [];
  List<String> _confirmPin = [];
  bool _isConfirming = false;
  bool _isError = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  List<String> get _currentPin => _isConfirming ? _confirmPin : _pin;

  void _onDigit(String digit) {
    if (_currentPin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      if (_isConfirming) {
        _confirmPin.add(digit);
      } else {
        _pin.add(digit);
      }
    });

    if (_currentPin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isConfirming) {
          _verify();
        } else {
          setState(() => _isConfirming = true);
        }
      });
    }
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin.removeLast();
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin.removeLast();
      }
    });
  }

  Future<void> _verify() async {
    if (_pin.join() == _confirmPin.join()) {
      await LocalStorageService.instance.savePin(_pin.join());
      await ref.read(settingsNotifierProvider.notifier).setPinEnabled(true);

      if (!mounted) return;
      if (widget.isInitialSetup) {
        context.go('/home');
      } else {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN updated successfully')),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _confirmPin = [];
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    if (!widget.isInitialSetup)
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _isConfirming ? 'Confirm Security PIN' : 'Create Security PIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isConfirming
                                ? 'Re-enter your PIN to confirm'
                                : 'Enter a $_pinLength-digit PIN',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isInitialSetup) const SizedBox(width: 48),
                  ],
                ),
              ),

              const Spacer(),

              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
              ),

              const SizedBox(height: 40),

              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeCtrl.isAnimating
                          ? (_shakeCtrl.value < 0.5 ? _shakeAnim.value : -_shakeAnim.value)
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _currentPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: filled
                            ? (_isError ? Colors.red : Colors.white)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isError
                              ? Colors.red
                              : Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_isError) ...[
                const SizedBox(height: 16),
                const Text(
                  "PINs don't match. Try again.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ],

              const Spacer(),

              // Keypad
              _Keypad(onDigit: _onDigit, onDelete: _onDelete),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

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
          _KeypadRow(digits: ['1', '2', '3'], onDigit: onDigit, onDelete: null),
          const SizedBox(height: 16),
          _KeypadRow(digits: ['4', '5', '6'], onDigit: onDigit, onDelete: null),
          const SizedBox(height: 16),
          _KeypadRow(digits: ['7', '8', '9'], onDigit: onDigit, onDelete: null),
          const SizedBox(height: 16),
          _KeypadRow(digits: ['', '0', '⌫'], onDigit: onDigit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _KeypadRow extends StatelessWidget {
  final List<String> digits;
  final ValueChanged<String> onDigit;
  final VoidCallback? onDelete;

  const _KeypadRow({
    required this.digits,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) {
        if (d.isEmpty) return const SizedBox(width: 72, height: 72);
        if (d == '⌫') {
          return _KeyButton(
            onTap: onDelete ?? () {},
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 24),
          );
        }
        return _KeyButton(
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

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeyButton({required this.onTap, required this.child});

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
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
