import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'metadata.dart';
import 'package:whisper_dart/scheme/scheme.dart';
import 'package:whisper_dart/whisper_dart.dart';

import 'settings.dart';

class Player extends ChangeNotifier {
  late AudioPlayer audioPlayer;
  late MetadataManager _metadataManager;

  bool _isPlaying = false;
  Song? _currentSong;
  List<Song> allSongs = [];
  List<Song> playlistSongs = [];
  int currentIndex = -1;
  bool globalShowPlayerBottomBar = false;
  final Random _random = Random();
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

  // Getters
  bool get showPlayerBottomBar => globalShowPlayerBottomBar;
  bool get isPlaying => _isPlaying;
  Song? get currentSong => _currentSong;
  Duration get currentPosition => _currentPosition;
  Duration get duration => _duration;
  double get volume => _volume;

  late Fuzzy<Song> fuzzySongs;
  String currentSortBy = 'Name';
  bool isSortingReversed = false;

  late Settings settings;

  Player() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _loadSettings();
    JustAudioMediaKit.ensureInitialized();
    audioPlayer = AudioPlayer();
    _metadataManager = MetadataManager(
      metadataDirectory: settings.metadataDirectory,
      songsDirectory: settings.musicDirectory,
    );

    _initializeAudioPlayer();
    await _loadAllSongs();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    settings = await Settings.load();
    _volume = settings.defaultVolume;
    notifyListeners();
  }

  void _initializeAudioPlayer() {
    audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    audioPlayer.durationStream.listen((newDuration) {
      _duration = newDuration ?? Duration.zero;
      notifyListeners();
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _incrementPlayCount().then((_) {
          nextSong();
        });
      }
    });
  }

  Future<void> updateSettings(Settings newSettings) async {
    settings = newSettings;
    await settings.save();
    _volume = settings.defaultVolume;
    audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  Future<void> _loadAllSongs() async {
    allSongs = await _metadataManager.loadSongsWithMetadata();
    playlistSongs = List.from(allSongs);
    _initializeFuzzySearch();
    notifyListeners();
  }

  void _initializeFuzzySearch() {
    fuzzySongs = Fuzzy(
      allSongs,
      options: FuzzyOptions(keys: [
        WeightedKey(
            name: 'title',
            getter: (song) => song.title.toLowerCase(),
            weight: 5),
        WeightedKey(
            name: 'artist',
            getter: (song) => song.artist.toLowerCase(),
            weight: 4),
        WeightedKey(
            name: 'album',
            getter: (song) => song.album.toLowerCase(),
            weight: 3),
        WeightedKey(
            name: 'genre',
            getter: (song) => song.genre.toLowerCase(),
            weight: 2),
      ], threshold: 0.4, isCaseSensitive: false),
    );
  }

  Future<void> _incrementPlayCount() async {
    if (_currentSong != null) {
      final updatedMetadata = _currentSong!.metadata.copyWith(
        playCount: _currentSong!.metadata.playCount + 1,
        lastPlayed: DateTime.now(),
      );
      final updatedSong = _currentSong!.copyWith(metadata: updatedMetadata);

      // Update the metadata in the manager
      await _metadataManager.updateMetadata(updatedSong, updatedMetadata);

      // Update the song in allSongs and playlistSongs
      _updateSongInLists(updatedSong);

      // Update the current song
      _currentSong = updatedSong;

      // Notify listeners after all updates are complete
      notifyListeners();
    }
  }

  void _updateSongInLists(Song updatedSong) {
    // Update in allSongs
    final allSongsIndex =
        allSongs.indexWhere((s) => s.path == updatedSong.path);
    if (allSongsIndex != -1) {
      allSongs[allSongsIndex] = updatedSong;
    }

    // Update in playlistSongs
    final playlistSongsIndex =
        playlistSongs.indexWhere((s) => s.path == updatedSong.path);
    if (playlistSongsIndex != -1) {
      playlistSongs[playlistSongsIndex] = updatedSong;
    }
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      playlistSongs = List.from(allSongs);
    } else {
      final lowercaseQuery = query.toLowerCase();
      final results = fuzzySongs.search(lowercaseQuery);
      playlistSongs = results.map((result) => result.item).toList();

      // If no fuzzy results, try a simple contains search
      if (playlistSongs.isEmpty) {
        playlistSongs = allSongs
            .where((song) =>
                song.title.toLowerCase().contains(lowercaseQuery) ||
                song.artist.toLowerCase().contains(lowercaseQuery) ||
                song.album.toLowerCase().contains(lowercaseQuery) ||
                song.genre.toLowerCase().contains(lowercaseQuery))
            .toList();
      }
    }
    notifyListeners();
  }

  void sortSongs(String sortBy) {
    currentSortBy = sortBy;
    isSortingReversed = !isSortingReversed;

    Comparator<Song> comparator;
    switch (sortBy) {
      case 'Name':
        comparator = (a, b) => isSortingReversed
            ? b.title.compareTo(a.title)
            : a.title.compareTo(b.title);
        break;
      case 'Duration':
        comparator = (a, b) => isSortingReversed
            ? a.duration.compareTo(b.duration)
            : b.duration.compareTo(a.duration);
        break;
      case 'Artist':
        comparator = (a, b) => isSortingReversed
            ? b.artist.compareTo(a.artist)
            : a.artist.compareTo(b.artist);
        break;
      case 'Genre':
        comparator = (a, b) => isSortingReversed
            ? b.genre.compareTo(a.genre)
            : a.genre.compareTo(b.genre);
        break;
      case 'Year':
        comparator = (a, b) => isSortingReversed
            ? b.year.compareTo(a.year)
            : a.year.compareTo(b.year);
        break;
      case 'Play Count':
        comparator = (a, b) => isSortingReversed
            ? a.metadata.playCount.compareTo(b.metadata.playCount)
            : b.metadata.playCount.compareTo(a.metadata.playCount);
        break;
      case 'Last Played':
        comparator = (a, b) => isSortingReversed
            ? b.metadata.lastPlayed.compareTo(a.metadata.lastPlayed)
            : a.metadata.lastPlayed.compareTo(b.metadata.lastPlayed);
        break;
      default:
        return;
    }
    playlistSongs.sort(comparator);
    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> pause() async {
    _isPlaying = false;
    await audioPlayer.pause();
    notifyListeners();
  }

  Future<void> play() async {
    _isPlaying = true;
    await audioPlayer.play();
    notifyListeners();
  }

  // Selects a song from the playlist. If the song is not in the playlist, resets the playlist to include all songs. Then, sets the current index to the index of the selected song in the playlist and plays the selected song.
  Future<void> selectSong(Song song) async {
    if (!playlistSongs.contains(song)) {
      playlistSongs = List.from(allSongs);
    }
    currentIndex = playlistSongs.indexWhere((s) => s.path == song.path);
    await _playSong(song);
  }

  Future<void> selectArtist(String artist) async {
    playlistSongs = allSongs.where((song) => song.artist == artist).toList();
    if (playlistSongs.isNotEmpty) {
      // Do not automatically start playing the first song
      // Remove or comment out the lines that set currentIndex and play the song
      // currentIndex = 0;
      // await _playSong(playlistSongs[currentIndex]);
    }
    notifyListeners();
  }

  void resetPlaylist() {
    playlistSongs = List.from(allSongs);
    notifyListeners();
  }

  int getArtistSongCount(String artistName) {
    return allSongs.where((song) => song.artist == artistName).length;
  }

  Future<void> _playSong(Song song) async {
    Uri uri = Uri.file(song.path);
    try {
      await audioPlayer.setUrl(uri.toString());
      await audioPlayer.play();
      _currentSong = song;

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print("Error playing audio: $e");
      _resetPlayerState();
    }
  }

  void _resetPlayerState() {
    _isPlaying = false;
    _currentSong = null;
    currentIndex = -1;
    notifyListeners();
  }

  void togglePlayPause() async {
    _isPlaying ? await pause() : await play();
  }

  void nextSong() {
    // print("next");
    //print("before ${_currentSong?.title.toString() ?? ''}");

    if (currentIndex < playlistSongs.length - 1) {
      currentIndex++;
      _playSong(playlistSongs[currentIndex]);
      _currentSong = playlistSongs[currentIndex];
    } else if (playlistSongs.isNotEmpty) {
      // Loop back to the first song if we're at the end
      currentIndex = 0;
      _playSong(playlistSongs[currentIndex]);
    }
    notifyListeners();

    // print("after ${_currentSong?.title.toString() ?? ''}");
  }

  void previousSong() {
    if (currentIndex > 0) {
      currentIndex--;
      _playSong(playlistSongs[currentIndex]);
      _currentSong = playlistSongs[currentIndex];
    }
  }

  void shufflePlaylist() {
    if (playlistSongs.isEmpty) return;

    final currentSong = _currentSong;
    playlistSongs.shuffle(_random);

    if (currentSong != null) {
      final index =
          playlistSongs.indexWhere((song) => song.path == currentSong.path);
      if (index != -1) {
        final song = playlistSongs.removeAt(index);
        playlistSongs.insert(0, song);
        currentIndex = 0;
      }
    }

    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
    notifyListeners();
  }

  void stop() {
    audioPlayer.stop();
    _resetPlayerState();
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  Future<void> transcribeSong(String audioFilePath, String modelPath) async {
    Whisper whisper = Whisper(whisperLib: "./path_to_your_whisper_library");
    try {
      Transcribe transcribe = await whisper.transcribe(
        audio: audioFilePath,
        model: modelPath,
        language: "en",
      );
      print(transcribe.text);
    } catch (e) {
      print("Error during transcription: $e");
    }
  }

  List<String> getUniqueAlbums() {
    return allSongs.map((song) => song.album).toSet().toList();
  }

  List<String> getUniqueArtists() {
    return allSongs.map((song) => song.artist).toSet().toList();
  }

  void resetPlaylistKeepingCurrentSong() {
    if (_currentSong != null) {
      int currentIndex =
          playlistSongs.indexWhere((song) => song.path == _currentSong!.path);
      playlistSongs = List.from(allSongs);
      if (currentIndex != -1) {
        // If the current song was in the playlist, find its new index
        currentIndex =
            playlistSongs.indexWhere((song) => song.path == _currentSong!.path);
      } else {
        // If the current song wasn't in the playlist, add it to the beginning
        playlistSongs.insert(0, _currentSong!);
        currentIndex = 0;
      }
      this.currentIndex = currentIndex;
    } else {
      playlistSongs = List.from(allSongs);
      currentIndex = -1;
    }
    sortSongs(currentSortBy); // Re-apply the current sorting
    notifyListeners();
  }

  Future<String> getMusicDirectorySize() async {
    try {
      final musicDir = Directory(settings.musicDirectory);
      int totalSize = 0;
      await for (final file
          in musicDir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return _formatBytes(totalSize);
    } catch (e) {
      print('Error getting music directory size: $e');
      return 'Unknown';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
