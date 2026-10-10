import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      icon: Icons.phonelink_lock_rounded,
      title: "Don't Touch\nMy Phone",
      subtitle: "Protect your phone from\nunwanted movement and access.",
      bgColor1: Color(0xFF4A148C),
      bgColor2: Color(0xFF7B1FA2),
    ),
    _OnboardPage(
      icon: Icons.security_rounded,
      title: "Smart\nSecurity",
      subtitle: "Detect movement and suspicious\naccess attempts in real time.",
      bgColor1: Color(0xFF880E4F),
      bgColor2: Color(0xFFAD1457),
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      title: "Stay\nProtected",
      subtitle: "Activate protection before\nleaving your phone unattended.",
      bgColor1: Color(0xFFBF360C),
      bgColor2: Color(0xFFD84315),
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await LocalStorageService.instance.markNotFirstRun();
    if (!mounted) return;
    context.go('/create-pin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardPageView(page: _pages[i]),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A1B9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bgColor1;
  final Color bgColor2;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor1,
    required this.bgColor2,
  });
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;

  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [page.bgColor1, page.bgColor2],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration area
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(page.icon, size: 100, color: Colors.white),
              ),
              const SizedBox(height: 48),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
