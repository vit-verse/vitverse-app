import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/utils/logger.dart';

/// Image compression service for Lost & Found
class ImageCompressionService {
  static const String _tag = 'ImageCompress';
  static const int _maxSizeBytes = 1024 * 1024; // 1MB
  static const int _targetQuality = 70;
  static const int _maxWidth = 1080;

  /// Compress image to under 1MB
  static Future<File> compressImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileSize = await file.length();

      Logger.d(_tag, 'Original size: ${fileSize ~/ 1024}KB');

      // If already under 1MB, return as is
      if (fileSize <= _maxSizeBytes) {
        Logger.d(_tag, 'Image already under 1MB, no compression needed');
        return file;
      }

      // Compress
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${const Uuid().v4()}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: _targetQuality,
        minWidth: _maxWidth,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        Logger.w(_tag, 'Compression failed, using original');
        return file;
      }

      final compressedSize = await File(compressed.path).length();
      Logger.success(
        _tag,
        'Compressed: ${fileSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB',
      );

      // If still too large, compress more aggressively
      if (compressedSize > _maxSizeBytes) {
        Logger.d(_tag, 'Still too large, compressing further');
        final targetPath2 =
            '${tempDir.path}/compressed_2_${const Uuid().v4()}.jpg';

        final compressed2 = await FlutterImageCompress.compressAndGetFile(
          compressed.path,
          targetPath2,
          quality: 50,
          minWidth: 720,
          format: CompressFormat.jpeg,
        );

        if (compressed2 != null) {
          final finalSize = await File(compressed2.path).length();
          Logger.success(_tag, 'Final size: ${finalSize ~/ 1024}KB');
          return File(compressed2.path);
        }
      }

      return File(compressed.path);
    } catch (e, stack) {
      Logger.e(_tag, 'Compression error', e, stack);
      // Return original on error
      return File(imageFile.path);
    }
  }
}
