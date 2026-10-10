import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.7, 1.0, curve: Curves.easeInOut)),
    );

    _ctrl.forward().then((_) => _ctrl.repeat(reverse: true));

    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final storage = LocalStorageService.instance;
    if (storage.isFirstRun) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated shield
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Transform.scale(
                    scale: _scaleAnim.value * _pulseAnim.value,
                    child: _ShieldIllustration(),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      const Text(
                        "Don't Touch",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        "My Phone",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Smart Phone Security",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: const _LoadingDots(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Shield icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.security_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          // Warning badge
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFF1744),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3 - i) % 3).clamp(0.0, 1.0);
            final opacity = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4 + opacity * 0.6),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
