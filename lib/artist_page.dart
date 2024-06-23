import 'package:flutter/material.dart';
import 'package:musica/player.dart';
import 'package:musica/player_widget.dart';
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
        title: const Text('Artists'),
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
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: Colors.white,
                              onPressed: () {
                                player.selectArtist(artist);
                              },
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
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: MemoryImage(song.picture!.data),
                    ),
                  ),
                ),
                title: Text(song.title),
                subtitle: Text(song.album),
                onTap: () => player.selectSong(song),
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
