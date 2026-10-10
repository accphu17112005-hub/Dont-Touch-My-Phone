import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/motion_service.dart';
import '../../core/services/alarm_engine.dart';
import '../../data/local/local_storage_service.dart';
import '../../models/app_models.dart';
import '../../models/alarm_event.dart';
import 'settings_repository.dart';

/// Central repository that orchestrates protection state
class ProtectionRepository {
  final MotionService _motionService;
  final AlarmEngine _alarmEngine;
  final LocalStorageService _storage;
  final SettingsRepository _settingsRepo;

  final _stateController = StreamController<ProtectionState>.broadcast();
  Stream<ProtectionState> get stateStream => _stateController.stream;

  ProtectionState _currentState = ProtectionState.inactive;
  ProtectionState get currentState => _currentState;

  StreamSubscription<double>? _motionSub;

  ProtectionRepository({
    required MotionService motionService,
    required AlarmEngine alarmEngine,
    required LocalStorageService storage,
    required SettingsRepository settingsRepo,
  })  : _motionService = motionService,
        _alarmEngine = alarmEngine,
        _storage = storage,
        _settingsRepo = settingsRepo;

  void _setState(ProtectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Begin the arming sequence
  Future<void> activateProtection({bool skipDelay = false}) async {
    if (_currentState != ProtectionState.inactive) return;

    final settings = _settingsRepo.currentSettings;

    _setState(skipDelay ? ProtectionState.protected : ProtectionState.arming);

    try {
      // Record event
      await _storage.addAlarmEvent(
        AlarmEvent.create(
          type: AlarmEventType.protectionActivated,
          details: 'Protection mode activated',
        ),
      );

      // Listen for motion detection
      _motionSub?.cancel();
      _motionSub = _motionService.onMotionDetected.listen((magnitude) {
        if (_currentState == ProtectionState.protected) {
          _handleMotionDetected(magnitude);
        }
      });

      // Start monitoring (includes arming delay internally unless skipped)
      await _motionService.startMonitoring(
        sensitivity: settings.motionSensitivity,
        delaySeconds: settings.alarmDelay,
        skipDelay: skipDelay,
      );

      if (_currentState == ProtectionState.arming) {
        _setState(ProtectionState.protected);
      }
    } catch (e) {
      _motionSub?.cancel();
      _motionService.stopMonitoring();
      _setState(ProtectionState.inactive);
      rethrow;
    }
  }

  void _handleMotionDetected(double magnitude) async {
    if (_currentState != ProtectionState.protected) return;
    _setState(ProtectionState.motionDetected);

    await _storage.addAlarmEvent(
      AlarmEvent.create(
        type: AlarmEventType.motionDetected,
        details: 'Movement detected (magnitude: ${magnitude.toStringAsFixed(2)})',
      ),
    );

    await _triggerAlarm();
  }

  Future<void> _triggerAlarm() async {
    _setState(ProtectionState.alarmActive);
    final settings = _settingsRepo.currentSettings;

    await _alarmEngine.startAlarm(
      soundId: settings.selectedSound,
      volume: settings.soundVolume,
      flashEnabled: settings.flashEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      flashMode: settings.flashMode,
      vibrationStrength: settings.vibrationStrength,
    );

    _setState(ProtectionState.pinRequired);
  }

  /// Called when user enters correct PIN
  Future<void> deactivateAlarm() async {
    _motionSub?.cancel();
    _motionService.stopMonitoring();
    await _alarmEngine.stopAlarm();

    await _storage.addAlarmEvent(
      AlarmEvent.create(
        type: AlarmEventType.protectionDeactivated,
        details: 'Protection deactivated by user',
      ),
    );

    _setState(ProtectionState.inactive);
  }

  /// Cancel during arming or force stop
  Future<void> cancelProtection() async {
    _motionSub?.cancel();
    _motionService.stopMonitoring();
    await _alarmEngine.stopAlarm();
    _setState(ProtectionState.inactive);
  }

  /// Trigger intruder alarm after wrong PIN threshold
  Future<void> triggerIntruderAlarm(int failedAttempts) async {
    await _storage.addAlarmEvent(
      AlarmEvent.create(
        type: AlarmEventType.intruderDetected,
        details: 'Intruder alert after $failedAttempts failed PIN attempts',
        failedAttempts: failedAttempts,
      ),
    );
    // Escalate — re-trigger alarm
    if (!_alarmEngine.isAlarmActive) {
      final settings = _settingsRepo.currentSettings;
      await _alarmEngine.startAlarm(
        soundId: settings.selectedSound,
        volume: 1.0, // Max volume for intruder
        flashEnabled: settings.flashEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        flashMode: 'fast',
        vibrationStrength: 'strong',
      );
    }
  }

  void dispose() {
    _motionSub?.cancel();
    _stateController.close();
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

final protectionRepositoryProvider = Provider<ProtectionRepository>((ref) {
  final motionService = ref.read(motionServiceProvider);
  final alarmEngine = ref.read(alarmEngineProvider);
  final storage = LocalStorageService.instance;
  final settingsRepo = ref.read(settingsRepositoryProvider);

  final repo = ProtectionRepository(
    motionService: motionService,
    alarmEngine: alarmEngine,
    storage: storage,
    settingsRepo: settingsRepo,
  );

  ref.onDispose(repo.dispose);
  return repo;
});

final motionServiceProvider = Provider<MotionService>((ref) {
  final svc = MotionService();
  ref.onDispose(svc.dispose);
  return svc;
});

final alarmEngineProvider = Provider<AlarmEngine>((ref) {
  final engine = AlarmEngine();
  engine.initialize();
  ref.onDispose(engine.dispose);
  return engine;
});

final protectionStateProvider = StreamProvider<ProtectionState>((ref) async* {
  final repo = ref.watch(protectionRepositoryProvider);
  yield repo.currentState;
  yield* repo.stateStream;
});
