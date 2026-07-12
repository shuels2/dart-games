import 'dart:convert' show JsonEncoder, base64Encode;
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../main.dart' show apiClient;
import '../services/dart_announcer_service.dart';
import '../services/app_settings.dart';
import '../services/victory_music_service.dart';
import '../services/photo_service.dart';
import '../services/test_data_service.dart';
import '../services/test_headshot_landmarks_service.dart';
import '../models/victory_music_file.dart';
import '../widgets/add_player/add_player.dart';
import '../models/player.dart';
import '../providers/player_provider.dart';
import 'test_dartboard_screen.dart';
import 'api_logger_screen.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../widgets/player_avatar_widget.dart';
import '../widgets/face_landmark_inspector/face_landmark_inspector.dart';
import '../widgets/face_landmarks_hint.dart';
import '../utils/concurrent_runner.dart';
import '../services/api/api_config.dart';
import '../providers/dartboard_provider.dart';
import '../build_info.dart';

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
  // User-tunable playback rate (1.0 = normal). Slider range 0.7-1.5.
  double _playbackRate = 1.0;
  List<dynamic> _systemVoices = [];
  bool _responsiveVoiceReady = false;
  bool _isSaving = false;
  List<VictoryMusicFile> _victoryMusicFiles = [];
  final PhotoService _photoService = PhotoService();

  // Navigation and scrolling
  final ScrollController _scrollController = ScrollController();
  final ScrollController _playersListScrollController = ScrollController();
  final GlobalKey _announcerKey = GlobalKey();
  final GlobalKey _musicKey = GlobalKey();
  final GlobalKey _userManagementKey = GlobalKey();
  final GlobalKey _adminKey = GlobalKey();
  String _activeSection = 'announcer';
  PlayerProvider? _playerProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playerProvider = context.read<PlayerProvider>();
  }

  /// Cached face-landmark sidecar diagnostics, populated in [initState]
  /// via a background call to `GET /face-landmarks/diagnostics` and
  /// consumed by [_buildSidecarWarningBanner] to render a persistent
  /// orange banner at the top of the screen when detection is broken.
  /// Kept as state so we don't poll the endpoint on every rebuild.
  Map<String, dynamic>? _faceLandmarksDiagnostics;

  @override
  void initState() {
    super.initState();
    _loadVoices();
    _loadSettings();
    _scrollController.addListener(_onScroll);

    // Load players when screen opens (ensures alphabetical sorting)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PlayerProvider>().loadPlayers();
    });
    // Background probe of the face-landmarks sidecar so the persistent
    // warning banner appears if detection is broken. Failures are
    // logged but not surfaced — the banner just doesn't render if the
    // probe itself couldn't reach the endpoint.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final diag = await apiClient.faceLandmarksDiagnostics();
        if (mounted) setState(() => _faceLandmarksDiagnostics = diag);
      } catch (e) {
        debugPrint('Face-landmarks diagnostics probe failed: $e');
      }
    });
  }

  @override
  void dispose() {
    // Mark players as sorted when leaving screen
    _playerProvider?.markPlayersSorted();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _playersListScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.offset;
    String newSection = 'announcer';

    // Check which section is currently visible
    final announcerPosition = _getKeyPosition(_announcerKey);
    final musicPosition = _getKeyPosition(_musicKey);
    final userManagementPosition = _getKeyPosition(_userManagementKey);
    final adminPosition = _getKeyPosition(_adminKey);

    if (adminPosition != null && scrollPosition >= adminPosition - 100) {
      newSection = 'admin';
    } else if (userManagementPosition != null && scrollPosition >= userManagementPosition - 100) {
      newSection = 'userManagement';
    } else if (musicPosition != null && scrollPosition >= musicPosition - 100) {
      newSection = 'music';
    } else {
      newSection = 'announcer';
    }

    if (newSection != _activeSection) {
      setState(() {
        _activeSection = newSection;
      });
    }
  }

  double? _getKeyPosition(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position.dy + _scrollController.offset;
  }

  void _scrollToSection(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final offset = position.dy + _scrollController.offset - 100; // 100px offset for AppBar

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
    // Load voice engine
    final engineStr = await AppSettings.getVoiceEngine() ?? 'responsiveVoice';
    final voiceEngine = VoiceEngine.values.firstWhere(
      (e) => e.name == engineStr,
      orElse: () => VoiceEngine.responsiveVoice,
    );

    // Load announcer style
    final styleStr = await AppSettings.getAnnouncerStyle() ?? 'professional';
    final selectedVoice = AnnouncerVoice.values.firstWhere(
      (v) => v.name == styleStr,
      orElse: () => AnnouncerVoice.professional,
    );

    // Load system voice
    final systemVoice = await AppSettings.getSystemVoice() ?? '';

    // Load ResponsiveVoice
    final responsiveVoice = await AppSettings.getResponsiveVoice() ?? 'Australian Female';

    // Load playback rate (default 1.0)
    final playbackRate = await AppSettings.getVoicePlaybackRate();

    setState(() {
      _voiceEngine = voiceEngine;
      _selectedVoice = selectedVoice;
      _selectedSystemVoice = systemVoice;
      _selectedResponsiveVoice = responsiveVoice;
      _playbackRate = playbackRate.clamp(0.7, 1.5);
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
      await AppSettings.saveVoiceEngine(_voiceEngine.name);
      await AppSettings.saveAnnouncerStyle(_selectedVoice.name);
      await AppSettings.saveSystemVoice(_selectedSystemVoice);
      await AppSettings.saveResponsiveVoice(_selectedResponsiveVoice);
      await AppSettings.saveVoicePlaybackRate(_playbackRate);

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
    widget.announcer.setPlaybackRate(_playbackRate);
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

        // Live phase label for the progress dialog. addMusicFile runs
        // base64Encode synchronously and then POSTs the whole payload
        // — the two phases can't be observed granularly without
        // refactoring the service, so we swap labels around the
        // await boundary to at least signal "still working".
        final phaseLabel = ValueNotifier<String>('Preparing file…');
        _showMusicUploadProgress(
          fileName: fileName,
          fileSizeBytes: fileSize,
          phaseLabel: phaseLabel,
        );

        try {
          phaseLabel.value = 'Uploading to server…';
          debugPrint('Adding music file...');
          final musicService = VictoryMusicService();
          await musicService.addMusicFile(
            fileName: fileName,
            filePath: kIsWeb ? null : file.path, // path not available on web
            fileBytes: file.bytes,
          );

          debugPrint('Music file added, reloading list...');
          phaseLabel.value = 'Refreshing library…';
          // Reload the files list
          final files = await musicService.getMusicFiles();

          setState(() {
            _victoryMusicFiles = files;
          });
        } finally {
          if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          phaseLabel.dispose();
        }

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

  /// Shows a non-dismissible progress modal while a music file is
  /// uploading. The API doesn't expose byte-level progress (single
  /// POST with a base64 payload), so the dialog uses an indeterminate
  /// linear progress bar plus a live phase label to signal "still
  /// working" — important on the kiosk where WAV files can take
  /// 10-30s to encode + upload on port 80 with no feedback otherwise.
  void _showMusicUploadProgress({
    required String fileName,
    required int fileSizeBytes,
    required ValueNotifier<String> phaseLabel,
  }) {
    final sizeMb = fileSizeBytes / (1024 * 1024);
    final sizeText = sizeMb >= 1
        ? '${sizeMb.toStringAsFixed(1)} MB'
        : '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';

    // Not awaited — the caller pops it explicitly in a finally so
    // errors don't leave a stuck modal on screen. Uses the root
    // navigator so subsequent pushDialog calls (e.g. error dialogs)
    // don't stack under a still-mounted SnackBar.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Uploading Music'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sizeText,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: phaseLabel,
                  builder: (_, label, __) => Text(
                    label,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Large files can take a few seconds. Please wait.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _handleAddPlayer() async {
    // The dialog handles savePlayer inside onSubmit, showing its own
    // progress indicator while the roundtrip is in flight. We only get
    // the returned Player back after it has already been persisted.
    final playerProvider = context.read<PlayerProvider>();
    final player = await showAddPlayerDialog(
      context: context,
      config: AddPlayerDialogConfig.optionsScreen(context),
      onSubmit: playerProvider.savePlayer,
    );

    if (player != null && mounted) {
      // Non-blocking hint if the server-side face-landmark detection
      // couldn't find a face in the just-uploaded photo. Photo is still
      // saved; hint tells the operator to retake or re-detect.
      showFaceLandmarksHintIfAny(context);

      // Show success snackbar (Options screen only)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player "${player.name}" added'),
          backgroundColor: Colors.green,
        ),
      );

      // Scroll to show the new player after dialog closes
      _scrollToNewPlayer();
    }
  }

  void _scrollToNewPlayer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Use post-frame callback to ensure layout is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _playersListScrollController.hasClients) {
            // Add buffer to ensure full tile is visible
            final targetPosition = _playersListScrollController.position.maxScrollExtent + 150;
            _playersListScrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  void _showEditPlayerDialog(BuildContext context, Player player) {
    final nameController = TextEditingController(text: player.name);
    String? photoPath = player.photoPath;
    bool showError = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo preview section
                if (photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: kIsWeb
                              ? NetworkImage(photoPath!)
                              : FileImage(File(photoPath!)) as ImageProvider,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setDialogState(() {
                                photoPath = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    border: const OutlineInputBorder(),
                    errorText: showError ? 'Please enter a player name' : null,
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    if (showError && value.trim().isNotEmpty) {
                      setDialogState(() {
                        showError = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Photo (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path =
                            await _photoService.takePhoto(context: context);
                        if (path != null) {
                          setDialogState(() {
                            photoPath = path;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path = await _photoService.selectFromGallery();
                        if (path != null) {
                          setDialogState(() {
                            photoPath = path;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  setDialogState(() {
                    showError = true;
                  });
                  return;
                }

                final updatedPlayer = player.copyWith(
                  name: nameController.text.trim(),
                  photoPath: photoPath,
                );

                final playerProvider = context.read<PlayerProvider>();
                await playerProvider.savePlayer(updatedPlayer);

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  // Non-blocking face-landmarks hint (only fires when
                  // detection ran and failed on the just-uploaded photo).
                  showFaceLandmarksHintIfAny(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Player "${updatedPlayer.name}" updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  /// Kiosk-friendly diagnostic for the mediapipe sidecar. Hits the
  /// server's `/api/v1/players/face-landmarks/diagnostics` route and
  /// renders the report in a dialog so the operator can see why
  /// Re-detect is failing (python missing, sidecar not on disk, or
  /// mediapipe not importable for the service account) without
  /// spelunking the WinSW service log.
  Future<void> _runFaceLandmarksDiagnostics() async {
    if (!mounted) return;
    // Loading dialog while the server probes python + imports mediapipe
    // (can take a few seconds cold).
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Diagnosing face landmarks…'),
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    Map<String, dynamic>? report;
    String? fetchError;
    try {
      report = await apiClient.faceLandmarksDiagnostics();
    } catch (e) {
      fetchError = e.toString();
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // close loader

    final buffer = StringBuffer();
    Widget statusIcon;
    String headline;

    if (fetchError != null) {
      headline = 'Could not reach server';
      statusIcon = const Icon(Icons.error, color: Colors.red, size: 32);
      buffer.writeln(fetchError);
    } else if (report == null) {
      headline = 'No report returned';
      statusIcon = const Icon(Icons.error, color: Colors.red, size: 32);
    } else {
      final pythonFound = report['pythonFound'] == true;
      final sidecarFound = report['sidecarFound'] == true;
      final mediapipeOk = report['mediapipeOk'] == true;

      if (pythonFound && sidecarFound && mediapipeOk) {
        headline = 'Face landmarks pipeline OK';
        statusIcon = const Icon(Icons.check_circle,
            color: Colors.green, size: 32);
      } else {
        headline = 'Face landmarks NOT ready';
        statusIcon = const Icon(Icons.warning, color: Colors.orange, size: 32);
      }

      String yn(bool b) => b ? '✓' : '✗';
      buffer.writeln('${yn(pythonFound)} Python interpreter');
      buffer.writeln(
          '    ${report['pythonCommand'] ?? "not found"}');
      final envOverride = report['envOverride'];
      if (envOverride != null && envOverride.toString().isNotEmpty) {
        buffer.writeln('    (from DART_GAMES_PYTHON env var)');
      }
      buffer.writeln('');
      buffer.writeln('${yn(sidecarFound)} Sidecar script');
      buffer.writeln(
          '    ${report['sidecarPath'] ?? "not found"}');
      buffer.writeln('');
      buffer.writeln('${yn(mediapipeOk)} mediapipe importable');
      if (mediapipeOk) {
        buffer.writeln(
            '    version ${report['mediapipeVersion'] ?? "unknown"}');
      } else if (report['mediapipeError'] != null) {
        buffer.writeln('    ${report['mediapipeError']}');
      }
      buffer.writeln('');
      buffer.writeln('Server working dir:');
      buffer.writeln('    ${report['workingDirectory']}');
      buffer.writeln('Server script:');
      buffer.writeln('    ${report['scriptPath']}');
      buffer.writeln('Platform:');
      buffer.writeln('    ${report['platform']}');
    }

    final text = buffer.toString();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            statusIcon,
            const SizedBox(width: 12),
            Expanded(child: Text(headline)),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!dialogCtx.mounted) return;
              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Collect every loaded test-player's current face landmarks into the
  /// `headshot-NN.png → landmarks` JSON shape, then show a copyable dialog
  /// the user can paste into `assets/common/test_headshot_landmarks.json`.
  ///
  /// The match is by display name against [TestDataService.generateTestPlayers];
  /// players with no stored landmarks are silently skipped.
  Future<void> _exportTestHeadshotLandmarkOverrides() async {
    final playerProvider = context.read<PlayerProvider>();
    final overrides = TestHeadshotLandmarksService.buildExportPayload(
      playerProvider.allPlayers,
    );

    if (overrides.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No test-data players with stored landmarks were found. '
              'Load Test Data, then correct landmarks via the face-mapping '
              'icon next to each player.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Pretty-print so the committed JSON diffs cleanly.
    final encoder = const JsonEncoder.withIndent('  ');
    final pretty = encoder.convert(overrides);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Landmark overrides for ${overrides.length}/20 test players'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this JSON and replace the contents of '
                'assets/common/test_headshot_landmarks.json, then commit. '
                'Future Load Test Data runs will apply these corrections '
                'automatically.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      pretty,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to clipboard'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pretty));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Copied. Paste into '
                        'assets/common/test_headshot_landmarks.json'),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Resolve the player's photo to an absolute URL the inspector's
  /// Image.network can load. The server stores `photoPath` as the relative
  /// API endpoint `/api/v1/players/<id>/photo`; ApiConfig knows the host.
  String _photoUrlForInspector(Player player) {
    final path = player.photoPath ?? '';
    if (path.startsWith('http')) return path;
    return ApiConfig.url(path);
  }

  void _showFaceLandmarkInspector(BuildContext context, Player player) {
    final playerProvider = context.read<PlayerProvider>();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FaceLandmarkInspector(
        player: player,
        photoUrl: _photoUrlForInspector(player),
        onSave: (landmarks) =>
            playerProvider.updateFaceLandmarks(player.id, landmarks),
        onRedetect: () =>
            playerProvider.redetectFaceLandmarks(player.id),
      ),
    );
  }

  Future<void> _deletePlayer(BuildContext context, Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text(
          'Are you sure you want to delete "${player.name}"? This will remove all their game history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.deletePlayer(player.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player "${player.name}" deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildUserManagementSection() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final players = playerProvider.allPlayers;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Players',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (players.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${players.length} player${players.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (players.isEmpty)
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
                            'No players yet. Click "Add Player" below to get started.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      controller: _playersListScrollController,
                      shrinkWrap: true,
                      itemCount: players.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return _buildPlayerListTile(player, playerProvider);
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                // Add Player button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleAddPlayer,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Player'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerListTile(Player player, PlayerProvider playerProvider) {
    return ExpansionTile(
      // Using the shared PlayerAvatarWidget (single source of truth for
      // photo rendering — handles data URLs, server-served HTTP URLs,
      // and mobile filesystem paths via the same code path PlayerSelectionCard
      // uses in every game's player list). Size 20 matches the previous
      // CircleAvatar(radius: 20, ...) shape.
      leading: PlayerAvatarWidget(player: player, size: 20.0),
      title: Text(
        player.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${player.gamesWon} wins • ${player.gamesPlayed} games',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.photoPath != null)
            IconButton(
              icon: const Icon(Icons.face_retouching_natural, size: 20),
              tooltip: 'Inspect / edit face mapping',
              onPressed: () => _showFaceLandmarkInspector(context, player),
            ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit player',
            onPressed: () => _showEditPlayerDialog(context, player),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            tooltip: 'Delete player',
            color: Colors.red,
            onPressed: () => _deletePlayer(context, player),
          ),
          const Icon(Icons.expand_more),
        ],
      ),
      children: [
        _buildPlayerDetails(player, playerProvider),
      ],
    );
  }

  Widget _buildPlayerDetails(Player player, PlayerProvider playerProvider) {
    final history = player.gameHistory;
    final totalPlayTime = playerProvider.getPlayerTotalPlayTime(player.id);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All stats in a single row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.emoji_events,
                label: 'Wins',
                value: player.gamesWon.toString(),
                color: Colors.amber,
              ),
              _buildStatCard(
                icon: Icons.games,
                label: 'Games played',
                value: player.gamesPlayed.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.groups,
                label: 'Total players',
                value: playerProvider.getPlayerTotalPlayersEncountered(player.id).toString(),
                color: Colors.teal,
              ),
              _buildStatCard(
                icon: Icons.loop,
                label: 'Turns (legs)',
                value: playerProvider.getPlayerTotalTurns(player.id).toString(),
                color: Colors.purple,
              ),
              _buildStatCard(
                icon: Icons.adjust,
                label: 'Darts thrown',
                value: playerProvider.getPlayerTotalDartsThrown(player.id).toString(),
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.timer,
                label: 'Total time',
                value: _formatDuration(totalPlayTime),
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Game history
          Text(
            'Recent Games (${history.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No games yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...history.take(5).map((entry) {
              final isWin = entry.metadata?['won'] == true;
              return ListTile(
                dense: true,
                leading: isWin
                    ? const Icon(Icons.emoji_events, size: 16, color: Colors.amber)
                    : const Icon(Icons.sports_esports, size: 16, color: Colors.grey),
                title: Row(
                  children: [
                    Text(
                      entry.gameName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total players: ${entry.playerCount ?? 0} • Turns (legs): ${entry.turns ?? 0} • Darts thrown: ${entry.dartThrows ?? 0} • Total time: ${_formatDuration(entry.duration)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _formatHistoryDate(entry.timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }).toList(),
          if (history.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'and ${history.length - 5} more...',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hours = diff.inHours;
      if (hours == 0) {
        final minutes = diff.inMinutes;
        return '$minutes min ago';
      }
      return '$hours hr ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildNavigationMenu(ThemeData theme) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavItem(
                  theme: theme,
                  icon: Icons.campaign,
                  label: 'Game Announcer',
                  sectionKey: 'announcer',
                  onTap: () => _scrollToSection(_announcerKey),
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  theme: theme,
                  icon: Icons.music_note,
                  label: 'Celebration Music',
                  sectionKey: 'music',
                  onTap: () => _scrollToSection(_musicKey),
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  theme: theme,
                  icon: Icons.people,
                  label: 'User Management',
                  sectionKey: 'userManagement',
                  onTap: () => _scrollToSection(_userManagementKey),
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  theme: theme,
                  icon: Icons.admin_panel_settings,
                  label: 'Admin',
                  sectionKey: 'admin',
                  onTap: () => _scrollToSection(_adminKey),
                ),
              ],
            ),
          ),
          // Build identifier — injected via --dart-define=BUILD_NUMBER
          // from build.bat / build.sh wrappers. Falls back to 'dev'
          // when launched directly with `flutter run`.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Build ${BuildInfo.number}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String sectionKey,
    required VoidCallback onTap,
  }) {
    final isActive = _activeSection == sectionKey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Load test players with game history
  Future<void> _loadTestData() async {
    final playerProvider = context.read<PlayerProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Load Test Data'),
          content: const Text(
            'This will add:\n'
            '• 20 sample players with varied game history\n'
            '• 20 sample headshots (1 per player) — each runs through '
            'the face-landmarks detector on upload\n'
            '• 2 sample victory music files\n\n'
            'These will be added to your existing data.',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Load test data'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Generate inputs upfront so the progress dialog can show accurate
    // totals from the very first frame.
    final testPlayers = TestDataService.generateTestPlayers();
    final headshotPaths = TestDataService.getTestHeadshotAssetPaths();
    final testMusicDataUrls = TestDataService.getTestVictoryMusicDataUrls();
    final musicService = VictoryMusicService();

    // ── Progress tracker ────────────────────────────────────────────────
    // Drives the modal status indicator below. Each phase pushes a new
    // record with phase metadata + within-phase counters so the user sees
    // both the current step's label and "X of Y" progress.
    const int totalPhases = 5;
    final progress = ValueNotifier<({
      int phase,
      String phaseLabel,
      int done,
      int total,
    })>((
      phase: 1,
      phaseLabel: 'Saving players',
      done: 0,
      total: testPlayers.length,
    ));
    void setProgress(int phase, String label, int done, int total) {
      progress.value =
          (phase: phase, phaseLabel: label, done: done, total: total);
    }

    // Non-dismissible status dialog. Not awaited — we pop it manually
    // once all phases finish (in the finally block so errors don't
    // leave a stuck modal on screen).
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Loading Test Data'),
          content: ValueListenableBuilder<({
            int phase,
            String phaseLabel,
            int done,
            int total,
          })>(
            valueListenable: progress,
            builder: (_, p, __) {
              final pct = p.total > 0 ? p.done / p.total : 0.0;
              return SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${p.phase} of $totalPhases',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.phaseLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: pct),
                    const SizedBox(height: 6),
                    Text('${p.done} of ${p.total}'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    int photosAdded = 0;
    int landmarkOverridesApplied = 0;
    int filesAdded = 0;
    // Track per-player face-landmark detection failures so the completion
    // dialog can list them and offer a Retry button. Also feeds the
    // "detection is broken globally" warning path via the preflight ping.
    final failedDetections = <_LoaderDetectionFailure>[];
    bool sidecarBrokenAcknowledged = false;

    try {
      // ── Phase 1: Save players ────────────────────────────────────────
      for (var i = 0; i < testPlayers.length; i++) {
        await playerProvider.savePlayer(testPlayers[i]);
        setProgress(1, 'Saving players', i + 1, testPlayers.length);
      }

      // ── Phase 2: Upload headshots ────────────────────────────────────
      // Each upload hits POST /api/v1/players/<id>/photo, which the
      // server now runs face-landmarks detection on synchronously (per
      // the recent sidecar sync change). Two behaviors worth knowing:
      //   * Detection failures come back as HTTP 200 with a
      //     `faceLandmarksError` field on the response — NOT as thrown
      //     exceptions. We accumulate those into failedDetections so
      //     the completion dialog can list them and offer a Retry
      //     button. HTTP / network errors still throw and are caught
      //     per-photo below just like before.
      //   * We preflight the sidecar via GET /face-landmarks/diagnostics
      //     to detect a globally-broken interpreter (missing Python,
      //     mediapipe not importable, sidecar script missing, etc.).
      //     When broken we prompt once, then batch-flip every upload to
      //     detectLandmarks:false so we don't hammer a doomed sidecar
      //     20 times just to accumulate the same failure.
      setProgress(2, 'Checking face detection', 0, 1);
      Map<String, dynamic>? diag;
      try {
        diag = await apiClient.faceLandmarksDiagnostics();
      } catch (e) {
        debugPrint(
            'Face-landmarks diagnostics ping failed (proceeding anyway): $e');
      }
      final sidecarBroken = diag != null &&
          (diag['pythonFound'] != true ||
              diag['sidecarFound'] != true ||
              diag['mediapipeOk'] != true);
      if (sidecarBroken) {
        if (!mounted) return;
        final proceed = await _showSidecarBrokenDialog(diag);
        if (proceed != true) {
          // User chose Cancel — abort the whole load. The finally
          // block below will close the progress dialog.
          return;
        }
        sidecarBrokenAcknowledged = true;
      }

      // Pre-load the bundled override map once. Empty by default;
      // populated via the Export action and committed to assets/common/.
      final overrides =
          await TestHeadshotLandmarksService.loadOverrides();

      setProgress(2, 'Uploading headshots', 0, testPlayers.length);
      final photoCount = testPlayers.length < headshotPaths.length
          ? testPlayers.length
          : headshotPaths.length;
      final photoIndices = List<int>.generate(photoCount, (i) => i);
      // Concurrent uploads (limit 4). Cold-start MediaPipe dominates
      // the first call; subsequent ones are ~1s each with a warm
      // interpreter, so 4 in flight amortizes wall-clock cleanly
      // without saturating the sidecar's per-process spawn budget.
      await runConcurrent<int>(
        photoIndices,
        limit: 4,
        onProgress: (done) =>
            setProgress(2, 'Uploading headshots', done, testPlayers.length),
        worker: (i, _) async {
          final player = testPlayers[i];
          final assetPath = headshotPaths[i];
          try {
            final bytes =
                (await rootBundle.load(assetPath)).buffer.asUint8List();
            final base64Data = base64Encode(bytes);
            final fileName = assetPath.split('/').last;
            // If we have a saved override OR the sidecar is broken,
            // skip the server-side mediapipe job. Overrides are the
            // authoritative-write case; a broken sidecar just wastes
            // wall-clock racing the same failure 20 times.
            final override = overrides[fileName];
            final hasOverride = override != null;
            final skipDetection = hasOverride || sidecarBrokenAcknowledged;
            final result = await apiClient.uploadPlayerPhoto(
              player.id,
              base64Data,
              fileName,
              detectLandmarks: !skipDetection,
            );
            photosAdded++;

            // Track per-photo detection failure (only when detection
            // actually ran). The sidecar-broken case is already
            // surfaced globally by the preflight dialog — we don't
            // spam it 20 more times here.
            if (!skipDetection && result.faceLandmarksError != null) {
              failedDetections.add(_LoaderDetectionFailure(
                playerId: player.id,
                playerName: player.name,
                errorReason: result.faceLandmarksError!,
              ));
            }

            // Apply the manual correction now. With mediapipe suppressed
            // above, this is the authoritative write — nothing else will
            // touch face_landmarks for this player.
            if (hasOverride) {
              try {
                await playerProvider.updateFaceLandmarks(
                    player.id, override);
                landmarkOverridesApplied++;
              } catch (e) {
                debugPrint(
                    'Error applying landmark override for ${player.name}: $e');
              }
            }
          } catch (e) {
            debugPrint(
                'Error uploading test headshot $assetPath for ${player.name}: $e');
          }
        },
      );

      // ── Phase 3: Seed game history ───────────────────────────────────
      // Persist each player's pre-populated gameHistory to the server so
      // games_played and games_won accumulate correctly. Without this,
      // the stats only live in PlayerProvider's local cache until any
      // subsequent loadPlayers() (e.g., navigating to a game menu)
      // wipes them.
      setProgress(
          3, 'Seeding game history', 0, testPlayers.length);
      for (var i = 0; i < testPlayers.length; i++) {
        await playerProvider.seedPlayerHistory(
            testPlayers[i].id, testPlayers[i].gameHistory);
        setProgress(
            3, 'Seeding game history', i + 1, testPlayers.length);
      }

      // ── Phase 4: Add victory music files ─────────────────────────────
      setProgress(
          4, 'Adding music files', 0, testMusicDataUrls.length);
      for (var i = 0; i < testMusicDataUrls.length; i++) {
        final musicData = testMusicDataUrls[i];
        try {
          await musicService.addMusicFile(
            fileName: musicData['name']!,
            dataUrl: musicData['dataUrl']!,
          );
          filesAdded++;
        } catch (e) {
          debugPrint(
              'Error loading test music file ${musicData['name']}: $e');
        }
        setProgress(
            4, 'Adding music files', i + 1, testMusicDataUrls.length);
      }

      // ── Phase 5: Refresh local caches ────────────────────────────────
      // Refresh local cache from the server so optimistic local stats
      // match the persisted state, then refresh victory music list.
      setProgress(5, 'Refreshing data', 0, 2);
      await playerProvider.loadPlayers();
      setProgress(5, 'Refreshing data', 1, 2);
      final files = await musicService.getMusicFiles();
      if (mounted) {
        setState(() {
          _victoryMusicFiles = files;
        });
      }
      setProgress(5, 'Refreshing data', 2, 2);
    } finally {
      // Always close the progress dialog, even if a phase threw, so the
      // user can never be left looking at a stuck modal.
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return;
    // Completion UI branches on whether ANY detection failure needs
    // operator attention. Zero failures → keep the light-touch green
    // snackbar. One or more → open a dialog listing them with a
    // Retry button so the operator doesn't have to open each player
    // and hit Re-detect manually. Sidecar-broken failures are already
    // acknowledged in the preflight dialog so we DON'T re-list them
    // here (retry would just fail again against the same broken
    // sidecar).
    if (failedDetections.isEmpty || sidecarBrokenAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Loaded ${testPlayers.length} players, '
              '$photosAdded headshots'
              '${landmarkOverridesApplied > 0 ? " ($landmarkOverridesApplied with saved landmark overrides)" : ""}'
              '${sidecarBrokenAcknowledged ? " (face detection was skipped — see the warning above)" : ""}'
              ', and $filesAdded music files'),
          backgroundColor: sidecarBrokenAcknowledged
              ? Colors.orange
              : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      await _showLoaderCompletionDialog(
        totalPlayers: testPlayers.length,
        photosAdded: photosAdded,
        landmarkOverridesApplied: landmarkOverridesApplied,
        filesAdded: filesAdded,
        failedDetections: failedDetections,
        playerProvider: playerProvider,
      );
    }
  }

  /// Whether the last diagnostics probe indicates the sidecar is
  /// unhealthy enough that detection will fail for every incoming
  /// upload. Null means "no probe result yet" (banner stays hidden).
  bool _isSidecarBroken(Map<String, dynamic>? diag) {
    if (diag == null) return false;
    return diag['pythonFound'] != true ||
        diag['sidecarFound'] != true ||
        diag['mediapipeOk'] != true;
  }

  /// Persistent orange warning banner shown at the top of the Options
  /// screen body when [_faceLandmarksDiagnostics] indicates a broken
  /// sidecar. Includes a "Diagnose" button that opens the same
  /// diagnostics dialog the admin section uses (via
  /// [_runFaceLandmarksDiagnostics]) so the operator can see the
  /// exact failure and copy details out.
  Widget _buildSidecarWarningBanner(ThemeData theme) {
    final diag = _faceLandmarksDiagnostics;
    if (diag == null) return const SizedBox.shrink();

    final reasons = <String>[];
    if (diag['pythonFound'] != true) reasons.add('Python not found');
    if (diag['sidecarFound'] != true) reasons.add('sidecar script missing');
    if (diag['mediapipeOk'] != true) reasons.add('mediapipe not importable');
    final reasonLine =
        reasons.isEmpty ? 'unknown state' : reasons.join(' + ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face-landmarks detection is offline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: $reasonLine. New player photos will save but '
                  'themed avatars (hats, glasses, mustaches) will sit '
                  'in heuristic positions until an admin fixes the '
                  'sidecar. See docs/deployment/kiosk-setup.md.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _runFaceLandmarksDiagnostics,
            icon: const Icon(Icons.info_outline),
            label: const Text('Diagnose'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Modal shown before Phase 2 starts when the face-landmark
  /// sidecar's diagnostics come back with Python / mediapipe /
  /// sidecar-script problems. Returns `true` if the operator chose
  /// "Load anyway (skip detection)" — the loader then flips every
  /// upload to `detectLandmarks:false`. Returns `false` (or `null`)
  /// to cancel the whole load.
  Future<bool?> _showSidecarBrokenDialog(Map<String, dynamic> diag) {
    final lines = <String>[];
    if (diag['pythonFound'] != true) {
      lines.add(
          '• Python interpreter not found (env DART_GAMES_PYTHON or PATH probe).');
    }
    if (diag['sidecarFound'] != true) {
      lines.add(
          '• Sidecar script not found next to server/ (python/mediapipe_sidecar.py).');
    }
    if (diag['mediapipeOk'] != true) {
      final err = diag['mediapipeError'];
      lines.add(
          '• MediaPipe not importable' + (err != null ? ': $err' : '.'));
    }
    if (diag['taskModelFound'] == false && diag['sidecarFound'] == true) {
      lines.add(
          '• face_landmarker.task missing next to sidecar — Haar '
          'fallback would run instead of MediaPipe (less accurate).');
    }
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
        title: const Text('Face detection is offline'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The face-landmarks sidecar reported problems that '
                'would make every test-player photo fail detection. '
                'Loading is possible without detection, but themed '
                'avatars (pirate hats, glasses, mustaches, etc.) will '
                'sit in heuristic positions until an admin fixes the '
                'sidecar and each player is Re-detected.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Diagnostics reported:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...lines.map((l) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l),
                  )),
              const SizedBox(height: 12),
              const Text(
                'Fix path: run check_python_deps.bat, then '
                'install_service.bat. See docs/deployment/kiosk-setup.md.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Load anyway (skip detection)'),
          ),
        ],
      ),
    );
  }

  /// Completion dialog shown when Phase 2 finished with per-photo
  /// detection failures the operator can retry. Lists each failed
  /// player and offers a Retry button that calls
  /// [PlayerProvider.redetectFaceLandmarks] once per failed player,
  /// then rebuilds the list to reflect remaining failures.
  Future<void> _showLoaderCompletionDialog({
    required int totalPlayers,
    required int photosAdded,
    required int landmarkOverridesApplied,
    required int filesAdded,
    required List<_LoaderDetectionFailure> failedDetections,
    required PlayerProvider playerProvider,
  }) async {
    final remaining = List<_LoaderDetectionFailure>.from(failedDetections);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          var retrying = false;
          Future<void> retry() async {
            setDialog(() => retrying = true);
            final stillFailing = <_LoaderDetectionFailure>[];
            for (final failure in remaining) {
              try {
                await playerProvider.redetectFaceLandmarks(failure.playerId);
                // Success — do NOT add to stillFailing.
              } catch (e) {
                // The redetect API throws FaceLandmarksException on the
                // sidecar's error reason (503 with the reason string in
                // the body). Any other exception (network, 404) is also
                // captured as-is.
                stillFailing.add(_LoaderDetectionFailure(
                  playerId: failure.playerId,
                  playerName: failure.playerName,
                  errorReason: e.toString(),
                ));
              }
            }
            setDialog(() {
              remaining
                ..clear()
                ..addAll(stillFailing);
              retrying = false;
            });
          }

          return AlertDialog(
            icon: Icon(
              remaining.isEmpty ? Icons.check_circle : Icons.warning_amber,
              color: remaining.isEmpty ? Colors.green : Colors.orange,
              size: 40,
            ),
            title: Text(
              remaining.isEmpty
                  ? 'All players loaded'
                  : 'Loaded with detection warnings',
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalPlayers players, $photosAdded headshots'
                    '${landmarkOverridesApplied > 0 ? " ($landmarkOverridesApplied with saved overrides)" : ""}'
                    ', $filesAdded music files.',
                  ),
                  const SizedBox(height: 12),
                  if (remaining.isNotEmpty) ...[
                    Text(
                      '${remaining.length} of $totalPlayers headshots did not '
                      'produce landmarks:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...remaining.map((f) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• ${f.playerName} — ${_shortReason(f.errorReason)}',
                          ),
                        )),
                    const SizedBox(height: 12),
                    const Text(
                      'Retry re-runs detection on each failed photo. If '
                      'the sidecar is unhealthy, retries will fail with '
                      'the same reason.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (remaining.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: retrying ? null : retry,
                  icon: retrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(retrying ? 'Retrying…' : 'Retry failed'),
                ),
              TextButton(
                onPressed: retrying ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Trim the sidecar reason string to one short line for display in
  /// the completion dialog's failure list.
  String _shortReason(String reason) {
    final firstLine = reason.split('\n').first.trim();
    if (firstLine.length <= 90) return firstLine;
    return '${firstLine.substring(0, 87)}…';
  }

  /// Clear all players, game history, and victory music
  Future<void> _clearAllData() async {
    final playerProvider = context.read<PlayerProvider>();

    // Show warning dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Clear All Data'),
            ],
          ),
          content: Text(TestDataService.getClearAllDataWarning()),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Delete all players (game_history rows cascade via FK ON DELETE CASCADE)
    final allPlayers = playerProvider.allPlayers;
    for (final player in allPlayers) {
      await playerProvider.deletePlayer(player.id);
    }

    // Bulk-delete the orphan tables that DON'T cascade from players:
    //   - failed_stats: no FK constraint (rows persist after player delete).
    //   - saved_games: stores player NAMES (not ids), unrelated to players table.
    // Without these calls, "Clear All Data" leaves orphan rows behind that
    // re-surface in the Resume modal and the failed-stats inspection UI.
    await playerProvider.deleteAllFailedStats();
    await playerProvider.deleteAllSavedGames();

    // Delete all victory music files
    final musicService = VictoryMusicService();
    final allMusicFiles = await musicService.getMusicFiles();
    for (final musicFile in allMusicFiles) {
      await musicService.removeMusicFile(musicFile.id);
    }

    // Reload victory music in UI
    final files = await musicService.getMusicFiles();
    setState(() {
      _victoryMusicFiles = files;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ All data deleted'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF44336), // Red
                Color(0xFFFFC107), // Amber
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 32,
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const Text('System Settings'),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DartboardConnectionInfo(
              config: DartboardConnectionInfoConfig.homeScreen(),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildNavigationMenu(theme),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Persistent banner if the face-landmark sidecar is
                  // broken. Populated in initState via a background
                  // diagnostics probe. Kept above all sections so the
                  // operator can't miss a broken-detection state — a
                  // few games depend on this feature (Treasure Divide
                  // pirate hats, Monster Mash overlays) and the
                  // symptom (avatars sit wrong) is otherwise silent.
                  if (_isSidecarBroken(_faceLandmarksDiagnostics))
                    _buildSidecarWarningBanner(theme),
                  // Announcer Setup Section
                  Container(
                    key: _announcerKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Announcer Setup',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            const SizedBox(height: 8),
            Text(
              'Configure the voice used by the announcer for game notifications and updates.',
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

            // Playback Rate (applies to BOTH engines). 1.0 = normal speed.
            // Range 0.7 – 1.5 in 0.05 steps. Persisted as
            // voice_playback_rate via AppSettings. Applied immediately on
            // change so the user hears the new rate from the next Test
            // Voice press without needing to Save first.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed),
                        const SizedBox(width: 8),
                        Text(
                          'Playback Speed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_playbackRate.toStringAsFixed(2)}×',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _playbackRate,
                      min: 0.7,
                      max: 1.5,
                      divisions: 16, // 0.05 steps
                      label: '${_playbackRate.toStringAsFixed(2)}×',
                      onChanged: (value) {
                        setState(() => _playbackRate = value);
                        _applySettings();
                      },
                    ),
                    // Labels under the slider. "1.0× normal" is positioned
                    // proportionally — at 37.5% across the 0.7-1.5 range —
                    // not at the visual midpoint of the bar. Using
                    // Alignment(2 * fraction - 1, 0): fraction = (1.0 -
                    // 0.7) / (1.5 - 0.7) = 0.375 → alignment.x = -0.25.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        height: 16,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('0.7× slower',
                                  style: theme.textTheme.bodySmall),
                            ),
                            Align(
                              alignment: const Alignment(-0.25, 0),
                              child: Text('1.0× normal',
                                  style: theme.textTheme.bodySmall),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('1.5× faster',
                                  style: theme.textTheme.bodySmall),
                            ),
                          ],
                        ),
                      ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Victory Music Section
                  Container(
                    key: _musicKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Celebration Music',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            const SizedBox(height: 8),
            Text(
              'Select the music you would like to be played when a player wins a game. If you select multiple files the order they are used will be randomized to keep things exciting.',
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
                          'List of celebration music files',
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
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // User Management Section
                  Container(
                    key: _userManagementKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            const SizedBox(height: 8),
            Text(
              'Manage players and view game statistics. Players will be available for use in all the dart games.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildUserManagementSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Admin Section
                  Container(
                    key: _adminKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Options',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Advanced settings and tools for testing and development.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.computer),
                            title: const Text('Scolia 2 Dartboard Emulator'),
                            subtitle: const Text('Test the Scolia 2 dartboard emulator functions and API calls'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TestDartboardScreen(announcer: widget.announcer),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.science, color: Colors.blue),
                            title: const Text('Load Test Data'),
                            subtitle: const Text('Add 20 sample players and 2 victory music files for testing'),
                            trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                            onTap: _loadTestData,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.file_download,
                                color: Colors.indigo),
                            title: const Text(
                                'Export test-data landmark overrides'),
                            subtitle: const Text(
                                'Saves your manual face-mapping corrections '
                                'for the test players. Drop the JSON into '
                                'assets/common/test_headshot_landmarks.json '
                                'and commit to bake them in.'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _exportTestHeadshotLandmarkOverrides,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.health_and_safety,
                                color: Colors.deepPurple),
                            title: const Text('Diagnose face landmarks'),
                            subtitle: const Text(
                                'Checks whether the mediapipe sidecar is '
                                'reachable from the server: python found, '
                                'sidecar script located, mediapipe importable. '
                                'Use this when "Re-detect" fails on a kiosk.'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _runFaceLandmarksDiagnostics,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.delete_forever, color: Colors.red),
                            title: const Text('Clear All Data'),
                            subtitle: const Text('Delete all players, game history, and victory music'),
                            trailing: const Icon(Icons.warning_amber, color: Colors.red),
                            onTap: _clearAllData,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<DartboardProvider>(
                          builder: (context, dartboardProvider, child) {
                            final hasRealConnection = dartboardProvider.isConnected && !dartboardProvider.isEmulator;
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.receipt_long, color: hasRealConnection ? Colors.teal : Colors.grey),
                                title: Text(
                                  'Log Dartboard API Calls',
                                  style: TextStyle(color: hasRealConnection ? null : Colors.grey),
                                ),
                                subtitle: Text(
                                  hasRealConnection
                                      ? 'Log all dartboard API communications to a file'
                                      : 'Requires a real dartboard connection (not emulator)',
                                  style: TextStyle(color: hasRealConnection ? null : Colors.grey),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: hasRealConnection ? Colors.teal : Colors.grey),
                                enabled: hasRealConnection,
                                onTap: hasRealConnection
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const ApiLoggerScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single test-player photo whose upload succeeded but whose face
/// landmarks detection failed. Used by the loader completion dialog to
/// list the affected players and let the operator retry them all with
/// one tap. Not exported — internal to [OptionsScreenState].
class _LoaderDetectionFailure {
  final String playerId;
  final String playerName;
  final String errorReason;

  const _LoaderDetectionFailure({
    required this.playerId,
    required this.playerName,
    required this.errorReason,
  });
}
