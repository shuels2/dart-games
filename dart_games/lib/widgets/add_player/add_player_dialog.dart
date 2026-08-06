import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dart_games/constants/test_keys.dart';
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
/// - Optional in-dialog progress overlay while [onSubmit] runs (see below).
///
/// If [onSubmit] is provided, tapping "Add Player" locks the dialog inputs,
/// shows a progress overlay styled from [config] (spinner in the add-button
/// color, text in the text color, backdrop tinted with [config.backgroundColor]),
/// awaits `onSubmit(player)`, and only then pops. If `onSubmit` throws, the
/// error message replaces the "Saving…" label and the buttons re-enable so
/// the user can retry or cancel. If [onSubmit] is null, the dialog pops
/// immediately as before and the caller must save the player itself.
///
/// The caller is responsible for:
/// - (If not passing onSubmit) Saving the player via PlayerProvider.savePlayer()
/// - Auto-selecting the player (if applicable)
/// - Showing success feedback (if applicable)
/// - Scrolling to show the new player
///
/// Example usage:
/// ```dart
/// final player = await showAddPlayerDialog(
///   context: context,
///   config: AddPlayerDialogConfig.carnivalDerby(),
///   onSubmit: (p) => context.read<PlayerProvider>().savePlayer(p),
/// );
///
/// if (player != null) {
///   // Player is already saved. Handle auto-selection, scroll, etc.
/// }
/// ```
Future<Player?> showAddPlayerDialog({
  required BuildContext context,
  required AddPlayerDialogConfig config,
  Future<void> Function(Player player)? onSubmit,
  String progressLabel = 'Saving player…',
}) async {
  final photoService = PhotoService();
  final nameController = TextEditingController();
  String? photoPath;
  bool showError = false;
  bool busy = false;
  String? busyError;

  return showDialog<Player>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        key: AddPlayerDialogKeys.dialogContainer,
        backgroundColor: config.backgroundColor,
        insetPadding: config.dialogInsetPadding ?? const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Add New Player',
          style: config.titleStyle,
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: config.dialogContentWidth ?? 0,
            ),
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
                        key: AddPlayerDialogKeys.photoPreview,
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
                          key: AddPlayerDialogKeys.removePhotoButton,
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: busy
                              ? null
                              : () {
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
                key: AddPlayerDialogKeys.nameTextField,
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
                enabled: !busy,
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
                        key: AddPlayerDialogKeys.cameraButton,
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
                        key: AddPlayerDialogKeys.cameraButton,
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
                        key: AddPlayerDialogKeys.galleryButton,
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
                        key: AddPlayerDialogKeys.galleryButton,
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
              // Progress / status area — only rendered while an
              // async onSubmit is running (or has just failed).
              // Matches the dialog's style using colors from `config`.
              if (busy || busyError != null) ...[
                const SizedBox(height: 16),
                _AddPlayerStatusRow(
                  config: config,
                  busy: busy,
                  errorMessage: busyError,
                  label: progressLabel,
                ),
              ],
            ],
          ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Builder(builder: (_) {
            Future<void> handleSubmit() async {
              if (busy) return;
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

              if (onSubmit == null) {
                Navigator.pop(dialogContext, player);
                return;
              }

              setDialogState(() {
                busy = true;
                busyError = null;
              });
              try {
                await onSubmit(player);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, player);
                }
              } catch (e) {
                setDialogState(() {
                  busy = false;
                  busyError = e.toString();
                });
              }
            }

            VoidCallback? cancelHandler =
                busy ? null : () => Navigator.pop(dialogContext, null);
            VoidCallback addHandler = () {
              // Fire-and-forget — errors are caught inside handleSubmit
              // and surfaced via busyError.
              handleSubmit();
            };

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (config.photoButtonWidth != null)
                  SizedBox(
                    width: config.photoButtonWidth,
                    child: ElevatedButton(
                      key: AddPlayerDialogKeys.cancelButton,
                      onPressed: cancelHandler,
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
                      child:
                          Text('CANCEL', style: config.cancelButtonTextStyle),
                    ),
                  )
                else if (config.customCancelButton != null)
                  Expanded(
                    child: config.customCancelButton!(
                      AddPlayerDialogKeys.cancelButton,
                      cancelHandler ?? () {},
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      key: AddPlayerDialogKeys.cancelButton,
                      onPressed: cancelHandler,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.cancelButtonColor,
                        foregroundColor: config.cancelButtonForegroundColor,
                        padding: config.buttonPadding,
                        side: BorderSide(
                          color: config.cancelButtonBorderColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          Text('Cancel', style: config.cancelButtonTextStyle),
                    ),
                  ),
                const SizedBox(width: 16),
                if (config.photoButtonWidth != null)
                  SizedBox(
                    width: config.photoButtonWidth,
                    child: ElevatedButton(
                      key: AddPlayerDialogKeys.addButton,
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
                      onPressed: busy ? null : addHandler,
                      child: Text('ADD PLAYER',
                          style: config.addButtonTextStyle),
                    ),
                  )
                else if (config.customAddButton != null)
                  Expanded(
                    child: config.customAddButton!(
                      AddPlayerDialogKeys.addButton,
                      busy ? () {} : addHandler,
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      key: AddPlayerDialogKeys.addButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.addButtonColor,
                        foregroundColor: config.addButtonForegroundColor,
                        padding: config.buttonPadding,
                        side: BorderSide(
                          color: config.addButtonBorderColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: busy ? null : addHandler,
                      child: Text('Add Player',
                          style: config.addButtonTextStyle),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    ),
  );
  // NOTE: nameController is intentionally not disposed here. Disposing on the
  // dialog future's completion throws "A TextEditingController was used after
  // being disposed" — the route's exit transition keeps rebuilding the
  // TextField for several frames after pop. Proper ownership needs the dialog
  // body to be a StatefulWidget (see docs/plans .. 03-shared-components.md);
  // until then the controller is simply collected once the closure is
  // unreachable.
}

/// Progress / error status row shown at the bottom of the Add Player
/// dialog while an async `onSubmit` is in flight (or has just failed).
///
/// Uses colors from [AddPlayerDialogConfig] so it visually inherits the
/// game's theme — the spinner uses `addButtonColor`, the label uses
/// `textColor`, the error uses `errorTextColor`, and the surrounding
/// pill uses a subtle `backgroundColor` tint that reads on top of the
/// dialog's own backdrop.
class _AddPlayerStatusRow extends StatelessWidget {
  const _AddPlayerStatusRow({
    required this.config,
    required this.busy,
    required this.errorMessage,
    required this.label,
  });

  final AddPlayerDialogConfig config;
  final bool busy;
  final String? errorMessage;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AddPlayerDialogKeys.progressOverlay,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (errorMessage != null
                  ? config.errorTextColor
                  : config.addButtonColor)
              .withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(config.addButtonColor),
                  ),
                )
              else
                Icon(Icons.error_outline,
                    size: 20, color: config.errorTextColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  key: AddPlayerDialogKeys.progressLabel,
                  busy ? label : (errorMessage ?? label),
                  style: TextStyle(
                    color: errorMessage != null
                        ? config.errorTextColor
                        : config.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: config.addButtonColor.withOpacity(0.20),
                valueColor:
                    AlwaysStoppedAnimation<Color>(config.addButtonColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function to build photo upload buttons
Widget _buildPhotoButton({
  required BuildContext context,
  required AddPlayerDialogConfig config,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
  Key? key,
}) {
  return ElevatedButton.icon(
    key: key,
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: config.photoButtonColor,
      foregroundColor: config.photoButtonForegroundColor,
      padding: config.buttonPadding,
      side: BorderSide(
        color: config.photoButtonBorderColor,
        width: 2,
      ),
    ),
    icon: Icon(icon, color: config.photoButtonForegroundColor, shadows: config.photoIconShadows),
    label: Text(label, style: config.photoButtonTextStyle),
  );
}
