import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/dart_announcer_service.dart';
import '../services/app_settings.dart';
import '../services/victory_music_service.dart';
import '../models/victory_music_file.dart';
import 'test_dartboard_screen.dart';

class OptionsScreen extends StatefulWidget {
  final DartAnnouncerService announcer;

  const OptionsScreen({
    super.key,
    required this.announcer,
  });

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  VoiceEngine _voiceEngine = VoiceEngine.responsiveVoice;
  AnnouncerVoice _selectedVoice = AnnouncerVoice.professional;
  String _selectedSystemVoice = '';
  String _selectedResponsiveVoice = 'Australian Female';
  List<dynamic> _systemVoices = [];
  bool _responsiveVoiceReady = false;
  bool _isSaving = false;
  List<VictoryMusicFile> _victoryMusicFiles = [];

  @override
  void initState() {
    super.initState();
    _loadVoices();
    _loadSettings();
  }

  Future<void> _loadVoices() async {
    // Wait a bit for TTS to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    // Check ResponsiveVoice availability
    setState(() {
      _responsiveVoiceReady = widget.announcer.isResponsiveVoiceReady();
    });

    setState(() {
      _systemVoices = widget.announcer.availableVoices;
      // Filter to English voices only
      _systemVoices = _systemVoices.where((voice) {
        final locale = (voice['locale'] ?? '').toString();
        return locale.startsWith('en');
      }).toList();

      if (_systemVoices.isNotEmpty && _selectedSystemVoice.isEmpty) {
        _selectedSystemVoice = _systemVoices[0]['name'];
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load voice engine
      final engineStr = prefs.getString('voice_engine') ?? 'responsiveVoice';
      _voiceEngine = VoiceEngine.values.firstWhere(
        (e) => e.name == engineStr,
        orElse: () => VoiceEngine.responsiveVoice,
      );

      // Load announcer style
      final styleStr = prefs.getString('announcer_style') ?? 'professional';
      _selectedVoice = AnnouncerVoice.values.firstWhere(
        (v) => v.name == styleStr,
        orElse: () => AnnouncerVoice.professional,
      );

      // Load system voice
      _selectedSystemVoice = prefs.getString('system_voice') ?? '';

      // Load ResponsiveVoice
      _selectedResponsiveVoice = prefs.getString('responsive_voice') ?? 'Australian Female';

    });

    // Load victory music files from service
    final musicService = VictoryMusicService();
    final files = await musicService.getMusicFiles();
    setState(() {
      _victoryMusicFiles = files;
    });

    // Apply loaded settings to announcer
    _applySettings();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_engine', _voiceEngine.name);
      await prefs.setString('announcer_style', _selectedVoice.name);
      await prefs.setString('system_voice', _selectedSystemVoice);
      await prefs.setString('responsive_voice', _selectedResponsiveVoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default voice settings saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _applySettings() {
    if (_voiceEngine == VoiceEngine.responsiveVoice) {
      widget.announcer.useResponsiveVoice();
      widget.announcer.setResponsiveVoice(_selectedResponsiveVoice);
    } else {
      widget.announcer.setVoice(_selectedVoice);
      widget.announcer.useBrowserVoices();
      if (_selectedSystemVoice.isNotEmpty) {
        widget.announcer.setSystemVoice(_selectedSystemVoice);
      }
    }
  }

  void _testVoice() {
    // Apply current settings before testing
    _applySettings();
    widget.announcer.speak('The quick brown fox jumped over the lazy dog');
  }

  void _checkResponsiveVoice() {
    final isReady = widget.announcer.isResponsiveVoiceReady();

    setState(() {
      _responsiveVoiceReady = isReady;
      if (isReady) {
        _voiceEngine = VoiceEngine.responsiveVoice;
      }
    });

    if (isReady) {
      _applySettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ResponsiveVoice ready! Natural voices enabled.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ResponsiveVoice not loaded. Please refresh the page.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectVictoryMusic() async {
    try {
      // WMA is not supported in web browsers, only allow web-compatible formats
      final allowedExtensions = kIsWeb
          ? ['mp3', 'wav', 'ogg', 'aac']
          : ['mp3', 'wav', 'wma', 'ogg', 'aac'];

      debugPrint('Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb, // Get bytes on web since paths aren't available
        withReadStream: false,
      );

      debugPrint('File picker result: $result');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name;
        final fileSize = file.size;
        final hasBytes = file.bytes != null;

        debugPrint('Selected file: $fileName, size: $fileSize, hasBytes: $hasBytes');

        if (kIsWeb && file.bytes == null) {
          throw Exception('Could not read file bytes. Please try again.');
        }

        // Use the VictoryMusicService to add the music file
        debugPrint('Adding music file...');
        final musicService = VictoryMusicService();
        await musicService.addMusicFile(
          fileName: fileName,
          filePath: kIsWeb ? null : file.path, // path not available on web
          fileBytes: file.bytes,
        );

        debugPrint('Music file added, reloading list...');
        // Reload the files list
        final files = await musicService.getMusicFiles();

        setState(() {
          _victoryMusicFiles = files;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error selecting file: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeMusicFile(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Music File'),
        content:
            const Text('Are you sure you want to remove this music file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final musicService = VictoryMusicService();
      await musicService.removeMusicFile(id);

      final files = await musicService.getMusicFiles();
      setState(() {
        _victoryMusicFiles = files;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music file removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllVictoryMusic() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Music'),
        content: Text(
            'Remove all ${_victoryMusicFiles.length} music file(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final musicService = VictoryMusicService();
      await musicService.clearAllMusic();

      setState(() {
        _victoryMusicFiles = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All music files cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            const Text('System Settings'),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Announcer Setup Section
            Text(
              'Announcer Setup',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the voice announcer for dart throw notifications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Voice Engine Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_voice),
                        const SizedBox(width: 8),
                        Text(
                          'Voice Engine',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<VoiceEngine>(
                            value: _voiceEngine,
                            decoration: const InputDecoration(
                              labelText: 'Engine',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (VoiceEngine? newEngine) {
                              if (newEngine != null) {
                                if (newEngine == VoiceEngine.responsiveVoice) {
                                  _checkResponsiveVoice();
                                } else {
                                  setState(() {
                                    _voiceEngine = newEngine;
                                  });
                                  _applySettings();
                                }
                              }
                            },
                            items: VoiceEngine.values.map((engine) {
                              return DropdownMenuItem<VoiceEngine>(
                                value: engine,
                                child: Text(engine.displayName),
                              );
                            }).toList(),
                          ),
                        ),
                        if (_voiceEngine == VoiceEngine.responsiveVoice)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              _responsiveVoiceReady ? Icons.check_circle : Icons.error,
                              color: _responsiveVoiceReady ? Colors.green : Colors.orange,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Voice Selection
            if (_voiceEngine == VoiceEngine.browser)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over),
                          const SizedBox(width: 8),
                          Text(
                            'System Voice',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _systemVoices.isEmpty
                          ? const Text('Loading voices...')
                          : DropdownButtonFormField<String>(
                              value: _selectedSystemVoice.isEmpty ? null : _selectedSystemVoice,
                              decoration: const InputDecoration(
                                labelText: 'Voice',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (String? newVoice) {
                                if (newVoice != null) {
                                  setState(() {
                                    _selectedSystemVoice = newVoice;
                                  });
                                  _applySettings();
                                }
                              },
                              items: _systemVoices.map((voice) {
                                final name = voice['name'] ?? 'Unknown';
                                final locale = voice['locale'] ?? '';
                                String displayName = name.toString();
                                if (displayName.contains('Google')) {
                                  displayName = displayName.replaceAll('Google ', '');
                                }
                                if (displayName.contains('Microsoft')) {
                                  displayName = displayName.replaceAll('Microsoft ', '');
                                }
                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text('$displayName ($locale)'),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
            if (_voiceEngine == VoiceEngine.responsiveVoice)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'ResponsiveVoice',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedResponsiveVoice,
                        decoration: const InputDecoration(
                          labelText: 'Voice',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String? newVoice) {
                          if (newVoice != null) {
                            setState(() {
                              _selectedResponsiveVoice = newVoice;
                            });
                            _applySettings();
                          }
                        },
                        items: widget.announcer.responsiveVoices.map((voice) {
                          return DropdownMenuItem<String>(
                            value: voice['name']!,
                            child: Text(voice['description']!),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Personality Style (only for browser voices)
            if (_voiceEngine == VoiceEngine.browser)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sentiment_satisfied),
                          const SizedBox(width: 8),
                          Text(
                            'Announcer Style',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AnnouncerVoice>(
                        value: _selectedVoice,
                        decoration: const InputDecoration(
                          labelText: 'Style',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (AnnouncerVoice? newVoice) {
                          if (newVoice != null) {
                            setState(() {
                              _selectedVoice = newVoice;
                            });
                            _applySettings();
                          }
                        },
                        items: AnnouncerVoice.values.map((voice) {
                          return DropdownMenuItem<AnnouncerVoice>(
                            value: voice,
                            child: Text(voice.displayName),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Announcer Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testVoice,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Voice'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save as Default'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Victory Music Section
            Text(
              'Victory Music',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select custom music to play when a winner is announced',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Victory Music',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Show count badge
                        if (_victoryMusicFiles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_victoryMusicFiles.length} file${_victoryMusicFiles.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info message
                    if (_victoryMusicFiles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No custom music selected. Default music will play.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _victoryMusicFiles.length == 1
                                    ? 'Playing one custom music file'
                                    : 'Randomly selecting from ${_victoryMusicFiles.length} music files',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // List of music files
                    if (_victoryMusicFiles.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _victoryMusicFiles.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final file = _victoryMusicFiles[index];
                            return ListTile(
                              dense: true,
                              leading:
                                  const Icon(Icons.music_note, size: 20),
                              title: Text(
                                file.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Added ${_formatDate(file.addedDate)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: Colors.red,
                                tooltip: 'Remove',
                                onPressed: () =>
                                    _removeMusicFile(file.id),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectVictoryMusic,
                            icon: const Icon(Icons.add),
                            label: Text(_victoryMusicFiles.isEmpty
                                ? 'Add Music File'
                                : 'Add Another File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_victoryMusicFiles.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _clearAllVictoryMusic,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Admin Section
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ADMIN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.computer),
                title: const Text('Scolia 2 Dartboard Emulator'),
                subtitle: const Text('Test dartboard functionality'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TestDartboardScreen(announcer: widget.announcer),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
