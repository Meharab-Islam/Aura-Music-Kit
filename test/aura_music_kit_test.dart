import 'package:flutter_test/flutter_test.dart';
import 'package:aura_music_kit/aura_music_kit.dart';
import 'package:aura_music_kit/aura_music_kit_platform_interface.dart';
import 'package:aura_music_kit/aura_music_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAuraMusicKitPlatform
    with MockPlatformInterfaceMixin
    implements AuraMusicKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AuraMusicKitPlatform initialPlatform = AuraMusicKitPlatform.instance;

  test('$MethodChannelAuraMusicKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAuraMusicKit>());
  });

  test('getPlatformVersion', () async {
    MockAuraMusicKitPlatform fakePlatform = MockAuraMusicKitPlatform();
    AuraMusicKitPlatform.instance = fakePlatform;

    expect(await AuraMusicKit.getMusicFiles(), isA<List<Song>>());
  });
}
