import 'package:flutter/material.dart';
import '../../constants/test_keys.dart';
import 'save_game_modal_config.dart';

export 'save_game_modal_config.dart';

class SaveGameModal extends StatefulWidget {
  final SaveGameModalConfig config;
  final Future<void> Function() onSave;
  final VoidCallback onDontSave;

  const SaveGameModal({
    super.key,
    required this.config,
    required this.onSave,
    required this.onDontSave,
  });

  @override
  State<SaveGameModal> createState() => _SaveGameModalState();
}

class _SaveGameModalState extends State<SaveGameModal> {
  bool _saving = false;
  String? _errorText;

  /// Runs the save, keeping the modal usable if it fails.
  ///
  /// A failed save used to leave [_saving] true forever, which disabled the
  /// Save button permanently and left "Don't Save" — discarding the game — as
  /// the only way out.
  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.onSave();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = "Couldn't save — check the connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: SaveGameModalKeys.overlay,
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: _buildModalContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildModalContent() {
    final config = widget.config;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: config.maxWidth),
      child: Container(
        key: SaveGameModalKeys.container,
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
        // Scrollable so the modal degrades gracefully on short viewports
        // (and when the error row is showing) instead of overflowing.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.save,
                key: SaveGameModalKeys.icon,
                color: config.iconColor,
                size: config.iconSize,
              ),
              const SizedBox(height: 20),
              Text(
                'Save Game?',
                key: SaveGameModalKeys.title,
                style: config.titleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to save your game\nso you can resume later?',
                key: SaveGameModalKeys.message,
                style: config.messageTextStyle,
                textAlign: TextAlign.center,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  key: SaveGameModalKeys.errorMessage,
                  style: config.messageTextStyle.copyWith(
                    color: const Color(0xFFFF8A80),
                    fontSize: (config.messageTextStyle.fontSize ?? 18) - 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: SaveGameModalKeys.saveButton,
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.saveButtonColor,
                    foregroundColor: config.saveButtonTextColor,
                    padding: config.saveButtonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Save Game', style: config.saveButtonTextStyle),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: SaveGameModalKeys.dontSaveButton,
                  onPressed: widget.onDontSave,
                  style: TextButton.styleFrom(
                    foregroundColor: config.dontSaveButtonTextColor,
                    padding: config.dontSaveButtonPadding,
                  ),
                  child:
                      Text("Don't Save", style: config.dontSaveButtonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
