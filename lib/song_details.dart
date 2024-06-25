import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:blossom/metadata.dart';
import 'package:blossom/player_widget.dart';

class SongDetailsPage extends StatelessWidget {
  final Song song;

  const SongDetailsPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          const Icon(Icons.graphic_eq_rounded),
          const SizedBox(width: 8),
          Text(
            'Details for ${song.title}',
            overflow: TextOverflow.ellipsis,
          ),
        ],
      )),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.memory(
                  song.picture!.data,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.6),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            song.picture!.data,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Theme.of(context).cardColor.withOpacity(0.8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Artist: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: song.artist,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Album: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: song.album,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Genre: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: song.genre,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Year: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: song.year.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Duration: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: PlayerWidget.formatDuration(
                                          song.duration),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Play Count: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: song.metadata.playCount.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Last Played: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    TextSpan(
                                      text: _formatLastPlayed(
                                          song.metadata.lastPlayed),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }

  String _formatLastPlayed(DateTime lastPlayed) {
    final now = DateTime.now();
    final duration = now.difference(lastPlayed);

    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = (duration.inDays % 365) % 30;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];
    if (years > 0) parts.add('$years year${years > 1 ? 's' : ''}');
    if (months > 0) parts.add('$months month${months > 1 ? 's' : ''}');
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (minutes > 0) parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds second${seconds > 1 ? 's' : ''}');
    }
    parts.add('ago');

    return parts.join(', ');
  }
}
