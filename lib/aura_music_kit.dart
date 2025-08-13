import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A data class representing a single song from the device's media library.
@immutable
class Song {
  /// A unique identifier for the song. On Android, this is the MediaStore ID.
  final int id;
  /// The file path to the audio file.
  final String? path;
  /// The title of the song.
  final String title;
  /// The name of the artist.
  final String? artist;
  /// The duration of the song in milliseconds.
  final int duration;
  /// Raw byte data for the album artwork. Can be used with `Image.memory`.
  final Uint8List? artwork;

  const Song({
    required this.id,
    this.path,
    required this.title,
    this.artist,
    required this.duration,
    this.artwork,
  });

  /// Creates a Song instance from a map (typically from the native platform).
  factory Song.fromMap(Map<dynamic, dynamic> map) {
    return Song(
      id: map['id'] as int,
      path: map['path'] as String?,
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String?,
      duration: map['duration'] as int,
      artwork: map['artwork'] as Uint8List?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Song(id: $id, title: "$title", artist: "$artist")';
  }
}

/// A class to interact with native music querying and audio effects.
class AuraMusicKit {
  static const MethodChannel _channel = MethodChannel('com.example.aura_music_kit/channel');

  /// Fetches all music files from the device's media library.
  ///
  /// This requires the appropriate storage/media permissions to be granted by the user.
  /// Returns a list of [Song] objects.
  static Future<List<Song>> getMusicFiles() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getMusicFiles');
      return result.map((map) => Song.fromMap(map)).toList();
    } on PlatformException catch (e) {
      debugPrint("AuraMusicKit Error: Failed to get music files: '${e.message}'.");
      return [];
    }
  }

  // --- Equalizer Methods (Android Only) ---

  /// Initializes the Equalizer for a given audio session ID.
  /// **NOTE: This method is for Android only.** It will return `false` on iOS.
  static Future<bool> initEqualizer(int audioSessionId) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('initEqualizer', {'audioSessionId': audioSessionId}) ?? false;
    } on PlatformException catch (e) {
      debugPrint("AuraMusicKit Error: Failed to init equalizer: '${e.message}'.");
      return false;
    }
  }

  /// Retrieves the current equalizer settings.
  /// **NOTE: This method is for Android only.** Returns `null` on iOS.
  static Future<Map<String, dynamic>?> getEqualizerSettings() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getEqualizerSettings');
      return result;
    } on PlatformException catch (e) {
      debugPrint("AuraMusicKit Error: Failed to get equalizer settings: '${e.message}'.");
      return null;
    }
  }

  /// Sets the gain for a specific equalizer band.
  /// **NOTE: This method is for Android only.**
  static Future<void> setBandLevel(int band, int level) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setBandLevel', {'band': band, 'level': level});
    } on PlatformException catch (e) {
      debugPrint("AuraMusicKit Error: Failed to set band level: '${e.message}'.");
    }
  }
}
