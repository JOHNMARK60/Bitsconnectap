import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class ScanSoundService {
  ScanSoundService() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    unawaited(_player.setPlayerMode(PlayerMode.lowLatency));
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playCaptureSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/scan.mp3'));
    } catch (error) {
      debugPrint('Unable to play QR capture sound: $error');
    }
  }

  void dispose() {
    unawaited(_player.dispose());
  }
}
