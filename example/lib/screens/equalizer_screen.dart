import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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