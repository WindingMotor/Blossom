import 'dart:convert';
import 'dart:io';
import 'package:blossom/player.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class Settings {
  String musicDirectory;
  String metadataDirectory;
  double defaultVolume;

  Settings({
    required this.musicDirectory,
    required this.metadataDirectory,
    this.defaultVolume = 0.5,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      musicDirectory: json['musicDirectory'] ?? '',
      metadataDirectory: json['metadataDirectory'] ?? '',
      defaultVolume: json['defaultVolume']?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'musicDirectory': musicDirectory,
      'metadataDirectory': metadataDirectory,
      'defaultVolume': defaultVolume,
    };
  }

  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/settings.json');
  }

  static Future<Settings> load() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return Settings.fromJson(json.decode(contents));
    } catch (e) {
      // If we encounter an error, return default settings
      return Settings(
        musicDirectory: '',
        metadataDirectory: '',
        defaultVolume: 0.5,
      );
    }
  }

  Future<void> save() async {
    final file = await _localFile;
    await file.writeAsString(json.encode(toJson()));
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _musicDirController;
  late TextEditingController _metadataDirController;
  late double _defaultVolume;

  @override
  void initState() {
    super.initState();
    final player = Provider.of<Player>(context, listen: false);
    _musicDirController =
        TextEditingController(text: player.settings.musicDirectory);
    _metadataDirController =
        TextEditingController(text: player.settings.metadataDirectory);
    _defaultVolume = player.settings.defaultVolume;
  }

  @override
  void dispose() {
    _musicDirController.dispose();
    _metadataDirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Row(
        children: [
          Icon(Icons.settings),
          SizedBox(width: 8),
          Text('Settings'),
        ],
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Music Directory',
                style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _musicDirController,
                    decoration: const InputDecoration(
                      hintText: 'Select music directory',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    String? selectedDirectory =
                        await FilePicker.platform.getDirectoryPath();
                    if (selectedDirectory != null) {
                      setState(() {
                        _musicDirController.text = selectedDirectory;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Metadata Directory',
                style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _metadataDirController,
                    decoration: const InputDecoration(
                      hintText: 'Select metadata directory',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    String? selectedDirectory =
                        await FilePicker.platform.getDirectoryPath();
                    if (selectedDirectory != null) {
                      setState(() {
                        _metadataDirController.text = selectedDirectory;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Default Volume',
                style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: _defaultVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _defaultVolume.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _defaultVolume = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Save Settings and Restart'),
              onPressed: () async {
                final player = Provider.of<Player>(context, listen: false);
                final newSettings = Settings(
                  musicDirectory: _musicDirController.text,
                  metadataDirectory: _metadataDirController.text,
                  defaultVolume: _defaultVolume,
                );
                await player.updateSettings(newSettings);

                // Show a dialog to inform the user about the restart
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Settings Saved'),
                      content: const Text(
                          'The application will now close to apply the new settings.'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            // Restart the application
                            restartApp();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void restartApp() {
    exit(0); // This will close the app
    // The system will automatically restart the app if it's configured to do so
  }
}
