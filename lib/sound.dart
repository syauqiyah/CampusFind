import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

final _player = AudioPlayer();

/// Bunyi + getar saat ada notifikasi baru.
Future<void> playAlert() async {
  try {
    HapticFeedback.heavyImpact();
    await _player.stop();
    await _player.play(AssetSource('notif.wav'));
  } catch (_) {}
}
