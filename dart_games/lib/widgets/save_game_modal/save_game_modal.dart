import 'package:flutter/material.dart';
import '../../constants/test_keys.dart';
import 'save_game_modal_config.dart';

export 'save_game_modal_config.dart';

class SaveGameModal extends StatelessWidget {
  final SaveGameModalConfig config;
  final VoidCallback onSave;
  final VoidCallback onDontSave;

  const SaveGameModal({
    super.key,
    required this.config,
    required this.onSave,
    required this.onDontSave,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        key: SaveGameModalKeys.overlay,
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: _buildModalContent(),
        ),
      ),
    );
  }

  Widget _buildModalContent() {
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
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: SaveGameModalKeys.saveButton,
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.saveButtonColor,
                  foregroundColor: config.saveButtonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                onPressed: onDontSave,
                style: TextButton.styleFrom(
                  foregroundColor: config.dontSaveButtonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Don't Save", style: config.dontSaveButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
