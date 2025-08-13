import 'dart:io';

import 'package:aura_music_kit/aura_music_kit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Music Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MusicListScreen(), // Set your screen as the home
    );
  }
}


// this code for music_list_screen.dart

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


// this code for player_screen.dart


// Helper class is now simpler
class PositionData {
  final Duration position;
  final Duration duration;

  const PositionData(this.position, this.duration);
}

class PlayerScreen extends StatefulWidget {
  final List<Song> songs;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _equalizer = AndroidEqualizer();
  late AudioPlayer _audioPlayer;
  late int _currentIndex;

  // MODIFIED: Combine just position and duration streams
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (position, duration) => PositionData(
          position,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer],
      ),
    );

    _loadSong();

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _loadSong() async {
    final song = widget.songs[_currentIndex];
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(song.path!)));
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading song: $e");
    }
  }

  void _playNext() {
    if (_currentIndex < widget.songs.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadSong();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadSong();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.deepPurple.shade300,
        actions: [
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: SizedBox(
                width: 250,
                height: 250,
                child: currentSong.artwork != null
                    ? Image.memory(
                        currentSong.artwork!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.music_note, size: 120),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              currentSong.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.artist ?? "Unknown Artist",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            _buildProgressBar(),
            const SizedBox(height: 16),
            _buildControls(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (context, snapshot) {
        final positionData =
            snapshot.data ?? const PositionData(Duration.zero, Duration.zero);
        final position = positionData.position;
        final duration = positionData.duration;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              min: 0.0,
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, duration.inMilliseconds.toDouble()),
              // REMOVED: secondaryTrackValue property
              onChangeEnd: (value) {
                _audioPlayer.seek(Duration(milliseconds: value.round()));
              },
              onChanged: (value) {
                 // No action needed while dragging, but callback is required.
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 40,
          onPressed: _playPrevious,
        ),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: _audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final playing = playerState?.playing ?? false;
            return IconButton(
              icon: Icon(playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled),
              iconSize: 64,
              onPressed: () {
                if (playing) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
            );
          },
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 40,
          onPressed: _playNext,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// this code for equalizer_screen.dart


class EqualizerScreen extends StatefulWidget {
  // We require the AndroidEqualizer instance directly
  final AndroidEqualizer equalizer;

  const EqualizerScreen({
    super.key,
    required this.equalizer,
  });

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late bool _isEqualizerEnabled;

  @override
  void initState() {
    super.initState();
    // Initialize the equalizer state
    _isEqualizerEnabled = widget.equalizer.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Equalizer'),
              value: _isEqualizerEnabled,
              onChanged: (value) {
                setState(() {
                  _isEqualizerEnabled = value;
                  widget.equalizer.setEnabled(value);
                });
              },
            ),
            const Divider(),
            Expanded(
              // Use a FutureBuilder to get the full parameters object
              child: FutureBuilder<AndroidEqualizerParameters>(
                // Get the whole 'parameters' object, not just the bands
                future: widget.equalizer.parameters,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error loading equalizer bands.'));
                  }
                  
                  // -- THIS IS THE FIX --
                  // Get the parameters from the snapshot
                  final parameters = snapshot.data!;
                  // Get the min and max decibel levels for the sliders
                  final minDb = parameters.minDecibels;
                  final maxDb = parameters.maxDecibels;
                  // Get the list of bands
                  final bands = parameters.bands;
                  // -- END OF FIX --

                  return ListView.builder(
                    itemCount: bands.length,
                    itemBuilder: (context, index) {
                      final band = bands[index];
                      return Column(
                        children: [
                          Text(
                            '${band.centerFrequency.round()} Hz',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          StreamBuilder<double>(
                            stream: band.gainStream,
                            builder: (context, snapshot) {
                              return Slider(
                                // Use the min and max values from the parameters
                                min: minDb,
                                max: maxDb,
                                value: snapshot.data ?? band.gain,
                                onChanged: !_isEqualizerEnabled
                                    ? null
                                    : (value) {
                                        band.setGain(value);
                                      },
                              );
                            },
                          ),
                          StreamBuilder<double>(
                              stream: band.gainStream,
                              builder: (context, snapshot) {
                                return Text(
                                    '${(snapshot.data ?? band.gain).toStringAsFixed(2)} dB');
                              }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
