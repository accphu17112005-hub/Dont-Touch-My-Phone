import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/repositories/protection_repository.dart';
import '../models/app_models.dart';

/// Main scaffold wrapping all bottom-nav screens.
/// Listens globally for alarm state changes and navigates to /alarm.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global alarm navigation: when motion detected → navigate to alarm screen
    ref.listen<AsyncValue<ProtectionState>>(protectionStateProvider, (prev, next) {
      final prevState = prev?.valueOrNull;
      final nextState = next.valueOrNull;

      if (nextState == null) return;

      // Navigate when transitioning INTO alarmActive / pinRequired
      if (nextState == ProtectionState.alarmActive ||
          nextState == ProtectionState.pinRequired) {
        if (prevState != ProtectionState.alarmActive &&
            prevState != ProtectionState.pinRequired) {
          context.go('/alarm');
        }
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home', path: '/home'),
    _NavItem(icon: Icons.security_rounded, label: 'Security', path: '/security'),
    _NavItem(icon: Icons.history_rounded, label: 'History', path: '/history'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final selectedIdx = _items.indexWhere((i) => loc.startsWith(i.path));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 3,
                          ),
                          decoration: selected
                              ? BoxDecoration(
                                  color: const Color(0xFF6A1B9A).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                )
                              : null,
                          child: Icon(
                            item.icon,
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}
