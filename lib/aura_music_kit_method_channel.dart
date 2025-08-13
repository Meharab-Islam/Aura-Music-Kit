import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aura_music_kit_platform_interface.dart';

/// An implementation of [AuraMusicKitPlatform] that uses method channels.
class MethodChannelAuraMusicKit extends AuraMusicKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aura_music_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
