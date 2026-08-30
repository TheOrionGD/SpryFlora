import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Local Offline Image Service
/// Captures photos with device camera or gallery and persists them into local app storage
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captures a real-time photo using the system camera and saves it in app sandbox
  Future<String?> captureFromCamera({String prefix = 'checkin'}) async {
    // 1. On Windows Desktop: Launch real-time Windows System Camera (ms-windows-camera)
    if (!kIsWeb && Platform.isWindows) {
      final photoPath = await _captureFromWindowsSystemCamera(prefix: prefix);
      if (photoPath != null) return photoPath;
    }

    // 2. Default/Mobile/Web Camera via ImagePicker
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return await _savePhotoLocally(photo, prefix);
    } catch (_) {
      return null;
    }
  }

  /// Launches the native Windows System Camera, captures real-time photo, and tracks the latest photo from Camera Roll
  Future<String?> _captureFromWindowsSystemCamera({required String prefix}) async {
    try {
      // Find Pictures/Camera Roll directory on Windows
      final String userProfile = Platform.environment['USERPROFILE'] ?? '';
      final List<String> candidateCameraRollDirs = [
        '$userProfile/OneDrive/Pictures/Camera Roll',
        '$userProfile/Pictures/Camera Roll',
        '$userProfile/OneDrive/Pictures',
        '$userProfile/Pictures',
      ];

      Directory? cameraRollDir;
      for (final path in candidateCameraRollDirs) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          cameraRollDir = dir;
          break;
        }
      }

      // Record snapshot of existing files and timestamps
      final Set<String> existingFilePaths = {};
      DateTime launchTime = DateTime.now();
      if (cameraRollDir != null && cameraRollDir.existsSync()) {
        try {
          for (final entity in cameraRollDir.listSync()) {
            if (entity is File) {
              existingFilePaths.add(entity.path);
            }
          }
        } catch (_) {}
      }

      // Launch native real-time Windows Camera app
      await Process.run('cmd', ['/c', 'start', 'ms-windows-camera:']);

      // Poll for newly captured photo from system camera for up to 45 seconds
      if (cameraRollDir != null) {
        final startTime = DateTime.now();
        while (DateTime.now().difference(startTime).inSeconds < 45) {
          await Future.delayed(const Duration(milliseconds: 700));

          if (cameraRollDir.existsSync()) {
            try {
              final files = cameraRollDir
                  .listSync()
                  .whereType<File>()
                  .where((f) {
                    final ext = f.path.toLowerCase();
                    return ext.endsWith('.jpg') ||
                        ext.endsWith('.jpeg') ||
                        ext.endsWith('.png') ||
                        ext.endsWith('.webp');
                  })
                  .toList();

              // Sort by modified time descending (newest first)
              files.sort((a, b) {
                try {
                  return b.lastModifiedSync().compareTo(a.lastModifiedSync());
                } catch (_) {
                  return 0;
                }
              });

              for (final file in files) {
                // If it's a newly created file after launch time or wasn't previously in directory
                if (!existingFilePaths.contains(file.path) ||
                    file.lastModifiedSync().isAfter(launchTime.subtract(const Duration(seconds: 2)))) {
                  // File is ready, save into local app sandbox
                  return await _saveFileLocally(file, prefix);
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Picks a photo from the local gallery and saves it in app sandbox
  Future<String?> pickFromGallery({String prefix = 'plant'}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return await _savePhotoLocally(photo, prefix);
    } catch (_) {
      return null;
    }
  }

  /// Helper to copy a selected/captured file to local documents directory
  Future<String> _savePhotoLocally(XFile photo, String prefix) async {
    if (kIsWeb) {
      try {
        final bytes = await photo.readAsBytes();
        final base64Str = base64Encode(bytes);
        return 'data:image/png;base64,$base64Str';
      } catch (_) {
        return photo.path;
      }
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String plantPhotosDir = '${appDir.path}/plant_photos';
      final Directory dir = Directory(plantPhotosDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = photo.name.split('.').last;
      final String localPath = '$plantPhotosDir/${prefix}_$timestamp.$extension';

      final File savedFile = await File(photo.path).copy(localPath);
      return savedFile.path;
    } catch (_) {
      // Return temporary path if documents directory write fails
      return photo.path;
    }
  }

  /// Helper to copy File directly to local documents directory
  Future<String> _saveFileLocally(File sourceFile, String prefix) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String plantPhotosDir = '${appDir.path}/plant_photos';
      final Directory dir = Directory(plantPhotosDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = sourceFile.path.split('.').last;
      final String localPath = '$plantPhotosDir/${prefix}_$timestamp.$extension';

      final File savedFile = await sourceFile.copy(localPath);
      return savedFile.path;
    } catch (_) {
      return sourceFile.path;
    }
  }
}
