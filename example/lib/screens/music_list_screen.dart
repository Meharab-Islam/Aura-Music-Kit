import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Import your plugin's main library file
import 'package:aura_music_kit/aura_music_kit.dart';

// Import the new player screen we will create
import 'player_screen.dart';

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String _statusText = 'Checking permissions...';
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    // FIX: Check the permission status first without requesting it.
    _checkPermissionStatus();
  }

  /// Checks the current permission status and updates the UI accordingly.
  Future<void> _checkPermissionStatus() async {
    final status = await _getPermission();
    setState(() {
      _permissionStatus = status;
    });

    if (status.isGranted) {
      _fetchMusic();
    } else {
      setState(() {
        _isLoading = false;
        _statusText = 'This app needs permission to access your music.';
      });
    }
  }

  /// Fetches music files after permission has been granted.
  Future<void> _fetchMusic() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusText = 'Loading music...';
    });
    
    final songs = await AuraMusicKit.getMusicFiles();

    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
        if (_songs.isEmpty) {
          _statusText = 'No music found on this device.\nPull down to refresh.';
        }
      });
    }
  }

  /// Gets the appropriate permission based on the platform and Android version.
  Future<PermissionStatus> _getPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.audio.status;
      } else {
        return await Permission.storage.status;
      }
    } else {
      return await Permission.mediaLibrary.status;
    }
  }
  
  /// Requests the appropriate permission when the user taps the button.
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

    setState(() {
      _permissionStatus = status;
    });

    if (status.isGranted) {
      _fetchMusic();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Music Kit'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionStatus == null || _isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusText),
          ],
        ),
      );
    }

    if (!_permissionStatus!.isGranted) {
      return _buildPermissionRequestView();
    }

    return RefreshIndicator(
      onRefresh: _fetchMusic,
      child: _songs.isEmpty ? _buildEmptyView() : _buildSongList(),
    );
  }

  /// The view shown when permission has not been granted.
  Widget _buildPermissionRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return ListView.builder(
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  songs: _songs,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
