import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioPlayerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AudioPlayerPage extends StatefulWidget {
  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Listen to audio duration changes
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        duration = d;
      });
    });

    // Listen to audio position changes
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        position = p;
      });
    });

    // When audio completes, reset states
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  Future<void> _play() async {
    await _audioPlayer.play(AssetSource('audio/audio_message.aac'));
    setState(() {
      isPlaying = true;
    });
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      position = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSliderValue = duration.inMilliseconds.toDouble();
    final currentSliderValue = position.inMilliseconds.toDouble();

    return Scaffold(
      appBar: AppBar(title: Text('WhatsApp Style Audio Player')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow, size: 40, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sample Audio1',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_formatDuration(duration)),
              ],
            ),
            SizedBox(height: 20),
            Slider(
              min: 0,
              max: maxSliderValue > 0 ? maxSliderValue : 1,
              value: currentSliderValue.clamp(0, maxSliderValue),
              onChanged: (value) async {
                final seekPosition = Duration(milliseconds: value.toInt());
                await _audioPlayer.seek(seekPosition);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Row(
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                      color: Colors.green,
                      onPressed: () {
                        if (isPlaying) {
                          _pause();
                        } else {
                          _play();
                        }
                      },
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: Icon(Icons.stop_circle_outlined),
                      color: Colors.red,
                      onPressed: _stop,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}