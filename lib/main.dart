import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_storage_service.dart';
import 'data/repositories/settings_repository.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize persistent storage (Hive, SharedPreferences, SecureStorage)
  await LocalStorageService.init();

  runApp(
    const ProviderScope(
      child: DontTouchMyPhoneApp(),
    ),
  );
}

class DontTouchMyPhoneApp extends ConsumerWidget {
  const DontTouchMyPhoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      title: "Don't Touch My Phone",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
