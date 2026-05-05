import 'package:audioplayers/audioplayers.dart';

/// In-app looped siren — fires once user has visible UI (after
/// answering the CallKit call on iOS, or tapping the alarm
/// notification on Android). Independent of the per-platform
/// ringing layer, so it keeps the user engaged with the alert
/// even after the OS-level ringtone fades.
class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  final _player = AudioPlayer();
  bool _playing = false;

  Future<void> startSiren() async {
    if (_playing) return;
    _playing = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource('sounds/siren.mp3'));
  }

  Future<void> stop() async {
    _playing = false;
    await _player.stop();
  }
}
