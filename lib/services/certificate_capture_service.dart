import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Helper service to capture high-res certificate image, download, and share across Android & Web
class CertificateCaptureService {
  /// Capture RepaintBoundary as high-resolution PNG bytes
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey, {double pixelRatio = 3.0}) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Ensure boundary is painted
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing certificate: $e');
      return null;
    }
  }

  /// Download / Save the certificate PNG to the device
  static Future<String?> saveCertificateImage({
    required Uint8List pngBytes,
    required String plantName,
  }) async {
    try {
      final cleanName = plantName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'SpryFlora_Certificate_${cleanName}_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        // On Web, use share_plus XFile.saveTo or download anchor
        final xfile = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: fileName,
        );
        await xfile.saveTo(fileName);
        return 'Downloaded $fileName';
      } else {
        // On Android / iOS
        io.Directory? targetDir;
        try {
          // Try to get Downloads / External Storage on Android
          if (io.Platform.isAndroid) {
            targetDir = io.Directory('/storage/emulated/0/Download');
            if (!targetDir.existsSync()) {
              targetDir = await getExternalStorageDirectory();
            }
          }
        } catch (_) {}

        targetDir ??= await getApplicationDocumentsDirectory();

        final filePath = '${targetDir.path}/$fileName';
        final file = io.File(filePath);
        await file.writeAsBytes(pngBytes, flush: true);
        return filePath;
      }
    } catch (e) {
      debugPrint('Error saving certificate image: $e');
      return null;
    }
  }

  /// Share the certificate PNG with Android / iOS / Web native share sheet
  static Future<bool> shareCertificateImage({
    required Uint8List pngBytes,
    required String plantName,
    required String recipientName,
  }) async {
    try {
      final cleanName = plantName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'SpryFlora_Certificate_$cleanName.png';

      final xfile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: fileName,
      );

      final shareText =
          '🌱 Proudly presenting $recipientName\'s Official SpryFlora Certificate of Achievement for successfully growing $plantName! 🌿🏆';

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xfile],
          text: shareText,
          subject: 'SpryFlora Certificate of Achievement - $plantName',
        ),
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Error sharing certificate: $e');
      return false;
    }
  }
}
