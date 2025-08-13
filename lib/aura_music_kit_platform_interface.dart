import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'aura_music_kit_method_channel.dart';

abstract class AuraMusicKitPlatform extends PlatformInterface {
  /// Constructs a AuraMusicKitPlatform.
  AuraMusicKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static AuraMusicKitPlatform _instance = MethodChannelAuraMusicKit();

  /// The default instance of [AuraMusicKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelAuraMusicKit].
  static AuraMusicKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AuraMusicKitPlatform] when
  /// they register themselves.
  static set instance(AuraMusicKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
