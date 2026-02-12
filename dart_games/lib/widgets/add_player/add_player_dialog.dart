import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../services/photo_service.dart';
import 'add_player_dialog_config.dart';

/// Shows a dialog for adding a new player with photo upload capabilities.
///
/// Returns a [Player] object if successfully created, or null if cancelled.
///
/// The dialog handles:
/// - Player name input with validation
/// - Optional photo upload via camera or gallery
/// - Photo preview with remove capability
/// - Styling via [AddPlayerDialogConfig]
///
/// The caller is responsible for:
/// - Saving the player via PlayerProvider.savePlayer()
/// - Auto-selecting the player (if applicable)
/// - Showing success feedback (if applicable)
/// - Scrolling to show the new player
///
/// Example usage:
/// ```dart
/// final player = await showAddPlayerDialog(
///   context: context,
///   config: AddPlayerDialogConfig.carnivalDerby(),
/// );
///
/// if (player != null) {
///   await playerProvider.savePlayer(player);
///   // Handle auto-selection, scroll, etc.
/// }
/// ```
Future<Player?> showAddPlayerDialog({
  required BuildContext context,
  required AddPlayerDialogConfig config,
}) async {
  final photoService = PhotoService();
  final nameController = TextEditingController();
  String? photoPath;
  bool showError = false;

  return showDialog<Player>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: config.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Add New Player',
          style: config.titleStyle,
        ),
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
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
                style: TextStyle(color: config.textColor),
                decoration: InputDecoration(
                  labelText: 'Player Name',
                  labelStyle: config.inputLabelStyle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: config.inputBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: config.inputBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: config.inputFocusedBorderColor, width: 2),
                  ),
                  errorText: showError ? 'Please enter a player name' : null,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: config.inputErrorBorderColor, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: config.inputErrorBorderColor, width: 2),
                  ),
                ),
                autofocus: true,
                onChanged: (value) {
                  // Clear error when user starts typing
                  if (showError && value.trim().isNotEmpty) {
                    setDialogState(() {
                      showError = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Photo (Optional)',
                style: config.photoLabelStyle,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (config.photoButtonWidth != null)
                    SizedBox(
                      width: config.photoButtonWidth,
                      child: _buildPhotoButton(
                        context: context,
                        config: config,
                        icon: Icons.camera_alt,
                        label: 'CAMERA',
                        onPressed: () async {
                          final path = await photoService.takePhoto(context: context);
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: _buildPhotoButton(
                        context: context,
                        config: config,
                        icon: Icons.camera_alt,
                        label: 'CAMERA',
                        onPressed: () async {
                          final path = await photoService.takePhoto(context: context);
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                      ),
                    ),
                  const SizedBox(width: 16),
                  if (config.photoButtonWidth != null)
                    SizedBox(
                      width: config.photoButtonWidth,
                      child: _buildPhotoButton(
                        context: context,
                        config: config,
                        icon: Icons.photo_library,
                        label: 'GALLERY',
                        onPressed: () async {
                          final path = await photoService.selectFromGallery();
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: _buildPhotoButton(
                        context: context,
                        config: config,
                        icon: Icons.photo_library,
                        label: 'GALLERY',
                        onPressed: () async {
                          final path = await photoService.selectFromGallery();
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.photoButtonWidth != null)
                SizedBox(
                  width: config.photoButtonWidth,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.cancelButtonColor,
                      foregroundColor: config.cancelButtonForegroundColor,
                      side: BorderSide(
                        color: config.cancelButtonBorderColor,
                        width: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('CANCEL', style: config.cancelButtonTextStyle),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.cancelButtonColor,
                      foregroundColor: config.cancelButtonForegroundColor,
                      side: BorderSide(
                        color: config.cancelButtonBorderColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel', style: config.cancelButtonTextStyle),
                  ),
                ),
              const SizedBox(width: 16),
              if (config.photoButtonWidth != null)
                SizedBox(
                  width: config.photoButtonWidth,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.addButtonColor,
                      foregroundColor: config.addButtonForegroundColor,
                      side: BorderSide(
                        color: config.addButtonBorderColor,
                        width: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        setDialogState(() {
                          showError = true;
                        });
                        return;
                      }

                      final player = Player.create(
                        name: nameController.text.trim(),
                        photoPath: photoPath,
                      );

                      Navigator.pop(dialogContext, player);
                    },
                    child: Text('ADD PLAYER', style: config.addButtonTextStyle),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.addButtonColor,
                      foregroundColor: config.addButtonForegroundColor,
                      side: BorderSide(
                        color: config.addButtonBorderColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        setDialogState(() {
                          showError = true;
                        });
                        return;
                      }

                      final player = Player.create(
                        name: nameController.text.trim(),
                        photoPath: photoPath,
                      );

                      Navigator.pop(dialogContext, player);
                    },
                    child: Text('Add Player', style: config.addButtonTextStyle),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Helper function to build photo upload buttons
Widget _buildPhotoButton({
  required BuildContext context,
  required AddPlayerDialogConfig config,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: config.photoButtonColor,
      foregroundColor: config.photoButtonForegroundColor,
      side: BorderSide(
        color: config.photoButtonBorderColor,
        width: 2,
      ),
    ),
    icon: Icon(icon, color: config.photoButtonForegroundColor),
    label: Text(label, style: config.photoButtonTextStyle),
  );
}
