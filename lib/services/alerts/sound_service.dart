import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../settings/settings_service.dart';

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _stopTimer;

  Future<void> init() async {
    // Preload sounds if needed
  }

  Future<void> playAlert() async {
    final soundId =
        SettingsService.instance.settings.soundSettings.selectedAlertSoundId;
    await _stopAndPlay('sounds/alert_$soundId.wav', intensive: false);
  }

  Future<void> previewAlertSound(String soundId) async {
    await _stopAndPlay('sounds/alert_$soundId.wav', intensive: false);
  }

  Future<void> playCritical() async {
    final settings = SettingsService.instance.settings.soundSettings;
    if (!settings.criticalAlarmEnabled) return;

    final soundId = settings.selectedCriticalSoundId;
    final assetPath = soundId == 'lion_roar'
        ? 'sounds/lion_roar.wav'
        : 'sounds/critical_$soundId.wav';
    await _stopAndPlay(assetPath, intensive: false);
  }

  Future<void> previewCriticalSound(String soundId) async {
    final assetPath = soundId == 'lion_roar'
        ? 'sounds/lion_roar.wav'
        : 'sounds/critical_$soundId.wav';
    await _stopAndPlay(assetPath, intensive: false);
  }

  Future<void> playPanic() async {
    final settings = SettingsService.instance.settings.soundSettings;
    if (!settings.panicAlarmEnabled) return;

    final soundId = settings.selectedPanicSoundId;
    final assetPath =
        soundId == 'lion_roar' ? 'sounds/lion_roar.wav' : 'sounds/$soundId.wav';
    await _stopAndPlay(assetPath, intensive: true);
  }

  Future<void> previewPanicSound(String soundId) async {
    final assetPath =
        soundId == 'lion_roar' ? 'sounds/lion_roar.wav' : 'sounds/$soundId.wav';
    await _stopAndPlay(assetPath, intensive: true);
  }

  Future<void> _stopAndPlay(
    String assetPath, {
    int duration = 30000,
    bool intensive = false,
  }) async {
    try {
      // 1. Cancel everything first to ensure immediate stop of previous action
      _stopTimer?.cancel();
      await _player.stop();
      await Vibration.cancel();

      final settings = SettingsService.instance.settings.soundSettings;
      final soundOn = settings.soundEnabled;
      final vibeOn = settings.vibrationEnabled;

      // 2. If neither sound nor vibration is enabled, we are done
      if (!soundOn && !vibeOn) return;

      // 3. Start audio if enabled
      if (soundOn) {
        await _player.play(AssetSource(assetPath));
      }

      // 4. Start vibration if enabled
      if (vibeOn) {
        await _startVibration(intensive: intensive);
      }

      // 5. Timer stops both after duration
      _stopTimer = Timer(Duration(milliseconds: duration), () {
        _player.stop();
        Vibration.cancel();
      });
    } catch (e) {
      debugPrint('Error in sound/vibration action ($assetPath): $e');
    }
  }

  Future<void> _startVibration({required bool intensive}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (intensive) {
          Vibration.vibrate(
            pattern: [0, 500, 200, 500],
            intensities: [0, 255, 0, 255],
            repeat: 0,
          );
        } else {
          Vibration.vibrate(pattern: [0, 1000, 500], repeat: 0);
        }
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> stopAll() async {
    try {
      _stopTimer?.cancel();
      _stopTimer = null;
      await _player.stop();
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Error stopping sound/vibration: $e');
    }
  }

  Future<void> stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Error stopping vibration: $e');
    }
  }
}
