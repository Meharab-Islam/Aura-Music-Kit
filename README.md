Got it — you basically want this `Aura Music Kit` README rewritten so it’s cleaner, more professional, and consistent in formatting while keeping all the functionality intact.
I can reorganize the sections, improve clarity, and make the examples more concise while keeping them complete.

Here’s the polished and professional rewrite:

---

# Aura Music Kit

[![Pub Version](https://img.shields.io/pub/v/aura_music_kit?color=5c3c8b\&style=for-the-badge)](https://pub.dev/packages/aura_music_kit)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](/LICENSE)
![Platforms](https://img.shields.io/badge/platforms-android%20%7C%20ios-lightgrey.svg?style=for-the-badge)

A powerful Flutter plugin for accessing local audio files, retrieving metadata, and handling platform-specific permissions.
Perfect for building music player apps without the hassle of writing native code.

---

## ✨ Features

* **Fetch All Songs** — Query audio files from the device’s media library.
* **Album Artwork** — Retrieve embedded album covers for each track.
* **Rich Metadata** — Title, artist, album, duration, file path, and more.
* **Permission Handling** — Automatically requests the right permissions for Android/iOS.
* **API-Level Awareness** — Uses `READ_MEDIA_AUDIO` for Android 13+, `READ_EXTERNAL_STORAGE` for older devices.

---

## ⚙️ Platform Setup

### **Android**

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### **iOS**

Add the `NSAppleMusicUsageDescription` key to `ios/Runner/Info.plist`:

```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to play songs.</string>
```

---

## 🚀 Installation

Add dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  aura_music_kit: ^1.0.0
  permission_handler: ^11.0.0
  device_info_plus: ^9.0.0
  just_audio: ^0.9.36
```

Run:

```bash
flutter pub get
```

Import:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:aura_music_kit/aura_music_kit.dart';
```

---

## 📋 Usage

### **1. Handle Permissions**

```dart
Future<PermissionStatus> _getPermission() async {
  if (Platform.isAndroid) {
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    return sdkInt >= 33 ? Permission.audio.status : Permission.storage.status;
  }
  return Permission.mediaLibrary.status;
}

Future<void> _requestPermission() async {
  PermissionStatus status;
  if (Platform.isAndroid) {
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    status = sdkInt >= 33
        ? await Permission.audio.request()
        : await Permission.storage.request();
  } else {
    status = await Permission.mediaLibrary.request();
  }

  if (status.isGranted) {
    _fetchMusic();
  } else {
    // Handle denial
  }
}
```

### **2. Fetch Music Files**

```dart
List<Song> _songs = [];
bool _isLoading = true;

Future<void> _fetchMusic() async {
  if (!(await _getPermission()).isGranted) return;
  final fetchedSongs = await AuraMusicKit.getMusicFiles();
  setState(() {
    _songs = fetchedSongs;
    _isLoading = false;
  });
}
```

### **3. Display Song List**

```dart
ListView.builder(
  itemCount: _songs.length,
  itemBuilder: (context, index) {
    final song = _songs[index];
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 50,
          height: 50,
          child: song.artwork != null
              ? Image.memory(song.artwork!, fit: BoxFit.cover)
              : const Icon(Icons.music_note, size: 30),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist ?? "Unknown Artist",
          maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        // Navigate to player
      },
    );
  },
);
```

---

## 🎛 Equalizer Integration (Android)

### **Player Setup**

```dart
final _equalizer = AndroidEqualizer();
late AudioPlayer _audioPlayer;

@override
void initState() {
  super.initState();
  _audioPlayer = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
  );
}
```

### **Equalizer UI**

```dart
IconButton(
  icon: const Icon(Icons.equalizer),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EqualizerScreen(equalizer: _equalizer),
      ),
    );
  },
);
```

**EqualizerScreen:**

```dart
class EqualizerScreen extends StatefulWidget {
  final AndroidEqualizer equalizer;
  const EqualizerScreen({super.key, required this.equalizer});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.equalizer.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Equalizer'),
            value: _isEnabled,
            onChanged: (v) {
              setState(() {
                _isEnabled = v;
                widget.equalizer.setEnabled(v);
              });
            },
          ),
          Expanded(
            child: FutureBuilder<AndroidEqualizerParameters>(
              future: widget.equalizer.parameters,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final params = snapshot.data!;
                return ListView(
                  children: params.bands.map((band) {
                    return Column(
                      children: [
                        Text('${band.centerFrequency.round()} Hz'),
                        StreamBuilder<double>(
                          stream: band.gainStream,
                          builder: (context, snap) {
                            return Slider(
                              min: params.minDecibels,
                              max: params.maxDecibels,
                              value: snap.data ?? band.gain,
                              onChanged: !_isEnabled
                                  ? null
                                  : (v) => band.setGain(v),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📚 API

### `AuraMusicKit`

| Method            | Description                                       |
| ----------------- | ------------------------------------------------- |
| `getMusicFiles()` | Fetches a list of `Song` objects from the device. |

### `Song`

| Property   | Type         | Description   |
| ---------- | ------------ | ------------- |
| `title`    | `String`     | Song title    |
| `artist`   | `String?`    | Song artist   |
| `album`    | `String?`    | Album name    |
| `data`     | `String`     | File path     |
| `artwork`  | `Uint8List?` | Album cover   |
| `duration` | `int?`       | Duration (ms) |

---

## 🤝 Contributing

Found a bug? Want to add a feature?
Open an issue or submit a PR on [GitHub](https://github.com/Meharab-Islam/Aura-Music-Kit.git).

---

## 📄 License

Licensed under the [MIT License](LICENSE).

---

