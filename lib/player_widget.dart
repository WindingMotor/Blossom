import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({super.key});

  static String formatDuration(int durationInSeconds) {
    Duration duration = Duration(seconds: durationInSeconds);
    String twoDigitMinutes =
        (duration.inMinutes % 60).toString().padLeft(2, '0');
    String twoDigitSeconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  bool _isImageExpanded = false;
  bool _showVolumeSlider = false;

  void _toggleImageExpansion() {
    setState(() {
      _isImageExpanded = !_isImageExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<Player>(context);

    if (player.currentSong == null) {
      return const SizedBox.shrink();
    }

    final double max = player.duration.inSeconds.toDouble() > 0
        ? player.duration.inSeconds.toDouble()
        : 1.0;
    final double value =
        player.currentPosition.inSeconds.toDouble().clamp(0.0, max);

    return Stack(
      children: [
        Positioned.fill(
          child: Blur(
            blur: 15,
            blurColor: Colors.black,
            colorOpacity: 0.5,
            overlay: Container(color: Colors.black.withOpacity(0.3)),
            child: Image.memory(
              player.currentSong!.picture!.data,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleImageExpansion,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 5),
                      width: _isImageExpanded ? 100 : 45,
                      height: _isImageExpanded ? 100 : 45,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: MemoryImage(player.currentSong!.picture!.data),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.currentSong!.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          player.currentSong!.artist,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    tooltip: 'Previous',
                    onPressed: () => player.previousSong(),
                  ),
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    tooltip: player.isPlaying ? 'Pause' : 'Play',
                    onPressed: () => player.togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    tooltip: 'Next',
                    onPressed: () => player.nextSong(),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.shuffle_rounded, color: Colors.white),
                    tooltip: 'Shuffle Songs',
                    onPressed: () => player.shufflePlaylist(),
                  ),
                  IconButton(
                    icon: Icon(player.showPlayerBottomBar
                        ? Icons.expand_more
                        : Icons.expand_less),
                    tooltip: player.showPlayerBottomBar
                        ? 'Hide Progress Bar'
                        : 'Show Progress Bar',
                    onPressed: () => setState(() =>
                        player.globalShowPlayerBottomBar =
                            !player.globalShowPlayerBottomBar),
                  ),
                ],
              ),
              if (player.showPlayerBottomBar)
                Row(
                  children: [
                    Text(
                      PlayerWidget.formatDuration(player.duration.inSeconds),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Expanded(
                      child: Slider(
                        value: value,
                        activeColor: Colors.grey.shade200,
                        inactiveColor: Colors.black.withOpacity(0.2),
                        thumbColor: Colors.white,
                        min: 0,
                        max: max,
                        onChanged: (value) {
                          if (player.duration.inSeconds > 0) {
                            final position = Duration(seconds: value.round());
                            player.seek(position);
                          }
                        },
                      ),
                    ),
                    Text(
                      PlayerWidget.formatDuration(
                          player.currentPosition.inSeconds),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_showVolumeSlider)
                      Expanded(
                        child: Slider(
                          value: player.volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 50,
                          label: '${(player.volume * 100).round()}%',
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          onChanged: (newVolume) {
                            setState(() {
                              player.setVolume(newVolume);
                            });
                          },
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      tooltip: 'Adjust Volume',
                      onPressed: () => setState(
                          () => _showVolumeSlider = !_showVolumeSlider),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
