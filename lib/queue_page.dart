import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player.dart';
import 'player_widget.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<Player>(context);
    final totalSeconds =
        player.playlistSongs.fold(0, (prev, song) => prev + song.duration);
    final totalDuration = Duration(seconds: totalSeconds);

    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          const Icon(Icons.queue_music_rounded),
          const SizedBox(width: 8),
          Text(
            'Current Queue',
          )
        ],
      )),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // New card for playing all songs
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    player.playlistSongs.length == 1
                        ? '1 song'
                        : '${player.playlistSongs.length} songs',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total duration: ${PlayerWidget.formatDurationHour(totalDuration)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...player.playlistSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            final isCurrentSong = player.currentSong != null &&
                song.path == player.currentSong!.path;
            final isPlayed = player.currentIndex > index;

            return Opacity(
              opacity: isPlayed
                  ? 0.2
                  : 1.0, // Set the opacity to 0.5 if the song has been played
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: isCurrentSong
                    ? Colors.transparent
                    : Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  children: [
                    if (isCurrentSong)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: Blur(
                            blur: 35,
                            blurColor: Colors.black,
                            colorOpacity: 0.65,
                            overlay:
                                Container(color: Colors.black.withOpacity(0.3)),
                            child: Image.memory(
                              player.playlistSongs[index].picture!.data,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: MemoryImage(
                                player.playlistSongs[index].picture!.data),
                          ),
                        ),
                      ),
                      title: Text(
                        player.playlistSongs[index].title,
                        style: TextStyle(
                          fontSize: 18,
                          color: isCurrentSong ? Colors.white : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${player.playlistSongs[index].artist} - ${player.playlistSongs[index].album}',
                            style: TextStyle(
                              color: isCurrentSong
                                  ? Colors.grey[200]
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            player.playlistSongs[index].genre,
                            style: TextStyle(
                              color: isCurrentSong
                                  ? Colors.grey[200]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isCurrentSong
                                  ? Icons.stop_circle
                                  : Icons.play_arrow_rounded,
                              color: isCurrentSong ? Colors.white : null,
                            ),
                            tooltip: isCurrentSong
                                ? 'Stop ${player.playlistSongs[index].title}'
                                : 'Play ${player.playlistSongs[index].title}',
                            onPressed: () {
                              if (isCurrentSong) {
                                player.stop();
                              } else {
                                player.selectSong(player.playlistSongs[index]);
                              }
                            },
                          ),
                          Column(children: [
                            Text(
                              ' #${index + 1}',
                              style: TextStyle(
                                color: isCurrentSong
                                    ? Colors.grey[200]
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              PlayerWidget.formatDuration(
                                  player.playlistSongs[index].duration),
                              style: TextStyle(
                                color: isCurrentSong
                                    ? Colors.grey[200]
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              ' ${player.playlistSongs[index].metadata.playCount} plays',
                              style: TextStyle(
                                color: isCurrentSong
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            )
                          ])
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }
}
