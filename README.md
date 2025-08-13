# Aura Music Kit

[![pub version](https://img.shields.io/pub/v/aura_music_kit?color=5c3c8b&style=for-the-badge)](https://pub.dev/packages/aura_music_kit)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](/LICENSE)
![platforms](https://img.shields.io/badge/platforms-android%20%7C%20ios-lightgrey.svg?style=for-the-badge)

A powerful and easy-to-use Flutter plugin for accessing local audio files on a user's device. Aura Music Kit simplifies fetching songs, retrieving metadata, and handling platform-specific permissions, making it the perfect starting point for your music player app.



---

## ✨ Features

- ✅ **Fetch All Songs**: Query all audio files from the device's media library.
- 🖼️ **Album Artwork**: Retrieve embedded album artwork for each song.
- 🎵 **Rich Metadata**: Access essential song details including title, artist, album, duration, and file path.
- 🔒 **Simplified Permissions**: Handles the complexity of requesting storage/media permissions on both Android and iOS.
- 📱 **Platform-Specific Logic**: Automatically uses the correct permissions for various Android API levels (`READ_EXTERNAL_STORAGE` for older versions and `READ_MEDIA_AUDIO` for Android 13+).

---

## ⚙️ Platform Configuration

Before you begin, add the required permissions to your project's native configuration files.

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml` file.

```xml
<!-- For Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- For Android 13 and above -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### iOS

Add the `NSAppleMusicUsageDescription` key to your `ios/Runner/Info.plist` file. This is required by Apple to explain why your app needs access to the user's media library.

```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to play songs.</string>
```

---

## 🚀 Getting Started

### 1. Installation

Add `aura_music_kit` to your `pubspec.yaml` file. It's also recommended to include `permission_handler` and `device_info_plus` for a complete setup.

```yaml
dependencies:
  flutter:
    sdk: flutter
  aura_music_kit: ^1.0.0 # Use the latest version
  permission_handler: ^11.0.0 # Recommended for handling permissions
  device_info_plus: ^9.0.0 # Recommended for checking device info
  just_audio: ^0.9.36 # Recommended for audio playback and effects
```

Then, run `flutter pub get` in your terminal to install the packages.

### 2. Import the necessary packages

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:aura_music_kit/aura_music_kit.dart';
```

---

## 📋 How to Use

Here’s a step-by-step guide to using Aura Music Kit in your Flutter application.

### Step 1: Check and Request Permissions

Before fetching music, you must have the user's permission. The required permission varies by platform and Android SDK version.

```dart
/// Gets the appropriate permission status.
Future<PermissionStatus> _getPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    // For Android 13 (SDK 33) and above, use READ_MEDIA_AUDIO
    if (androidInfo.version.sdkInt >= 33) {
      return Permission.audio.status;
    } else {
      // For older versions, use READ_EXTERNAL_STORAGE
      return Permission.storage.status;
    }
  } else {
    // For iOS, use mediaLibrary
    return Permission.mediaLibrary.status;
  }
}

/// Requests the appropriate permission from the user.
Future<void> _requestPermission() async {
  PermissionStatus status;
   if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      status = await Permission.audio.request();
    } else {
      status = await Permission.storage.request();
    }
  } else {
    status = await Permission.mediaLibrary.request();
  }

  // Handle the permission response
  if (status.isGranted) {
    // Permission granted, you can now fetch music
    _fetchMusic();
  } else {
    // Permission denied
    // You might want to show a dialog to the user
  }
}
```

### Step 2: Fetch Music Files

Once permission is granted, call `AuraMusicKit.getMusicFiles()` to get a list of all songs on the device.

```dart
List<Song> _songs = [];
bool _isLoading = true;

