import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioPlayer player = AudioPlayer();

  /// Currently playing audio URL
  static final ValueNotifier<String?> currentlyPlayingUrlNotifier =
      ValueNotifier(null);

  /// Currently playing track (full object)
  static final ValueNotifier<Map<String, dynamic>?> currentTrackNotifier =
      ValueNotifier(null);

  /// Play or pause a track
  static Future<void> playOrPause(
    String url,
    Map<String, dynamic> track,
  ) async {
    // Same track → toggle
    if (currentlyPlayingUrlNotifier.value == url) {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
      return;
    }

    // New track
    await player.setUrl(url);
    await player.play();

    currentlyPlayingUrlNotifier.value = url;
    currentTrackNotifier.value = track;
  }

  /// Is this track currently playing?
  static bool isPlaying(String? url) {
    return player.playing && currentlyPlayingUrlNotifier.value == url;
  }
}
