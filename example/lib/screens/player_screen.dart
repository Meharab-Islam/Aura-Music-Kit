import 'package:aura_music_kit/aura_music_kit.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart'; // rxdart is still useful here

// Import the equalizer screen
import 'equalizer_screen.dart';

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