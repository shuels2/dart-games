import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../widgets/web_camera_stub.dart'
    if (dart.library.html) '../widgets/web_camera_widget.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  // Capture photo from camera
  Future<String?> takePhoto({BuildContext? context}) async {
    // On web, use custom camera widget for better UX
    if (kIsWeb && context != null) {
      return await _takePhotoWeb(context);
    }

    // On mobile, use image_picker
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo == null) return null;

      return await _savePhotoToAppDirectory(photo);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Web-specific camera capture
  Future<String?> _takePhotoWeb(BuildContext context) async {
    try {
      String? imageDataUrl;

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 640,
            height: 580,
            child: WebCameraWidget(
              onCapture: (dataUrl) {
                imageDataUrl = dataUrl;
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );

      return imageDataUrl;
    } catch (e) {
      print('Error taking photo on web: $e');
      return null;
    }
  }

  // Select photo from gallery
  Future<String?> selectFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo == null) return null;

      return await _savePhotoToAppDirectory(photo);
    } catch (e) {
      print('Error selecting photo: $e');
      return null;
    }
  }

  // Save photo to app documents directory (or return base64 data URL on web)
  Future<String> _savePhotoToAppDirectory(XFile photo) async {
    // On web, convert to base64 data URL for persistence
    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);
      // Return as data URL
      return 'data:image/jpeg;base64,$base64String';
    }

    // On mobile, save to app directory
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/player_photos');

    // Create directory if it doesn't exist
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    // Generate unique filename
    final uuid = const Uuid().v4();
    final extension = photo.path.split('.').last;
    final fileName = '$uuid.$extension';
    final filePath = '${photosDir.path}/$fileName';

    // Copy file to app directory
    final File imageFile = File(photo.path);
    await imageFile.copy(filePath);

    return filePath;
  }

  // Get app documents path (for reference)
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Delete a photo file
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  // Check if photo file exists
  Future<bool> photoExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get default avatar path (returns null to use Flutter icon instead)
  String? getDefaultAvatarPath() {
    return null;
  }
}
