import 'package:flutter/material.dart';
import 'package:blossom/player.dart';
import 'package:blossom/player_widget.dart';
import 'package:provider/provider.dart';
import 'package:blur/blur.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  _ArtistsPageState createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  bool isSearchVisible = false;
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for artists...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : const Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Artists'),
                ],
              ),
        actions: <Widget>[
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search),
            tooltip: isSearchVisible ? 'Close' : 'Search',
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (!isSearchVisible) {
                  searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<Player>(
        builder: (context, player, child) {
          final allArtists = player.getUniqueArtists();
          final filteredArtists = searchController.text.isEmpty
              ? allArtists
              : allArtists
                  .where((artist) => artist
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase()))
                  .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredArtists.length,
            itemBuilder: (context, index) {
              final artist = filteredArtists[index];
              final firstSong =
                  player.allSongs.firstWhere((song) => song.artist == artist);
              return GestureDetector(
                onTap: () => _navigateToArtistSongs(context, artist),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          firstSong.picture!.data,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Blur(
                          blur: 3,
                          blurColor: Colors.black,
                          child: Container(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.getArtistSongCount(artist) == 1
                                  ? '1 song'
                                  : '${player.getArtistSongCount(artist)} songs',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }

  void _navigateToArtistSongs(BuildContext context, String artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistSongsPage(artist: artist),
      ),
    );
  }
}

class ArtistSongsPage extends StatelessWidget {
  final String artist;

  const ArtistSongsPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs by $artist'),
      ),
      body: Consumer<Player>(
        builder: (context, player, child) {
          final songs =
              player.allSongs.where((song) => song.artist == artist).toList();
          final totalSeconds =
              songs.fold(0, (prev, song) => prev + song.duration);
          final totalDuration = Duration(seconds: totalSeconds);

          return ListView(
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
                        songs.length == 1 ? '1 song' : '${songs.length} songs',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total duration: ${PlayerWidget.formatDurationHour(totalDuration)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
                        onPressed: () {
                          player.playlistSongs = List.from(songs);
                          if (songs.isNotEmpty) {
                            player.selectSong(songs[0]);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // List of individual songs
              ...songs.asMap().entries.map((entry) {
                final index = entry.key;
                final song = entry.value;
                final isCurrentSong = player.currentSong != null &&
                    song.path == player.currentSong!.path;
                return Card(
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
                              overlay: Container(
                                  color: Colors.black.withOpacity(0.3)),
                              child: Image.memory(
                                song.picture!.data,
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
                              image: MemoryImage(song.picture!.data),
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            fontSize: 18,
                            color: isCurrentSong ? Colors.white : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.album,
                              style: TextStyle(
                                color: isCurrentSong
                                    ? Colors.grey[200]
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              song.genre,
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
                                  ? 'Stop ${song.title}'
                                  : 'Play ${song.title}',
                              onPressed: () {
                                if (isCurrentSong) {
                                  player.stop();
                                } else {
                                  player.selectSong(song);
                                }
                              },
                            ),
                            Column(
                              children: [
                                Text(
                                  ' #${index + 1}',
                                  style: TextStyle(
                                    color: isCurrentSong
                                        ? Colors.grey[200]
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  PlayerWidget.formatDuration(song.duration),
                                  style: TextStyle(
                                    color: isCurrentSong
                                        ? Colors.grey[200]
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  ' ${song.metadata.playCount} plays',
                                  style: TextStyle(
                                    color: isCurrentSong
                                        ? Colors.grey[200]
                                        : Colors.grey[600],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }
}
