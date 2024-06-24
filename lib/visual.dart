import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicVisualizer extends StatefulWidget {
  final Color color;
  final AudioPlayer audioPlayer;

  const MusicVisualizer({
    Key? key,
    required this.color,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  _MusicVisualizerState createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with SingleTickerProviderStateMixin {
  final List<double> _heights = List.filled(30, 0);
  late AnimationController _animationController;
  late StreamSubscription<double?> _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        setState(() {});
      });
    _animationController.repeat(reverse: true);
    _listenToAudioChanges();
  }

  void _listenToAudioChanges() {
    _volumeSubscription = widget.audioPlayer.volumeStream.listen((volume) {
      if (volume != null) {
        _updateHeights(volume);
      }
    });

    // Add a listener for the player state
    widget.audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.playing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    });
  }

  void _updateHeights(double volume) {
    for (int i = 0; i < _heights.length; i++) {
      _heights[i] = (volume * 50) + (math.Random().nextDouble() * 20);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _volumeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        _heights.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 3,
          height: _heights[index] * _animationController.value,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}
