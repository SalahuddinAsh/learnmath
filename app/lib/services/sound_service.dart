import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'settings_controller.dart';

/// Plays the short tones in assets/sounds, pre-rendered from app.js's WebAudio
/// beeps (same frequencies and decay). A fresh player per sound lets a timer
/// tick overlap a feedback beep, like the independent oscillators on the web.
class SoundService {
  final SettingsController settings;
  SoundService(this.settings);

  void _play(String file) {
    if (!settings.settings.sound) return;
    try {
      final player = AudioPlayer();
      unawaited(player.setReleaseMode(ReleaseMode.release).catchError((_) {}));
      unawaited(player.play(AssetSource("sounds/$file")).catchError((_) {}));
      player.onPlayerComplete.listen((_) => unawaited(player.dispose().catchError((_) {})), onError: (_) {});
    } catch (_) {}
  }

  void good() => _play("good.wav");
  void bad() => _play("bad.wav");
  void tick() => _play("tick.wav");
  void partial() => _play("partial.wav");
  void zap() => _play("zap.wav");
}
