import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:blossom/artist_page.dart';
import 'package:blossom/player.dart';
import 'package:blossom/player_widget.dart';
import 'package:blossom/sort_dropdown.dart';
import 'package:blossom/visual.dart';
// Adjust the import path according to your project structure
import 'package:provider/provider.dart';

void main() {
  // Initialize the app and provide the Player instance to the widget tree

  runApp(
    ChangeNotifierProvider(
      create: (context) => Player(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark, // Enable dark mode
          scaffoldBackgroundColor:
              Colors.black.withOpacity(0.8), // Main background color
          cardColor:
              Colors.grey.shade900.withOpacity(0.2), // Card background color
          appBarTheme: AppBarTheme(
              color: Colors.black.withOpacity(0.8)), // App bar color
          popupMenuTheme: PopupMenuThemeData(
              color: Colors.black
                  .withOpacity(0.8)), // Drop down menu background color
          splashColor: Colors.pink.shade300.withOpacity(0.5)),
      // Circular progress indicator theme

      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;
  int _currentImageIndex = 0;
  late Future<void> _delayFuture;

  @override
  void initState() {
    super.initState();
    _delayFuture = Future.delayed(const Duration(seconds: 4));
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentImageIndex++;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 18),
            Text('Blossom',
                style: TextStyle(
                  fontFamily: 'Magic Retro',
                  fontSize: 38,
                  color: Colors.pink.shade300,
                ))
          ],
        ),
      ),
      body: Stack(
        children: [
          // Blurred background image
          Positioned.fill(
            child: Blur(
              blur: 6,
              blurColor: Colors.black,
              colorOpacity: 0.75,
              overlay: Container(color: Colors.black.withOpacity(0.2)),
              child: Image.asset(
                'assets/bg1.gif',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ),
          // Main content
          FutureBuilder<void>(
            future: _delayFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _buildMainContent();
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Blossoming the library...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Magic Retro',
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }

  _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                buildInkwell(
                  context,
                  icon: Icons.library_music_rounded,
                  title: 'Library',
                  subtitle: 'View all songs',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SongsListPage()),
                    );
                  },
                ),
                buildInkwell(
                  context,
                  icon: Icons.person,
                  title: 'Artists',
                  subtitle: 'See all artists',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ArtistsPage()),
                    );
                  },
                ),
                buildInkwell(
                  context,
                  icon: Icons.queue_music_rounded,
                  title: 'Playlists',
                  subtitle: 'Browse your playlists',
                  onTap: () {
                    // Implement navigation to albums page
                  },
                ),
                buildInkwell(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Manage Blossom',
                  onTap: () {
                    // Implement navigation to settings page
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Consumer<Player>(
            builder: (context, player, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: player.isPlaying ? 120 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: player.isPlaying ? 1.0 : 0.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Now Playing: ${player.currentSong?.title ?? ""}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        child: MusicVisualizer(
                          color: Colors.pink.shade300,
                          audioPlayer: player.audioPlayer,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildInkwell(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final player = Provider.of<Player>(context, listen: false);
    final randomSong = player.allSongs.isNotEmpty
        ? player.allSongs[
            (_currentImageIndex + Random().nextInt(player.allSongs.length)) %
                player.allSongs.length]
        : null;

    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: Stack(
            children: [
              // Background image with fade transition
              if (randomSong != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.memory(
                    randomSong.picture!.data,
                    key: ValueKey(_currentImageIndex),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              // Blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 35, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SongsListPage extends StatefulWidget {
  const SongsListPage({super.key});

  @override
  _SongsListPageState createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  bool isSearchVisible = false;
  TextEditingController searchController = TextEditingController();
  late Future<void> _playlistResetFuture;

  @override
  void initState() {
    super.initState();
    _playlistResetFuture = _resetPlaylist();
  }

  Future<void> _resetPlaylist() async {
    final player = Provider.of<Player>(context, listen: false);
    await Future.microtask(() => player.resetPlaylistKeepingCurrentSong());
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<Player>(context);

    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for songs...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: player.performSearch,
              )
            : Row(
                children: [
                  const Icon(Icons.my_library_music_rounded,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Library'),
                  const SizedBox(width: 16),
                  Text('${player.playlistSongs.length} songs',
                      style: const TextStyle(fontSize: 12)),
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
                  player.performSearch('');
                }
              });
            },
          ),
          if (isSearchVisible) const SizedBox(width: 16),
          if (!isSearchVisible)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SortDropdownMenu(
                items: const [
                  'Name',
                  'Duration',
                  'Artist',
                  'Genre',
                  'Year',
                  'Play Count',
                  'Last Played'
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    player.sortSongs(newValue);
                  }
                },
                selectedItem: player.currentSortBy,
                currentOption: player.currentSortBy,
                isSortingReversed: player.isSortingReversed,
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _playlistResetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<Player>(
              builder: (context, player, child) {
                return Stack(
                  children: [
                    if (player.playlistSongs.isEmpty)
                      const Center(
                        child: Text('No songs found 😿'),
                      ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView.builder(
                            itemCount: player.playlistSongs.length,
                            itemBuilder: (context, index) {
                              final song = player.playlistSongs[index];
                              final isCurrentSong =
                                  player.currentSong != null &&
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
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          clipBehavior: Clip.antiAlias,
                                          child: Blur(
                                            blur: 35,
                                            blurColor: Colors.black,
                                            colorOpacity: 0.65,
                                            overlay: Container(
                                                color: Colors.black
                                                    .withOpacity(0.3)),
                                            child: Image.memory(
                                              player.playlistSongs[index]
                                                  .picture!.data,
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
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: MemoryImage(player
                                                .playlistSongs[index]
                                                .picture!
                                                .data),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        player.playlistSongs[index].title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isCurrentSong
                                              ? Colors.white
                                              : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              color: isCurrentSong
                                                  ? Colors.white
                                                  : null,
                                            ),
                                            tooltip: isCurrentSong
                                                ? 'Stop ${player.playlistSongs[index].title}'
                                                : 'Play ${player.playlistSongs[index].title}',
                                            onPressed: () {
                                              if (isCurrentSong) {
                                                player.stop();
                                              } else {
                                                player.selectSong(player
                                                    .playlistSongs[index]);
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
                                              PlayerWidget.formatDuration(player
                                                  .playlistSongs[index]
                                                  .duration),
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
                              );
                            },
                          )),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: const PlayerWidget(),
    );
  }
}
