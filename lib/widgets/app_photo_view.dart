import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-safe & Cross-platform Image/Photo Loader Widget
/// Handles:
/// - Base64 data URIs ('data:image/...')
/// - Local file paths on Windows/Android/iOS (safely avoiding dart:io on web)
/// - Network URLs ('http://', 'https://')
/// - Asset paths ('assets/...')
/// - Graceful fallback widgets for null/error states
class AppPhotoView extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;

  const AppPhotoView({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.trim().isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }

    final path = imagePath!.trim();

    // 1. Base64 Data URI
    if (path.startsWith('data:image')) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Content = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
        );
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    }

    // 2. Network URL
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    }

    // 3. Asset Image
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    }

    // 4. File Path
    if (!kIsWeb) {
      try {
        final file = io.File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
          );
        }
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    } else {
      // On Web, if it's a blob/object URL or web path
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    }

    return fallback ?? const SizedBox.shrink();
  }
}