Future<void> _fetchMusic() async {
  // Ensure permission is granted before fetching
  final status = await _getPermission();
  if (!status.isGranted) {
    print('Permission not granted.');
    return;
  }

  // Fetch the list of songs
  final fetchedSongs = await AuraMusicKit.getMusicFiles();

  setState(() {
    _songs = fetchedSongs;
    _isLoading = false;
  });
}
```

### Step 3: Display the Music List

You can display the fetched songs in a `ListView`. The `Song` object contains the artwork as a `Uint8List`, which can be displayed using `Image.memory`.

```dart
ListView.builder(
  itemCount: _songs.length,
  itemBuilder: (context, index) {
    final song = _songs[index];
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          width: 50,
          height: 50,
          child: song.artwork != null
              ? Image.memory(
                  song.artwork!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.music_note, size: 30),
                )
              : const Icon(Icons.music_note, size: 30),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.artist ?? "Unknown Artist",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        // Navigate to your player screen
        // Example: Navigator.push(context, MaterialPageRoute(...));
      },
    );
  },
);
```


---

## 🎛️ Advanced Usage: Adding an Equalizer

While `aura_music_kit` fetches your music, you'll need a playback library like `just_audio` to play songs and apply effects like an equalizer.

### Step 1: Set up the Audio Player with an Equalizer

In your player screen's state, create instances of `AudioPlayer` and `AndroidEqualizer`.

```dart
class PlayerScreen extends StatefulWidget {
  // ...
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _equalizer = AndroidEqualizer();
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer],
      ),
    );
    // ... load song etc.
  }
  // ...
}
```

### Step 2: Create an Equalizer Control UI

On your player screen, add a button that navigates to a new screen for equalizer controls. Pass the `_equalizer` instance to it.

**Player Screen:**
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
),
```

**Equalizer Screen:**
This new screen will contain the sliders to control the equalizer bands.

```dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class EqualizerScreen extends StatefulWidget {
  final AndroidEqualizer equalizer;

  const EqualizerScreen({super.key, required this.equalizer});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late bool _isEnabled;

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
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
                widget.equalizer.setEnabled(value);
              });
            },
          ),
          Expanded(
            child: FutureBuilder<AndroidEqualizerParameters>(
              future: widget.equalizer.parameters,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final params = snapshot.data!;
                return ListView.builder(
                  itemCount: params.bands.length,
                  itemBuilder: (context, index) {
                    final band = params.bands[index];
                    return Column(
                      children: [
                        Text('${band.centerFrequency.round()} Hz'),
                        StreamBuilder<double>(
                          stream: band.gainStream,
                          builder: (context, snapshot) {
                            return Slider(
                              min: params.minDecibels,
                              max: params.maxDecibels,
                              value: snapshot.data ?? band.gain,
                              onChanged: !_isEnabled ? null : (v) => band.setGain(v),
                            );
                          },
                        ),
                      ],
                    );
                  },
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

## 📚 API Reference

### `AuraMusicKit`

| Method              | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `getMusicFiles()`   | Asynchronously fetches a list of all audio files from the device. Returns a `Future<List<Song>>`. |

### `Song` Class

A data class representing a single audio file with the following properties:

| Property   | Type         | Description                                     |
| :--------- | :----------- | :---------------------------------------------- |
| `title`    | `String`     | The title of the song.                          |
| `artist`   | `String?`    | The artist of the song. Can be null.            |
| `album`    | `String?`    | The album the song belongs to. Can be null.     |
| `data`     | `String`     | The absolute file path to the audio file.       |
| `artwork`  | `Uint8List?` | The embedded album artwork as a byte list.      |
| `duration` | `int?`       | The duration of the song in milliseconds.       |

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on our [GitHub repository](https://github.com/your-username/aura_music_kit). If you would like to contribute code, please fork the repository and submit a pull request.

## 📄 License

This package is licensed under the MIT License. See the `LICENSE` file for more details.

---

> This video provides a great overview of creating a complete [Flutter Music App](https://www.youtube.com/watch?v=LMBNDKxXuDU), which is relevant to anyone using this package.
