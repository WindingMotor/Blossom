import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as path;

class MetadataUtils {
  MetadataUtils() {
    MetadataGod.initialize();
  }

  Future<void> fetchMetadata(String file) async {
    Metadata metadata = await MetadataGod.readMetadata(file: file);
    debugPrint(metadata.album);
  }
}

class Song {
  final String path;
  final String title;
  final String album;
  final String artist;
  final int duration;
  final Picture? picture;
  final int year;
  final String genre;
  final int size;
  final SongMetadata metadata;

  Song({
    required this.path,
    required this.title,
    required this.album,
    required this.artist,
    required this.duration,
    required this.picture,
    required this.year,
    required this.genre,
    required this.size,
    required this.metadata,
  });

  Song copyWith({
    String? path,
    String? title,
    String? album,
    String? artist,
    int? duration,
    Picture? picture,
    int? year,
    String? genre,
    int? size,
    SongMetadata? metadata,
  }) {
    return Song(
      path: path ?? this.path,
      title: title ?? this.title,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      picture: picture ?? this.picture,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      size: size ?? this.size,
      metadata: metadata ?? this.metadata,
    );
  }
}

class SongMetadata {
  final bool isFavorite;
  final String playlist;
  final int playCount;
  final DateTime lastPlayed;

  SongMetadata({
    this.isFavorite = false,
    this.playlist = '',
    this.playCount = 0, // Ensure this defaults to 0
    DateTime? lastPlayed,
  }) : lastPlayed = lastPlayed ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'isFavorite': isFavorite,
      'playlist': playlist,
      'playCount': playCount,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory SongMetadata.fromJson(Map<String, dynamic> json) {
    final playCount = json['playCount'];
    return SongMetadata(
      isFavorite: json['isFavorite'] ?? false,
      playlist: json['playlist'] ?? '',
      playCount: playCount is int ? playCount : 0,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'])
          : null,
    );
  }

  SongMetadata copyWith({
    bool? isFavorite,
    String? playlist,
    int? playCount,
    DateTime? lastPlayed,
  }) {
    return SongMetadata(
      isFavorite: isFavorite ?? this.isFavorite,
      playlist: playlist ?? this.playlist,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}

class MetadataManager {
  final String metadataDirectory;
  final String songsDirectory;

  MetadataManager({
    required this.metadataDirectory,
    required this.songsDirectory,
  }) {
    _ensureMetadataDirectoryExists();
  }

  void _ensureMetadataDirectoryExists() {
    final directory = Directory(metadataDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  Future<void> saveMetadata(Song song) async {
    final file = File(path.join(
        metadataDirectory, '${path.basenameWithoutExtension(song.path)}.json'));
    await file.writeAsString(jsonEncode(song.metadata.toJson()));
  }

  Future<SongMetadata> loadMetadata(String songPath) async {
    final file = File(path.join(
        metadataDirectory, '${path.basenameWithoutExtension(songPath)}.json'));
    if (await file.exists()) {
      final content = await file.readAsString();
      return SongMetadata.fromJson(jsonDecode(content));
    } else {
      print(
          "No metadata file found for $songPath, creating default"); // Debug log
      final defaultMetadata = SongMetadata();
      await saveMetadata(Song(
        path: songPath,
        title: path.basenameWithoutExtension(songPath),
        album: '',
        artist: '',
        duration: 0,
        picture: null,
        year: 0,
        genre: '',
        size: 0,
        metadata: defaultMetadata,
      ));
      return defaultMetadata;
    }
  }

  Future<List<Song>> loadSongsWithMetadata() async {
    final directory = Directory(songsDirectory);
    final List<Song> songs = [];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          ['.mp3', '.flac', '.wav', '.m4a']
              .contains(path.extension(entity.path).toLowerCase())) {
        try {
          final metadata = await MetadataGod.readMetadata(file: entity.path);
          final songMetadata = await loadMetadata(entity.path);

          final song = Song(
            path: entity.path,
            title: metadata.title ?? path.basenameWithoutExtension(entity.path),
            album: metadata.album ?? '',
            artist: metadata.artist ?? '',
            duration: metadata.duration?.inSeconds ?? 0,
            picture: metadata.picture,
            year: metadata.year ?? 0,
            genre: metadata.genre ?? '',
            size: await entity.length(),
            metadata: songMetadata,
          );
          songs.add(song);
        } catch (e) {
          print('Error reading metadata for ${entity.path}: $e');
        }
      }
    }

    return songs;
  }

  Future<void> updateMetadata(Song song, SongMetadata newMetadata) async {
    final updatedSong = song.copyWith(metadata: newMetadata);
    await saveMetadata(updatedSong);
  }
}
