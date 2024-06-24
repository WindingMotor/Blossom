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
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredArtists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<Player>(context, listen: false);
      setState(() {
        filteredArtists = player.getUniqueArtists();
      });
    });
  }

  void filterArtists(String query) {
    final player = Provider.of<Player>(context, listen: false);
    final allArtists = player.getUniqueArtists();
    setState(() {
      filteredArtists = allArtists
          .where((artist) => artist.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8),
            const Text('Artists'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
                context: context, delegate: ArtistSearchDelegate(this)),
          ),
        ],
      ),
      body: Consumer<Player>(
        builder: (context, player, child) {
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
                            ),
                            const SizedBox(height: 8),
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

// ArtistSearchDelegate remains the same

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
          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrentSong = player.currentSong != null &&
                  song.path == player.currentSong!.path;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: isCurrentSong
                    ? Colors.transparent
                    : Theme.of(context).cardColor,
                margin: const EdgeInsets.all(8.0),
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
            },
          );
        },
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }
}

class ArtistSearchDelegate extends SearchDelegate<String> {
  final _ArtistsPageState _artistsPageState;

  ArtistSearchDelegate(this._artistsPageState);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _artistsPageState.filterArtists('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _artistsPageState.filterArtists(query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _artistsPageState.filterArtists(query);
    return Container();
  }
}
