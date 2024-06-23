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

  Future<Song> createSong(String file) async {
    //debugPrint("Creating song for file: $file");
    Metadata metadata = await MetadataGod.readMetadata(file: file);
    //debugPrint("Metadata fetched: ${metadata.title}");

    Song song = Song(
        path: file,
        title: metadata.title ?? '',
        album: metadata.album ?? '',
        artist: metadata.artist ?? '',
        duration: metadata.duration?.inSeconds ?? 0,
        picture: metadata.picture,
        year: metadata.year ?? 0,
        genre: metadata.genre ?? '',
        size: metadata.fileSize ?? 0);

    //debugPrint("Created song: ${song.title}");
    return song;
  }

  Future<List<Song>> fetchSongsFromDirectory(String directoryPath) async {
    debugPrint("[INFO] Fetching songs from directory: $directoryPath");
    List<Song> songs = [];
    Directory directory = Directory(directoryPath);

    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();

      for (var file in files) {
        if (file is File) {
          String extension = path.extension(file.path).toLowerCase();
          if (extension == '.mp3' || extension == '.flac') {
            //debugPrint("Processing file: ${file.path}");
            try {
              Song song = await createSong(file.path);
              songs.add(song);
            } catch (e) {
              debugPrint(
                  "[ERROR] Failed to create song for file: ${file.path}, error: $e");
            }
          } else {
            debugPrint("[WARN] Skipping non-audio file: ${file.path}");
          }
        }
      }
    } else {
      debugPrint("[ERROR] Directory does not exist: $directoryPath");
    }

    debugPrint("[INFO] Fetched ${songs.length} songs");
    return songs;
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

  Song(
      {required this.path,
      required this.title,
      required this.album,
      required this.artist,
      required this.duration,
      required this.picture,
      required this.year,
      required this.genre,
      required this.size});
}
