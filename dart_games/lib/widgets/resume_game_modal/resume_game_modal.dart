import 'package:flutter/material.dart';
import '../../constants/test_keys.dart';
import '../../models/saved_game_metadata.dart';
import '../../services/save_game_service.dart';
import '../../services/api/api_client.dart';
import 'resume_game_modal_config.dart';

export 'resume_game_modal_config.dart';

class ResumeGameModal extends StatefulWidget {
  final ResumeGameModalConfig config;
  final String gameType;
  final VoidCallback onStartNewGame;
  final void Function(SavedGameMetadata savedGame) onResumeGame;
  final VoidCallback onClose;
  final ApiClient? apiClient;

  const ResumeGameModal({
    super.key,
    required this.config,
    required this.gameType,
    required this.onStartNewGame,
    required this.onResumeGame,
    required this.onClose,
    this.apiClient,
  });

  @override
  State<ResumeGameModal> createState() => _ResumeGameModalState();
}

class _ResumeGameModalState extends State<ResumeGameModal> {
  List<SavedGameMetadata> _savedGames = [];
  String? _selectedGameId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  Future<void> _loadSavedGames() async {
    final games = await SaveGameService(widget.apiClient).loadSavedGames(widget.gameType);
    if (mounted) {
      setState(() {
        _savedGames = games;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGame(String id) async {
    await SaveGameService(widget.apiClient).deleteSavedGame(widget.gameType, id);
    if (_selectedGameId == id) {
      _selectedGameId = null;
    }
    await _loadSavedGames();
  }

  Future<void> _deleteAllGames() async {
    await SaveGameService(widget.apiClient).deleteAllSavedGames(widget.gameType);
    _selectedGameId = null;
    await _loadSavedGames();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Positioned.fill(
      child: Container(
        key: ResumeGameModalKeys.overlay,
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: config.maxWidth,
              maxHeight: config.maxHeight,
            ),
            child: Container(
              key: ResumeGameModalKeys.container,
              margin: config.margin,
              padding: config.padding,
              decoration: BoxDecoration(
                color: config.backgroundColor.withOpacity(config.backgroundOpacity),
                borderRadius: BorderRadius.circular(config.borderRadius),
                border: Border.all(
                  color: config.borderColor,
                  width: config.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: config.boxShadowColor.withOpacity(config.boxShadowOpacity),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Saved Games',
                    key: ResumeGameModalKeys.title,
                    style: config.titleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Saved games list
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else if (_savedGames.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No saved games',
                        key: ResumeGameModalKeys.emptyStateText,
                        style: config.tileModeTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        key: ResumeGameModalKeys.savedGamesList,
                        shrinkWrap: true,
                        itemCount: _savedGames.length,
                        itemBuilder: (context, index) {
                          final game = _savedGames[index];
                          final isSelected = _selectedGameId == game.id;
                          return _buildSavedGameTile(game, isSelected, config);
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Buttons
                  _buildButtons(config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedGameTile(
    SavedGameMetadata game,
    bool isSelected,
    ResumeGameModalConfig config,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGameId = game.id),
      child: Container(
        key: ResumeGameModalKeys.savedGameTile(game.id),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? config.tileSelectedBackgroundColor : config.tileBackgroundColor,
          borderRadius: BorderRadius.circular(config.tileBorderRadius),
          border: Border.all(
            color: isSelected ? config.tileSelectedBorderColor : config.tileBorderColor,
            width: config.tileBorderWidth,
          ),
        ),
        child: Row(
          children: [
            // Game info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    _formatDate(game.savedAt),
                    key: ResumeGameModalKeys.tileDate(game.id),
                    style: config.tileDateTextStyle,
                  ),
                  const SizedBox(height: 4),
                  // Players
                  Text(
                    game.playerNames.join(', '),
                    key: ResumeGameModalKeys.tilePlayers(game.id),
                    style: config.tilePlayersTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Progress + Mode
                  Row(
                    children: [
                      Text(
                        game.progressInfo,
                        key: ResumeGameModalKeys.tileProgress(game.id),
                        style: config.tileProgressTextStyle,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          game.gameModeName,
                          key: ResumeGameModalKeys.tileMode(game.id),
                          style: config.tileModeTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Leading player
                  Text(
                    '${game.leadingPlayerName}: ${game.leadingPlayerScore}',
                    key: ResumeGameModalKeys.tileLeader(game.id),
                    style: config.tileLeaderTextStyle,
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              key: ResumeGameModalKeys.deleteSavedGameButton(game.id),
              onPressed: () => _deleteGame(game.id),
              icon: Icon(Icons.delete, color: config.deleteButtonColor, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(ResumeGameModalConfig config) {
    final hasSelection = _selectedGameId != null;

    return Column(
      children: [
        // Resume Game button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: ResumeGameModalKeys.resumeGameButton,
            onPressed: hasSelection
                ? () {
                    final selectedGame = _savedGames.firstWhere((g) => g.id == _selectedGameId);
                    widget.onResumeGame(selectedGame);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection ? config.resumeButtonColor : config.resumeButtonDisabledColor,
              foregroundColor: config.resumeButtonTextColor,
              padding: config.resumeButtonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Resume Game', style: config.resumeButtonTextStyle),
          ),
        ),
        const SizedBox(height: 8),
        // Start New Game button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: ResumeGameModalKeys.startNewGameButton,
            onPressed: widget.onStartNewGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: config.startNewButtonColor,
              foregroundColor: config.startNewButtonTextColor,
              padding: config.startNewButtonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Start New Game', style: config.startNewButtonTextStyle),
          ),
        ),
        const SizedBox(height: 8),
        // Delete All button
        if (_savedGames.isNotEmpty)
          TextButton(
            key: ResumeGameModalKeys.deleteAllButton,
            onPressed: _deleteAllGames,
            child: Text('Delete All Saved Games', style: config.deleteAllButtonTextStyle),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year $hour:$minute $amPm';
  }
}
