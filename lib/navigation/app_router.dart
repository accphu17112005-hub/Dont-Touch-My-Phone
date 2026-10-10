import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/local_storage_service.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/security/screens/security_dashboard_screen.dart';
import '../features/alarm_history/screens/alarm_history_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/motion_alarm/screens/motion_alarm_screen.dart';
import '../features/passcode/screens/create_pin_screen.dart';
import '../features/passcode/screens/verify_pin_screen.dart';
import '../features/alarm/screens/alarm_screen.dart';
import '../features/break_in/screens/break_in_screen.dart';
import '../features/airplane_alarm/screens/airplane_alarm_screen.dart';
import '../features/charging_alarm/screens/charging_alarm_screen.dart';
import '../features/settings/screens/alarm_sound_screen.dart';
import '../features/settings/screens/flash_vibration_screen.dart';
import '../widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/create-pin',
        builder: (ctx, state) => const CreatePinScreen(isInitialSetup: true),
      ),
      // Main shell with bottom nav
      ShellRoute(
        builder: (ctx, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (ctx, state) => const SecurityDashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (ctx, state) => const AlarmHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (ctx, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Feature screens
      GoRoute(
        path: '/motion-alarm',
        builder: (ctx, state) => const MotionAlarmScreen(),
      ),
      GoRoute(
        path: '/verify-pin',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyPinScreen(
            purpose: extra?['purpose'] ?? 'unlock',
            onSuccess: extra?['onSuccess'],
          );
        },
      ),
      GoRoute(
        path: '/alarm',
        builder: (ctx, state) => const AlarmScreen(),
      ),
      GoRoute(
        path: '/break-in',
        builder: (ctx, state) => const BreakInScreen(),
      ),
      GoRoute(
        path: '/airplane-alarm',
        builder: (ctx, state) => const AirplaneAlarmScreen(),
      ),
      GoRoute(
        path: '/charging-alarm',
        builder: (ctx, state) => const ChargingAlarmScreen(),
      ),
      GoRoute(
        path: '/alarm-sound',
        builder: (ctx, state) => const AlarmSoundScreen(),
      ),
      GoRoute(
        path: '/flash-vibration',
        builder: (ctx, state) => const FlashVibrationScreen(),
      ),
      GoRoute(
        path: '/change-pin',
        builder: (ctx, state) => const CreatePinScreen(isInitialSetup: false),
      ),
    ],
  );
});
