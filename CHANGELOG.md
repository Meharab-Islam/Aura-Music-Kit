# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-08-13
### Added
- Initial release of **Aura Music Kit**.
- Support for fetching all local audio files from Android and iOS devices.
- Automatic handling of platform-specific permissions:
  - `READ_MEDIA_AUDIO` for Android 13+.
  - `READ_EXTERNAL_STORAGE` for Android 12 and below.
  - `NSAppleMusicUsageDescription` for iOS.
- Ability to retrieve:
  - Song title, artist, album, duration, and file path.
  - Embedded album artwork (`Uint8List`).
- Example usage for:
  - Permission handling.
  - Song fetching.
  - Displaying songs in a `ListView`.
- Basic **Equalizer** integration with `just_audio`:
  - Enable/disable equalizer.
  - Adjust gain for each frequency band.

---

## [0.0.1] - 2025-08-10
### Added
- Project scaffold and package structure.
- Android and iOS platform channels.
- Basic permission handling setup.
